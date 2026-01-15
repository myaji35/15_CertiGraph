require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'pending'
    )
  end

  test "should be valid with valid attributes" do
    assert @payment.valid?
  end

  test "should require order_id" do
    @payment.order_id = nil
    assert_not @payment.valid?
  end

  test "should require amount" do
    @payment.amount = nil
    assert_not @payment.valid?
  end

  test "should require positive amount" do
    @payment.amount = -100
    assert_not @payment.valid?
  end

  test "should require currency" do
    @payment.currency = nil
    assert_not @payment.valid?
  end

  test "should require status" do
    @payment.status = nil
    assert_not @payment.valid?
  end

  test "should have unique order_id" do
    duplicate_payment = @payment.dup
    assert_not duplicate_payment.valid?
  end

  test "should generate order_id" do
    order_id = Payment.generate_order_id
    assert order_id.starts_with?('ORDER_')
    assert order_id.length > 20
  end

  test "success? should return true for done status" do
    @payment.update!(status: 'done')
    assert @payment.success?
  end

  test "failed? should return true for failed statuses" do
    @payment.update!(status: 'failed')
    assert @payment.failed?
  end

  test "pending? should return true for pending statuses" do
    assert @payment.pending?
  end

  test "mark_as_done! should update status and approved_at" do
    @payment.mark_as_done!
    assert_equal 'done', @payment.status
    assert_not_nil @payment.approved_at
  end

  test "mark_as_failed! should update status and failure fields" do
    @payment.mark_as_failed!('ERROR_CODE', 'Error message')
    assert_equal 'failed', @payment.status
    assert_equal 'ERROR_CODE', @payment.failure_code
    assert_equal 'Error message', @payment.failure_message
  end

  test "should belong to user" do
    assert_respond_to @payment, :user
    assert_equal @user, @payment.user
  end

  test "should have one subscription" do
    assert_respond_to @payment, :subscription
  end

  test "scope successful should return only done payments" do
    done_payment = Payment.create!(
      user: @user,
      order_id: Payment.generate_order_id,
      amount: 10000,
      currency: 'KRW',
      status: 'done'
    )

    successful = Payment.successful
    assert_includes successful, done_payment
    assert_not_includes successful, @payment
  end

  test "scope pending should return pending payments" do
    pending_payments = Payment.pending
    assert_includes pending_payments, @payment
  end
end
