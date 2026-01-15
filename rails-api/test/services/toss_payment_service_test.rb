require "test_helper"
require "webmock/minitest"

class TossPaymentServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @service = TossPaymentService.new

    # Set environment variables for testing
    ENV['TOSS_CLIENT_KEY'] = 'test_ck_123'
    ENV['TOSS_SECRET_KEY'] = 'test_sk_123'
    ENV['TOSS_SUCCESS_URL'] = 'http://localhost:3000/payments/success'
    ENV['TOSS_FAIL_URL'] = 'http://localhost:3000/payments/fail'
  end

  test "request_payment should create payment and return payment data" do
    result = @service.request_payment(user: @user, plan_type: 'season_pass')

    assert result[:payment].present?
    assert_equal 10000, result[:payment].amount
    assert_equal 'KRW', result[:payment].currency
    assert_equal 'pending', result[:payment].status
    assert_equal 'test_ck_123', result[:client_key]
  end

  test "request_payment should create VIP pass with correct amount" do
    result = @service.request_payment(user: @user, plan_type: 'vip_pass')

    assert_equal 50000, result[:payment].amount
    assert_equal 'vip_pass', result[:payment].metadata['plan_type']
  end

  test "confirm_payment should raise error for amount mismatch" do
    payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'pending'
    )

    assert_raises(TossPaymentService::TossPaymentError) do
      @service.confirm_payment(
        order_id: payment.order_id,
        payment_key: 'test_payment_key',
        amount: 20000
      )
    end
  end

  test "confirm_payment should handle successful response" do
    payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'pending',
      metadata: { plan_type: 'season_pass' }
    )

    # Mock successful Toss API response
    stub_request(:post, "https://api.tosspayments.com/v1/payments/confirm")
      .to_return(
        status: 200,
        body: {
          status: 'DONE',
          method: 'card',
          approvedAt: Time.current.iso8601,
          card: {
            company: 'KB',
            number: '1234****5678'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.confirm_payment(
      order_id: payment.order_id,
      payment_key: 'test_payment_key',
      amount: 10000
    )

    assert result[:success]
    payment.reload
    assert_equal 'done', payment.status
    assert_not_nil payment.approved_at
  end

  test "confirm_payment should handle error response" do
    payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'pending'
    )

    # Mock error Toss API response
    stub_request(:post, "https://api.tosspayments.com/v1/payments/confirm")
      .to_return(
        status: 400,
        body: {
          code: 'INVALID_PAYMENT_KEY',
          message: 'Payment key is invalid'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.confirm_payment(
      order_id: payment.order_id,
      payment_key: 'invalid_payment_key',
      amount: 10000
    )

    assert_not result[:success]
    payment.reload
    assert_equal 'failed', payment.status
  end

  test "confirm_payment should create subscription for successful payment" do
    payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'pending',
      metadata: { plan_type: 'season_pass' }
    )

    # Mock successful Toss API response
    stub_request(:post, "https://api.tosspayments.com/v1/payments/confirm")
      .to_return(
        status: 200,
        body: {
          status: 'DONE',
          method: 'card',
          approvedAt: Time.current.iso8601
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.confirm_payment(
      order_id: payment.order_id,
      payment_key: 'test_payment_key',
      amount: 10000
    )

    assert result[:success]
    payment.reload
    assert_not_nil payment.subscription
    assert_equal 'season_pass', payment.subscription.plan_type
  end

  test "cancel_payment should call Toss API" do
    stub_request(:post, "https://api.tosspayments.com/v1/payments/test_payment_key/cancel")
      .to_return(
        status: 200,
        body: { status: 'CANCELED' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.cancel_payment(
      payment_key: 'test_payment_key',
      cancel_reason: 'User requested'
    )

    assert_equal 'CANCELED', result['status']
  end

  test "get_payment should fetch payment details from Toss API" do
    stub_request(:get, "https://api.tosspayments.com/v1/payments/test_payment_key")
      .to_return(
        status: 200,
        body: {
          orderId: 'ORDER_123',
          amount: 10000,
          status: 'DONE'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    result = @service.get_payment('test_payment_key')

    assert_equal 'ORDER_123', result['orderId']
    assert_equal 10000, result['amount']
  end
end
