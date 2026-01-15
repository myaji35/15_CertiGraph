# app/services/stripe_service.rb
class StripeService
  include HTTParty
  base_uri 'https://api.stripe.com/v1'

  SEASON_PASS_AMOUNT = 10_000 # 10,000 KRW (100.00 in cents for Stripe)
  VIP_PASS_AMOUNT = 50_000 # 50,000 KRW (500.00 in cents for Stripe)

  class StripeError < StandardError; end

  def initialize
    @api_key = ENV['STRIPE_SECRET_KEY']
    @publishable_key = ENV['STRIPE_PUBLISHABLE_KEY']
    @success_url = ENV['STRIPE_SUCCESS_URL'] || "#{ENV['APP_URL']}/payments/success"
    @cancel_url = ENV['STRIPE_CANCEL_URL'] || "#{ENV['APP_URL']}/payments/fail"
    @webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
  end

  # Create checkout session
  def create_checkout_session(user:, plan_type: 'season_pass')
    amount = plan_type == 'vip_pass' ? VIP_PASS_AMOUNT : SEASON_PASS_AMOUNT

    # Create payment record first
    payment = Payment.create!(
      user: user,
      order_id: Payment.generate_order_id,
      amount: amount,
      currency: 'KRW',
      status: 'pending',
      metadata: {
        plan_type: plan_type,
        payment_provider: 'stripe',
        requested_at: Time.current.iso8601
      }
    )

    # Create Stripe checkout session
    response = self.class.post(
      '/checkout/sessions',
      basic_auth: auth,
      headers: headers,
      body: {
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'krw',
            product_data: {
              name: plan_type == 'vip_pass' ? 'VIP Pass' : 'Season Pass',
              description: subscription_description(plan_type)
            },
            unit_amount: amount
          },
          quantity: 1
        }],
        mode: 'payment',
        success_url: "#{@success_url}?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: @cancel_url,
        client_reference_id: payment.order_id,
        metadata: {
          user_id: user.id,
          order_id: payment.order_id,
          plan_type: plan_type
        }
      }
    )

    handle_response(response) do |data|
      payment.update!(
        metadata: payment.metadata.merge(
          stripe_session_id: data['id'],
          stripe_session_url: data['url']
        )
      )

      {
        payment: payment,
        session_id: data['id'],
        session_url: data['url'],
        publishable_key: @publishable_key
      }
    end
  end

  # Retrieve checkout session
  def retrieve_session(session_id)
    response = self.class.get(
      "/checkout/sessions/#{session_id}",
      basic_auth: auth,
      headers: headers
    )

    handle_response(response) { |data| data }
  end

  # Create payment intent (for custom checkout flows)
  def create_payment_intent(user:, amount:, plan_type:)
    payment = Payment.create!(
      user: user,
      order_id: Payment.generate_order_id,
      amount: amount,
      currency: 'KRW',
      status: 'pending',
      metadata: {
        plan_type: plan_type,
        payment_provider: 'stripe',
        requested_at: Time.current.iso8601
      }
    )

    response = self.class.post(
      '/payment_intents',
      basic_auth: auth,
      headers: headers,
      body: {
        amount: amount,
        currency: 'krw',
        automatic_payment_methods: { enabled: true },
        metadata: {
          user_id: user.id,
          order_id: payment.order_id,
          plan_type: plan_type
        }
      }
    )

    handle_response(response) do |data|
      payment.update!(
        payment_key: data['id'],
        metadata: payment.metadata.merge(
          stripe_payment_intent_id: data['id'],
          client_secret: data['client_secret']
        )
      )

      {
        payment: payment,
        client_secret: data['client_secret'],
        payment_intent_id: data['id']
      }
    end
  end

  # Confirm payment
  def confirm_payment(session_id:)
    session_data = retrieve_session(session_id)
    order_id = session_data['client_reference_id']
    payment = Payment.find_by!(order_id: order_id)

    if session_data['payment_status'] == 'paid'
      payment.update!(
        status: 'done',
        payment_key: session_data['payment_intent'],
        approved_at: Time.current,
        metadata: payment.metadata.merge(
          stripe_session_data: session_data,
          confirmed_at: Time.current.iso8601
        )
      )

      # Create subscription
      plan_type = payment.metadata['plan_type'] || 'season_pass'
      duration_days = plan_type == 'vip_pass' ? 365 : 90

      Subscription.create_from_payment(
        payment,
        plan_type: plan_type,
        duration_days: duration_days
      )

      # Send confirmation email
      PaymentMailer.payment_confirmed(payment).deliver_later

      { success: true, payment: payment }
    else
      payment.mark_as_failed!('PAYMENT_NOT_COMPLETED', 'Payment was not completed')
      { success: false, error: 'Payment not completed', payment: payment }
    end
  rescue StandardError => e
    Rails.logger.error "Stripe payment confirmation failed: #{e.message}"
    payment&.mark_as_failed!('CONFIRMATION_ERROR', e.message)
    { success: false, error: e.message, payment: payment }
  end

  # Create refund
  def create_refund(payment_intent_id:, amount: nil, reason: nil)
    body = {
      payment_intent: payment_intent_id
    }
    body[:amount] = amount if amount
    body[:reason] = map_refund_reason(reason) if reason

    response = self.class.post(
      '/refunds',
      basic_auth: auth,
      headers: headers,
      body: body
    )

    handle_response(response) { |data| data }
  end

  # Cancel payment intent
  def cancel_payment_intent(payment_intent_id:)
    response = self.class.post(
      "/payment_intents/#{payment_intent_id}/cancel",
      basic_auth: auth,
      headers: headers
    )

    handle_response(response) { |data| data }
  end

  # Retrieve payment intent
  def retrieve_payment_intent(payment_intent_id)
    response = self.class.get(
      "/payment_intents/#{payment_intent_id}",
      basic_auth: auth,
      headers: headers
    )

    handle_response(response) { |data| data }
  end

  # Handle webhook events
  def handle_webhook(payload, signature)
    event = construct_webhook_event(payload, signature)

    case event['type']
    when 'checkout.session.completed'
      handle_checkout_completed(event['data']['object'])
    when 'payment_intent.succeeded'
      handle_payment_succeeded(event['data']['object'])
    when 'payment_intent.payment_failed'
      handle_payment_failed(event['data']['object'])
    when 'charge.refunded'
      handle_refund(event['data']['object'])
    else
      Rails.logger.info "Unhandled Stripe webhook event: #{event['type']}"
    end

    { success: true }
  rescue StandardError => e
    Rails.logger.error "Webhook processing error: #{e.message}"
    { success: false, error: e.message }
  end

  # Create customer (for recurring payments in the future)
  def create_customer(user:)
    response = self.class.post(
      '/customers',
      basic_auth: auth,
      headers: headers,
      body: {
        email: user.email,
        name: user.name,
        metadata: {
          user_id: user.id
        }
      }
    )

    handle_response(response) do |data|
      user.update!(metadata: (user.metadata || {}).merge(stripe_customer_id: data['id']))
      data
    end
  end

  private

  def auth
    { username: @api_key, password: '' }
  end

  def headers
    {
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end

  def handle_response(response)
    if response.success?
      data = response.parsed_response
      yield(data) if block_given?
    else
      error = response.parsed_response
      error_message = error['error']&.dig('message') || 'Unknown error'
      raise StripeError, "Stripe API error: #{error_message}"
    end
  rescue HTTParty::Error => e
    raise StripeError, "Network error: #{e.message}"
  end

  def subscription_description(plan_type)
    case plan_type
    when 'season_pass'
      '90일 시즌 패스 - 모든 학습 자료 접근'
    when 'vip_pass'
      '365일 VIP 패스 - 모든 학습 자료 + 프리미엄 기능'
    else
      '학습 구독'
    end
  end

  def map_refund_reason(reason)
    case reason&.downcase
    when /duplicate/
      'duplicate'
    when /fraud/
      'fraudulent'
    when /customer.*request/
      'requested_by_customer'
    else
      'requested_by_customer'
    end
  end

  def construct_webhook_event(payload, signature)
    # In production, verify signature using Stripe library
    # For now, parse the payload
    JSON.parse(payload)
  rescue JSON::ParserError => e
    raise StripeError, "Invalid webhook payload: #{e.message}"
  end

  def handle_checkout_completed(session)
    order_id = session['client_reference_id']
    return unless order_id

    payment = Payment.find_by(order_id: order_id)
    return unless payment

    confirm_payment(session_id: session['id'])
  end

  def handle_payment_succeeded(payment_intent)
    order_id = payment_intent['metadata']['order_id']
    return unless order_id

    payment = Payment.find_by(order_id: order_id)
    return unless payment

    payment.mark_as_done! unless payment.success?
  end

  def handle_payment_failed(payment_intent)
    order_id = payment_intent['metadata']['order_id']
    return unless order_id

    payment = Payment.find_by(order_id: order_id)
    return unless payment

    error_message = payment_intent['last_payment_error']&.dig('message') || 'Payment failed'
    payment.mark_as_failed!('PAYMENT_FAILED', error_message)
  end

  def handle_refund(charge)
    payment = Payment.find_by(payment_key: charge['payment_intent'])
    return unless payment

    payment.update!(
      status: 'refunded',
      metadata: payment.metadata.merge(
        refund_data: charge,
        refunded_at: Time.current.iso8601
      )
    )

    payment.subscription&.deactivate!
    PaymentMailer.refund_processed(payment).deliver_later
  end
end
