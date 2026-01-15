require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'done'
    )
    @subscription = Subscription.create!(
      user: @user,
      payment: @payment,
      plan_type: Subscription::SEASON_PASS,
      price: 10000,
      starts_at: Time.current,
      expires_at: 90.days.from_now,
      is_active: true,
      status: 'active'
    )
  end

  test "should be valid with valid attributes" do
    assert @subscription.valid?
  end

  test "should require plan_type" do
    @subscription.plan_type = nil
    assert_not @subscription.valid?
  end

  test "should validate plan_type inclusion" do
    @subscription.plan_type = 'invalid_plan'
    assert_not @subscription.valid?
  end

  test "should require price" do
    @subscription.price = nil
    assert_not @subscription.valid?
  end

  test "should require positive price" do
    @subscription.price = -100
    assert_not @subscription.valid?
  end

  test "should require starts_at" do
    @subscription.starts_at = nil
    assert_not @subscription.valid?
  end

  test "should require expires_at" do
    @subscription.expires_at = nil
    assert_not @subscription.valid?
  end

  test "expires_at must be after starts_at" do
    @subscription.expires_at = @subscription.starts_at - 1.day
    assert_not @subscription.valid?
    assert_includes @subscription.errors[:expires_at], 'must be after start date'
  end

  test "should belong to user" do
    assert_respond_to @subscription, :user
    assert_equal @user, @subscription.user
  end

  test "should belong to payment" do
    assert_respond_to @subscription, :payment
    assert_equal @payment, @subscription.payment
  end

  test "active? should return true for active non-expired subscription" do
    assert @subscription.active?
  end

  test "active? should return false for expired subscription" do
    @subscription.update!(expires_at: 1.day.ago)
    assert_not @subscription.active?
  end

  test "expired? should return true for past expiration date" do
    @subscription.update!(expires_at: 1.day.ago)
    assert @subscription.expired?
  end

  test "days_remaining should return correct number" do
    days = @subscription.days_remaining
    assert days > 0
    assert days <= 90
  end

  test "days_remaining should return 0 for expired subscription" do
    @subscription.update!(expires_at: 1.day.ago)
    assert_equal 0, @subscription.days_remaining
  end

  test "deactivate! should deactivate subscription and update user" do
    @subscription.deactivate!
    assert_not @subscription.is_active
    assert_equal 'inactive', @subscription.status
    @user.reload
    assert_not @user.is_paid
    assert_nil @user.valid_until
  end

  test "create_from_payment should create subscription with correct attributes" do
    new_payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 50000,
      currency: 'KRW',
      status: 'done'
    )

    subscription = Subscription.create_from_payment(
      new_payment,
      plan_type: Subscription::VIP_PASS,
      duration_days: 365
    )

    assert subscription.persisted?
    assert_equal Subscription::VIP_PASS, subscription.plan_type
    assert_equal 50000, subscription.price
    assert subscription.is_active
  end

  test "should update user payment status on save" do
    @user.reload
    assert @user.is_paid
    assert_equal @subscription.expires_at, @user.valid_until
    assert_equal @subscription.plan_type, @user.subscription_type
  end

  test "scope active should return only active subscriptions" do
    expired_sub = Subscription.create!(
      user: @user,
      payment: @payment,
      plan_type: Subscription::SEASON_PASS,
      price: 10000,
      starts_at: 100.days.ago,
      expires_at: 10.days.ago,
      is_active: true,
      status: 'active'
    )

    active_subs = Subscription.active
    assert_includes active_subs, @subscription
    assert_not_includes active_subs, expired_sub
  end

  test "scope expired should return only expired subscriptions" do
    expired_sub = Subscription.create!(
      user: @user,
      payment: @payment,
      plan_type: Subscription::SEASON_PASS,
      price: 10000,
      starts_at: 100.days.ago,
      expires_at: 10.days.ago,
      is_active: true,
      status: 'active'
    )

    expired_subs = Subscription.expired
    assert_includes expired_subs, expired_sub
    assert_not_includes expired_subs, @subscription
  end
end
