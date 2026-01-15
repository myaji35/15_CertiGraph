class PaymentsController < ApplicationController
  before_action :authenticate_user!, except: [:success, :fail]
  before_action :set_payment, only: [:show, :cancel]

  # GET /payments
  def index
    @payments = current_user.payments.recent.page(params[:page]).per(20)
    render json: @payments
  end

  # GET /payments/:id
  def show
    render json: @payment.as_json(include: :subscription)
  end

  # POST /payments/request
  def request_payment
    plan_type = params[:plan_type] || 'season_pass'

    unless ['season_pass', 'vip_pass'].include?(plan_type)
      return render json: { error: 'Invalid plan type' }, status: :unprocessable_entity
    end

    service = TossPaymentService.new
    result = service.request_payment(user: current_user, plan_type: plan_type)

    render json: {
      success: true,
      payment: result[:payment].as_json(only: [:id, :order_id, :amount, :currency, :status]),
      clientKey: result[:client_key],
      successUrl: result[:success_url],
      failUrl: result[:fail_url]
    }
  rescue StandardError => e
    Rails.logger.error "Payment request failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /payments/confirm
  def confirm
    unless params[:orderId] && params[:paymentKey] && params[:amount]
      return render json: { error: 'Missing required parameters' }, status: :bad_request
    end

    service = TossPaymentService.new
    result = service.confirm_payment(
      order_id: params[:orderId],
      payment_key: params[:paymentKey],
      amount: params[:amount]
    )

    if result[:success]
      render json: {
        success: true,
        payment: result[:payment].as_json(include: :subscription),
        message: 'Payment confirmed successfully'
      }
    else
      render json: {
        success: false,
        error: result[:error],
        message: 'Payment confirmation failed'
      }, status: :unprocessable_entity
    end
  rescue TossPaymentService::TossPaymentError => e
    Rails.logger.error "Payment confirmation failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Unexpected error during payment confirmation: #{e.message}"
    render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
  end

  # GET /payments/success
  def success
    @order_id = params[:orderId]
    @payment_key = params[:paymentKey]
    @amount = params[:amount]

    # Find payment
    @payment = Payment.find_by(order_id: @order_id)

    if @payment
      @user = @payment.user
      @subscription = @payment.subscription
    end

    # Render success page
    render :success
  end

  # GET /payments/fail
  def fail
    @error_code = params[:code]
    @error_message = params[:message]
    @order_id = params[:orderId]

    # Find and update payment if exists
    if @order_id
      payment = Payment.find_by(order_id: @order_id)
      payment&.mark_as_failed!(@error_code, @error_message)
    end

    # Render fail page
    render :fail
  end

  # POST /payments/:id/cancel
  def cancel
    unless @payment.cancelable?
      return render json: { error: 'Payment cannot be canceled' }, status: :unprocessable_entity
    end

    cancel_reason = params[:cancelReason] || 'User requested cancellation'

    service = TossPaymentService.new
    result = service.cancel_payment(
      payment_key: @payment.payment_key,
      cancel_reason: cancel_reason
    )

    @payment.update!(status: 'canceled')
    @payment.subscription&.deactivate!

    render json: {
      success: true,
      payment: @payment,
      message: 'Payment canceled successfully'
    }
  rescue TossPaymentService::TossPaymentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /payments/subscription/status
  def subscription_status
    subscription = current_user.current_subscription

    if subscription
      render json: {
        has_subscription: true,
        subscription: subscription.as_json(include: :payment),
        is_active: subscription.active?,
        days_remaining: subscription.days_remaining,
        expires_at: subscription.expires_at
      }
    else
      render json: {
        has_subscription: false,
        message: 'No active subscription'
      }
    end
  end

  # POST /payments/:id/refund
  def refund
    @payment = current_user.payments.find(params[:id])

    unless @payment.refundable?
      return render json: { error: 'Payment is not refundable' }, status: :unprocessable_entity
    end

    refund_amount = params[:amount]&.to_i || @payment.amount
    refund_reason = params[:reason] || 'Customer requested refund'

    service = TossPaymentService.new
    result = service.cancel_payment(
      payment_key: @payment.payment_key,
      cancel_reason: refund_reason,
      cancel_amount: refund_amount
    )

    @payment.update!(
      status: 'refunded',
      metadata: @payment.metadata.merge(
        refund_amount: refund_amount,
        refund_reason: refund_reason,
        refunded_at: Time.current.iso8601
      )
    )

    @payment.subscription&.deactivate!

    # Send refund notification email
    PaymentMailer.refund_processed(@payment).deliver_later

    render json: {
      success: true,
      payment: @payment,
      message: 'Refund processed successfully'
    }
  rescue TossPaymentService::TossPaymentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Refund failed: #{e.message}"
    render json: { error: 'Refund processing failed' }, status: :internal_server_error
  end

  # GET /payments/history
  def history
    page = params[:page] || 1
    per_page = params[:per_page] || 20

    payments = current_user.payments
                           .order(created_at: :desc)
                           .page(page)
                           .per(per_page)

    render json: {
      success: true,
      payments: payments.as_json(include: :subscription),
      meta: {
        current_page: payments.current_page,
        total_pages: payments.total_pages,
        total_count: payments.total_count
      }
    }
  end

  # POST /payments/:id/retry
  def retry_payment
    @payment = current_user.payments.find(params[:id])

    unless @payment.failed? || @payment.status == 'pending'
      return render json: { error: 'Payment cannot be retried' }, status: :unprocessable_entity
    end

    service = TossPaymentService.new
    result = service.request_payment(
      user: current_user,
      plan_type: @payment.metadata['plan_type'] || 'season_pass'
    )

    render json: {
      success: true,
      payment: result[:payment].as_json(only: [:id, :order_id, :amount, :currency, :status]),
      clientKey: result[:client_key],
      successUrl: result[:success_url],
      failUrl: result[:fail_url]
    }
  rescue StandardError => e
    Rails.logger.error "Payment retry failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /payments/subscription/manage
  def manage_subscription
    subscription = current_user.current_subscription

    unless subscription
      return render json: { error: 'No active subscription found' }, status: :not_found
    end

    render json: {
      success: true,
      subscription: subscription.as_json(include: :payment),
      can_cancel: subscription.active?,
      can_upgrade: subscription.plan_type == 'season_pass',
      expires_at: subscription.expires_at,
      auto_renew: false # Currently not supported
    }
  end

  # POST /payments/subscription/upgrade
  def upgrade_subscription
    current_subscription = current_user.current_subscription

    unless current_subscription&.active?
      return render json: { error: 'No active subscription to upgrade' }, status: :unprocessable_entity
    end

    if current_subscription.plan_type == 'vip_pass'
      return render json: { error: 'Already on highest plan' }, status: :unprocessable_entity
    end

    service = TossPaymentService.new
    result = service.request_payment(
      user: current_user,
      plan_type: 'vip_pass'
    )

    render json: {
      success: true,
      message: 'Upgrade initiated',
      payment: result[:payment].as_json(only: [:id, :order_id, :amount, :currency, :status]),
      clientKey: result[:client_key],
      successUrl: result[:success_url],
      failUrl: result[:fail_url]
    }
  rescue StandardError => e
    Rails.logger.error "Subscription upgrade failed: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_payment
    @payment = current_user.payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Payment not found' }, status: :not_found
  end

  def payment_params
    params.require(:payment).permit(:plan_type, :cancelReason, :amount, :reason)
  end
end
