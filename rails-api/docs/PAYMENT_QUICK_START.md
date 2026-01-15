# Payment System Quick Start Guide

## Setup Instructions

### 1. Install Dependencies

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api
bundle install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Edit `.env` and add your Toss Payments credentials:

```bash
# Toss Payments Configuration
TOSS_CLIENT_KEY=your_client_key_here
TOSS_SECRET_KEY=your_secret_key_here
TOSS_SUCCESS_URL=http://localhost:3000/payments/success
TOSS_FAIL_URL=http://localhost:3000/payments/fail

# Application Configuration
APP_URL=http://localhost:3000
```

### 3. Run Migrations

```bash
rails db:migrate
```

### 4. Start Server

```bash
rails server
```

## Using the Payment System

### For Users (Frontend)

#### 1. Access Payment Page
```
http://localhost:3000/payments/checkout
```

#### 2. Payment Flow
1. Select plan (Season Pass or VIP Pass)
2. Enter payment information in Toss widget
3. Confirm payment
4. Redirect to success or fail page
5. Automatic subscription activation

### For Developers (Backend)

#### Request Payment

```ruby
service = TossPaymentService.new
result = service.request_payment(
  user: current_user,
  plan_type: 'season_pass' # or 'vip_pass'
)

payment = result[:payment]
client_key = result[:client_key]
```

#### Confirm Payment

```ruby
service = TossPaymentService.new
result = service.confirm_payment(
  order_id: 'ORDER_123',
  payment_key: 'payment_key_from_toss',
  amount: 10000
)

if result[:success]
  payment = result[:payment]
  subscription = payment.subscription
end
```

#### Cancel Payment

```ruby
service = TossPaymentService.new
result = service.cancel_payment(
  payment_key: 'payment_key',
  cancel_reason: 'User requested cancellation'
)
```

#### Check User Subscription

```ruby
user = User.find(1)

# Check if user has active subscription
user.has_active_subscription? # => true/false

# Get current subscription
subscription = user.current_subscription

# Check days remaining
subscription.days_remaining # => 45

# Check if expired
user.subscription_expired? # => true/false
```

## API Endpoints

### Payment Endpoints

```
GET    /payments                        # List user's payments
GET    /payments/:id                    # Show payment details
GET    /payments/checkout               # Payment checkout page
POST   /payments/request                # Request new payment
POST   /payments/confirm                # Confirm payment
GET    /payments/success                # Payment success page
GET    /payments/fail                   # Payment failure page
POST   /payments/:id/cancel             # Cancel payment
GET    /payments/subscription/status    # Get subscription status
```

### Request Examples

#### Request Payment (API)

```bash
curl -X POST http://localhost:3000/payments/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"plan_type": "season_pass"}'
```

Response:
```json
{
  "success": true,
  "payment": {
    "id": 1,
    "order_id": "ORDER_20260115_ABC123",
    "amount": 10000,
    "currency": "KRW",
    "status": "pending"
  },
  "clientKey": "test_ck_123",
  "successUrl": "http://localhost:3000/payments/success",
  "failUrl": "http://localhost:3000/payments/fail"
}
```

#### Get Subscription Status (API)

```bash
curl -X GET http://localhost:3000/payments/subscription/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
{
  "has_subscription": true,
  "subscription": {
    "id": 1,
    "plan_type": "season_pass",
    "price": 10000,
    "starts_at": "2026-01-15T00:00:00Z",
    "expires_at": "2026-04-15T00:00:00Z",
    "is_active": true,
    "status": "active"
  },
  "is_active": true,
  "days_remaining": 90,
  "expires_at": "2026-04-15T00:00:00Z"
}
```

## Testing

### Run All Payment Tests

```bash
# All tests
rails test

# Model tests only
rails test test/models/payment_test.rb
rails test test/models/subscription_test.rb
rails test test/models/user_test.rb

# Service tests only
rails test test/services/toss_payment_service_test.rb

# Controller tests only
rails test test/controllers/payments_controller_test.rb
```

### Manual Testing

#### 1. Create Test User

```ruby
rails console
user = User.create!(
  email: 'test@example.com',
  password: 'password123',
  name: 'Test User'
)
```

#### 2. Create Test Payment

```ruby
service = TossPaymentService.new
result = service.request_payment(user: user, plan_type: 'season_pass')
payment = result[:payment]
```

#### 3. Test Payment Flow

Visit: `http://localhost:3000/payments/checkout`

Use Toss test card numbers:
- Success: `4000000000000001`
- Failure: `4000000000000002`

## Database Queries

### Find User's Active Subscription

```ruby
user = User.find(1)
subscription = user.subscriptions.active.first
```

### Find All Successful Payments

```ruby
payments = Payment.successful
```

### Find Expired Subscriptions

```ruby
expired = Subscription.expired
```

### Get Payment by Order ID

```ruby
payment = Payment.find_by(order_id: 'ORDER_123')
```

## Common Operations

### Activate Premium Features for User

```ruby
user = User.find(1)
payment = Payment.create!(
  user: user,
  order_id: Payment.generate_order_id,
  amount: 10000,
  currency: 'KRW',
  status: 'done',
  approved_at: Time.current
)

Subscription.create_from_payment(
  payment,
  plan_type: Subscription::SEASON_PASS,
  duration_days: 90
)
```

### Check and Update Expired Subscriptions

```ruby
User.find_each do |user|
  user.check_subscription_expiration
end
```

### Cancel User Subscription

```ruby
user = User.find(1)
subscription = user.current_subscription
subscription.deactivate!
```

## Troubleshooting

### Payment Not Confirming

1. Check Toss API credentials in `.env`
2. Verify network connectivity
3. Check Rails logs: `tail -f log/development.log`
4. Verify payment amount matches

### Subscription Not Activating

1. Check payment status is 'done'
2. Verify subscription was created
3. Check user payment fields updated
4. Review callback execution in logs

### Test Failures

1. Ensure webmock gem is installed: `bundle install`
2. Check database is clean: `rails db:test:prepare`
3. Verify fixtures are correct
4. Check environment variables for test

## Monitoring

### Payment Statistics

```ruby
# Total successful payments
Payment.successful.count

# Revenue this month
Payment.successful
  .where('approved_at >= ?', 1.month.ago)
  .sum(:amount)

# Active subscriptions count
Subscription.active.count

# Users with active subscriptions
User.where(is_paid: true).count
```

### Subscription Metrics

```ruby
# Expiring soon (next 7 days)
Subscription.active
  .where('expires_at <= ?', 7.days.from_now)
  .count

# Average subscription duration
Subscription.average('DATEDIFF(expires_at, starts_at)')

# Subscription by plan type
Subscription.active.group(:plan_type).count
```

## Security Notes

1. Never commit `.env` file to version control
2. Use test keys in development
3. Use production keys only in production
4. Validate all payment amounts
5. Verify CSRF tokens on all POST requests
6. Use HTTPS in production
7. Monitor for suspicious payment patterns

## Support

### Toss Payments
- Documentation: https://developers.tosspayments.com/
- Test Dashboard: https://developers.tosspayments.com/sandbox
- Support: support@tosspayments.com

### Project
- Implementation Guide: `docs/PAYMENT_IMPLEMENTATION.md`
- API Documentation: `docs/API.md` (if available)

## Next Steps

1. Test payment flow in development
2. Verify all tests pass
3. Configure production environment
4. Set up payment monitoring
5. Implement webhook handling (optional)
6. Add payment analytics (optional)
7. Set up automated subscription renewal checks
