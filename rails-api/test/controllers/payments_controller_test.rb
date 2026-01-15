require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user

    @payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'pending'
    )
  end

  test "should get index" do
    get payments_url
    assert_response :success
  end

  test "should get show" do
    get payment_url(@payment)
    assert_response :success
  end

  test "should request payment for season pass" do
    post request_payments_url, params: { plan_type: 'season_pass' }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 10000, json['payment']['amount']
  end

  test "should request payment for vip pass" do
    post request_payments_url, params: { plan_type: 'vip_pass' }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json['success']
    assert_equal 50000, json['payment']['amount']
  end

  test "should reject invalid plan type" do
    post request_payments_url, params: { plan_type: 'invalid' }, as: :json
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert json['error'].present?
  end

  test "should get checkout page" do
    get checkout_payments_url
    assert_response :success
  end

  test "should get success page" do
    get success_payments_url, params: {
      orderId: @payment.order_id,
      paymentKey: 'test_payment_key',
      amount: 10000
    }
    assert_response :success
  end

  test "should get fail page" do
    get fail_payments_url, params: {
      code: 'ERROR_CODE',
      message: 'Payment failed',
      orderId: @payment.order_id
    }
    assert_response :success
  end

  test "should get subscription status" do
    # Create a subscription for the user
    subscription = Subscription.create!(
      user: @user,
      payment: @payment,
      plan_type: Subscription::SEASON_PASS,
      price: 10000,
      starts_at: Time.current,
      expires_at: 90.days.from_now,
      is_active: true,
      status: 'active'
    )

    get subscription_status_payments_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json['has_subscription']
    assert json['is_active']
  end

  test "should return no subscription when user has none" do
    get subscription_status_payments_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_not json['has_subscription']
  end

  test "should require authentication for index" do
    sign_out @user
    get payments_url
    assert_redirected_to new_user_session_url
  end

  test "should require authentication for request payment" do
    sign_out @user
    post request_payments_url, params: { plan_type: 'season_pass' }, as: :json
    assert_response :unauthorized
  end
end
