require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should have many payments" do
    assert_respond_to @user, :payments
  end

  test "should have many subscriptions" do
    assert_respond_to @user, :subscriptions
  end

  test "has_active_subscription? should return true for paid user with valid subscription" do
    @user.update!(is_paid: true, valid_until: 30.days.from_now)
    assert @user.has_active_subscription?
  end

  test "has_active_subscription? should return false for unpaid user" do
    @user.update!(is_paid: false, valid_until: 30.days.from_now)
    assert_not @user.has_active_subscription?
  end

  test "has_active_subscription? should return false for expired subscription" do
    @user.update!(is_paid: true, valid_until: 1.day.ago)
    assert_not @user.has_active_subscription?
  end

  test "subscription_expired? should return true for expired valid_until" do
    @user.update!(valid_until: 1.day.ago)
    assert @user.subscription_expired?
  end

  test "subscription_expired? should return false for future valid_until" do
    @user.update!(valid_until: 30.days.from_now)
    assert_not @user.subscription_expired?
  end

  test "current_subscription should return most recent active subscription" do
    payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'done'
    )

    subscription = Subscription.create!(
      user: @user,
      payment: payment,
      plan_type: Subscription::SEASON_PASS,
      price: 10000,
      starts_at: Time.current,
      expires_at: 90.days.from_now,
      is_active: true,
      status: 'active'
    )

    assert_equal subscription, @user.current_subscription
  end

  test "check_subscription_expiration should update user when expired" do
    @user.update!(is_paid: true, valid_until: 1.day.ago, subscription_type: 'season_pass')
    @user.check_subscription_expiration
    @user.reload

    assert_not @user.is_paid
    assert_nil @user.valid_until
    assert_nil @user.subscription_type
  end

  test "check_subscription_expiration should not update user when not expired" do
    @user.update!(is_paid: true, valid_until: 30.days.from_now, subscription_type: 'season_pass')
    @user.check_subscription_expiration
    @user.reload

    assert @user.is_paid
    assert_not_nil @user.valid_until
    assert_not_nil @user.subscription_type
  end
end
