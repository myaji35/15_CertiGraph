# app/mailers/payment_mailer.rb
class PaymentMailer < ApplicationMailer
  default from: ENV['MAILER_FROM'] || 'noreply@examsgraph.com'

  # Payment confirmation email
  def payment_confirmed(payment)
    @payment = payment
    @user = payment.user
    @subscription = payment.subscription
    @plan_name = plan_name(@subscription&.plan_type || 'season_pass')
    @expires_at = @subscription&.expires_at

    mail(
      to: @user.email,
      subject: '[ExamsGraph] 결제가 완료되었습니다'
    )
  end

  # Payment failed notification
  def payment_failed(payment)
    @payment = payment
    @user = payment.user
    @error_message = payment.failure_message
    @retry_url = "#{ENV['APP_URL']}/payments/#{payment.id}/retry"

    mail(
      to: @user.email,
      subject: '[ExamsGraph] 결제 처리 중 오류가 발생했습니다'
    )
  end

  # Refund processed notification
  def refund_processed(payment)
    @payment = payment
    @user = payment.user
    @refund_amount = payment.metadata['refund_amount'] || payment.amount
    @refund_reason = payment.metadata['refund_reason']

    mail(
      to: @user.email,
      subject: '[ExamsGraph] 환불이 완료되었습니다'
    )
  end

  # Subscription expiration warning (7 days before)
  def subscription_expiring_soon(subscription)
    @subscription = subscription
    @user = subscription.user
    @days_remaining = subscription.days_remaining
    @expires_at = subscription.expires_at
    @renew_url = "#{ENV['APP_URL']}/payments/checkout"

    mail(
      to: @user.email,
      subject: "[ExamsGraph] 구독이 #{@days_remaining}일 후 만료됩니다"
    )
  end

  # Subscription expired notification
  def subscription_expired(subscription)
    @subscription = subscription
    @user = subscription.user
    @expired_at = subscription.expires_at
    @renew_url = "#{ENV['APP_URL']}/payments/checkout"

    mail(
      to: @user.email,
      subject: '[ExamsGraph] 구독이 만료되었습니다'
    )
  end

  # Receipt email
  def payment_receipt(payment)
    @payment = payment
    @user = payment.user
    @subscription = payment.subscription
    @plan_name = plan_name(@subscription&.plan_type || 'season_pass')

    # Attach PDF receipt if available
    if @payment.receipt_pdf.present?
      attachments["receipt_#{@payment.order_id}.pdf"] = @payment.receipt_pdf
    end

    mail(
      to: @user.email,
      subject: "[ExamsGraph] 결제 영수증 (주문번호: #{@payment.order_id})"
    )
  end

  # Subscription renewal reminder
  def renewal_reminder(subscription)
    @subscription = subscription
    @user = subscription.user
    @plan_name = plan_name(@subscription.plan_type)
    @amount = plan_amount(@subscription.plan_type)
    @renew_url = "#{ENV['APP_URL']}/payments/checkout?plan=#{@subscription.plan_type}"

    mail(
      to: @user.email,
      subject: '[ExamsGraph] 구독 갱신 안내'
    )
  end

  # Failed payment retry reminder
  def retry_payment_reminder(payment)
    @payment = payment
    @user = payment.user
    @retry_url = "#{ENV['APP_URL']}/payments/#{payment.id}/retry"
    @support_url = "#{ENV['APP_URL']}/support"

    mail(
      to: @user.email,
      subject: '[ExamsGraph] 결제 재시도 안내'
    )
  end

  private

  def plan_name(plan_type)
    case plan_type
    when 'season_pass'
      '시즌 패스 (90일)'
    when 'vip_pass'
      'VIP 패스 (365일)'
    else
      '구독'
    end
  end

  def plan_amount(plan_type)
    case plan_type
    when 'season_pass'
      '10,000원'
    when 'vip_pass'
      '50,000원'
    else
      '0원'
    end
  end
end
