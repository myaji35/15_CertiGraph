class TossPaymentService
  include HTTParty
  base_uri 'https://api.tosspayments.com/v1'

  SEASON_PASS_AMOUNT = 10_000 # 10,000 KRW
  VIP_PASS_AMOUNT = 50_000 # 50,000 KRW (example)

  class TossPaymentError < StandardError; end

  def initialize
    @client_key = ENV['TOSS_CLIENT_KEY']
    @secret_key = ENV['TOSS_SECRET_KEY']
    @success_url = ENV['TOSS_SUCCESS_URL'] || "#{ENV['APP_URL']}/payments/success"
    @fail_url = ENV['TOSS_FAIL_URL'] || "#{ENV['APP_URL']}/payments/fail"
  end

  # Request payment - creates initial payment record
  def request_payment(user:, plan_type: 'season_pass')
    amount = plan_type == 'vip_pass' ? VIP_PASS_AMOUNT : SEASON_PASS_AMOUNT

    payment = Payment.create!(
      user: user,
      order_id: Payment.generate_order_id,
      amount: amount,
      currency: 'KRW',
      status: 'pending',
      metadata: {
        plan_type: plan_type,
        requested_at: Time.current.iso8601
      }
    )

    {
      payment: payment,
      client_key: @client_key,
      success_url: @success_url,
      fail_url: @fail_url
    }
  end

  # Confirm payment after user approval
  def confirm_payment(order_id:, payment_key:, amount:)
    payment = Payment.find_by!(order_id: order_id)

    # Verify amount
    unless payment.amount == amount.to_i
      raise TossPaymentError, "Amount mismatch: expected #{payment.amount}, got #{amount}"
    end

    # Call Toss API to confirm payment
    response = self.class.post(
      '/payments/confirm',
      basic_auth: auth,
      headers: headers,
      body: {
        paymentKey: payment_key,
        orderId: order_id,
        amount: amount
      }.to_json
    )

    handle_response(response, payment, payment_key)
  rescue HTTParty::Error => e
    payment&.mark_as_failed!('NETWORK_ERROR', e.message)
    raise TossPaymentError, "Network error: #{e.message}"
  end

  # Cancel payment
  def cancel_payment(payment_key:, cancel_reason:, cancel_amount: nil)
    response = self.class.post(
      "/payments/#{payment_key}/cancel",
      basic_auth: auth,
      headers: headers,
      body: {
        cancelReason: cancel_reason,
        cancelAmount: cancel_amount
      }.compact.to_json
    )

    if response.success?
      response.parsed_response
    else
      error = response.parsed_response
      raise TossPaymentError, "Cancel failed: #{error['message']}"
    end
  rescue HTTParty::Error => e
    raise TossPaymentError, "Network error: #{e.message}"
  end

  # Get payment details
  def get_payment(payment_key)
    response = self.class.get(
      "/payments/#{payment_key}",
      basic_auth: auth,
      headers: headers
    )

    if response.success?
      response.parsed_response
    else
      error = response.parsed_response
      raise TossPaymentError, "Get payment failed: #{error['message']}"
    end
  rescue HTTParty::Error => e
    raise TossPaymentError, "Network error: #{e.message}"
  end

  private

  def auth
    { username: @secret_key, password: '' }
  end

  def headers
    {
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response, payment, payment_key)
    if response.success?
      data = response.parsed_response

      # Update payment with Toss response
      payment.update!(
        payment_key: payment_key,
        status: data['status'],
        method: data['method'],
        card_company: data.dig('card', 'company'),
        card_number: data.dig('card', 'number'),
        approved_at: data['approvedAt'] ? Time.parse(data['approvedAt']) : Time.current,
        metadata: payment.metadata.merge(toss_response: data)
      )

      # Mark as done if status is DONE
      payment.mark_as_done! if data['status'] == 'DONE'

      # Create subscription if payment is successful
      if payment.success?
        plan_type = payment.metadata['plan_type'] || 'season_pass'
        duration_days = plan_type == 'vip_pass' ? 365 : 90

        Subscription.create_from_payment(
          payment,
          plan_type: plan_type,
          duration_days: duration_days
        )
      end

      { success: true, payment: payment, data: data }
    else
      error = response.parsed_response
      payment.mark_as_failed!(error['code'], error['message'])
      { success: false, error: error, payment: payment }
    end
  end
end
