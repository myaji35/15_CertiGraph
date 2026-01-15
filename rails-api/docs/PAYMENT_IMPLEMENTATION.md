# Payment System Implementation Summary

## Overview
Complete Toss Payments integration for ExamsGraph (CertiGraph) Rails application with season pass and VIP pass subscription models.

## Implementation Date
2026-01-15

## Components Implemented

### 1. Database Schema

#### Migrations Created
- `20260115021336_create_payments.rb` - Payment transactions table
- `20260115021337_create_subscriptions.rb` - User subscriptions table
- `20260115021338_add_payment_fields_to_users.rb` - User payment status fields

#### Payments Table
- `user_id` (foreign key)
- `order_id` (unique, indexed)
- `payment_key` (Toss payment key)
- `amount` (integer, KRW)
- `currency` (default: 'KRW')
- `status` (enum: pending, ready, in_progress, waiting_for_deposit, done, canceled, partial_canceled, aborted, expired, failed)
- `method` (payment method from Toss)
- `card_company` (card company name)
- `card_number` (masked card number)
- `approved_at` (datetime)
- `failure_code` (error code from Toss)
- `failure_message` (error message from Toss)
- `metadata` (JSON field for additional data)

#### Subscriptions Table
- `user_id` (foreign key)
- `payment_id` (foreign key)
- `plan_type` (season_pass, vip_pass)
- `price` (integer)
- `starts_at` (datetime)
- `expires_at` (datetime)
- `is_active` (boolean)
- `status` (string: active, inactive)

#### User Payment Fields
- `is_paid` (boolean, default: false)
- `valid_until` (datetime)
- `subscription_type` (string)

### 2. Models

#### Payment Model (`app/models/payment.rb`)
**Relationships:**
- `belongs_to :user`
- `has_one :subscription`

**Key Methods:**
- `self.generate_order_id` - Generates unique order ID
- `success?` - Check if payment succeeded
- `failed?` - Check if payment failed
- `pending?` - Check if payment is pending
- `cancelable?` - Check if payment can be canceled
- `mark_as_done!` - Mark payment as completed
- `mark_as_failed!(code, message)` - Mark payment as failed

**Scopes:**
- `successful` - Only successful payments
- `pending` - Pending payments
- `failed` - Failed payments
- `recent` - Ordered by creation date

#### Subscription Model (`app/models/subscription.rb`)
**Relationships:**
- `belongs_to :user`
- `belongs_to :payment`

**Constants:**
- `SEASON_PASS = 'season_pass'`
- `VIP_PASS = 'vip_pass'`

**Key Methods:**
- `self.create_from_payment(payment, plan_type:, duration_days:)` - Create subscription from payment
- `active?` - Check if subscription is active
- `expired?` - Check if subscription has expired
- `days_remaining` - Calculate days until expiration
- `deactivate!` - Deactivate subscription

**Callbacks:**
- `before_save :update_user_payment_status` - Update user payment status
- `after_create :activate_user_subscription` - Activate user subscription
- `after_save :check_expiration` - Check and handle expiration

**Scopes:**
- `active` - Only active non-expired subscriptions
- `expired` - Only expired subscriptions
- `by_plan(plan_type)` - Filter by plan type

#### User Model Updates (`app/models/user.rb`)
**New Relationships:**
- `has_many :payments`
- `has_many :subscriptions`

**New Methods:**
- `has_active_subscription?` - Check if user has active subscription
- `subscription_expired?` - Check if user's subscription expired
- `current_subscription` - Get user's current active subscription
- `check_subscription_expiration` - Check and update expired subscriptions

### 3. Service Layer

#### TossPaymentService (`app/services/toss_payment_service.rb`)
**Configuration:**
- Base URI: `https://api.tosspayments.com/v1`
- Season Pass: 10,000 KRW
- VIP Pass: 50,000 KRW

**Methods:**
1. `request_payment(user:, plan_type:)`
   - Creates initial payment record
   - Returns payment data and client configuration

2. `confirm_payment(order_id:, payment_key:, amount:)`
   - Confirms payment with Toss API
   - Updates payment status
   - Creates subscription if successful

3. `cancel_payment(payment_key:, cancel_reason:, cancel_amount:)`
   - Cancels payment via Toss API
   - Updates payment and subscription status

4. `get_payment(payment_key)`
   - Fetches payment details from Toss API

**Error Handling:**
- Custom `TossPaymentError` exception
- Network error handling
- Amount validation
- Response error handling

### 4. Controller

#### PaymentsController (`app/controllers/payments_controller.rb`)
**Endpoints:**

1. `GET /payments` - List user's payments
2. `GET /payments/:id` - Show payment details
3. `GET /payments/checkout` - Payment checkout page
4. `POST /payments/request` - Request new payment
5. `POST /payments/confirm` - Confirm payment after Toss redirect
6. `GET /payments/success` - Payment success page
7. `GET /payments/fail` - Payment failure page
8. `POST /payments/:id/cancel` - Cancel payment
9. `GET /payments/subscription/status` - Get subscription status

**Authentication:**
- Requires authentication for all endpoints except success/fail pages

**Error Handling:**
- Validates plan types
- Handles missing parameters
- Catches service errors
- Returns appropriate HTTP status codes

### 5. Views

#### Checkout Page (`app/views/payments/checkout.html.erb`)
**Features:**
- Season Pass and VIP Pass pricing cards
- Toss Payments Widget integration
- Plan selection interface
- Payment method selection
- Real-time payment processing

**JavaScript Integration:**
- Toss Payments SDK v1
- Payment widget initialization
- CSRF token handling
- Error handling

#### Success Page (`app/views/payments/success.html.erb`)
**Features:**
- Success confirmation message
- Payment details display
- Subscription information
- Auto-confirmation via JavaScript
- Navigation to dashboard

#### Fail Page (`app/views/payments/fail.html.erb`)
**Features:**
- Error message display
- Error code display
- Troubleshooting tips
- Retry payment option
- Customer support information

### 6. Routes

```ruby
resources :payments, only: [:index, :show] do
  collection do
    get :checkout
    post :request, to: 'payments#request_payment'
    post :confirm
    get :success
    get :fail
    get 'subscription/status', to: 'payments#subscription_status'
  end
  member do
    post :cancel
  end
end
```

### 7. Environment Variables

Required environment variables (in `.env.example`):

```bash
# Toss Payments Configuration
TOSS_CLIENT_KEY=test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq
TOSS_SECRET_KEY=test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
TOSS_SUCCESS_URL=http://localhost:3000/payments/success
TOSS_FAIL_URL=http://localhost:3000/payments/fail

# Application Configuration
APP_URL=http://localhost:3000
```

### 8. Test Suite

#### Model Tests
- `test/models/payment_test.rb` - Payment model tests (18 tests)
- `test/models/subscription_test.rb` - Subscription model tests (19 tests)
- `test/models/user_test.rb` - User payment methods tests (10 tests)

#### Service Tests
- `test/services/toss_payment_service_test.rb` - Service integration tests (8 tests)
  - Uses WebMock for API mocking

#### Controller Tests
- `test/controllers/payments_controller_test.rb` - Controller endpoint tests (12 tests)

#### Fixtures
- `test/fixtures/payments.yml` - Payment test data
- `test/fixtures/subscriptions.yml` - Subscription test data

**Total Tests:** 67 comprehensive tests

## Payment Flow

### 1. User Initiates Payment
1. User visits `/payments/checkout`
2. Selects plan (Season Pass or VIP Pass)
3. Frontend calls `POST /payments/request`
4. Backend creates Payment record with `pending` status
5. Returns payment data and Toss client key

### 2. Payment Widget
1. Frontend initializes Toss Payment Widget
2. User enters payment information
3. User confirms payment
4. Toss redirects to success or fail URL with query parameters

### 3. Payment Confirmation
1. Success page auto-calls `POST /payments/confirm`
2. Backend calls Toss API to confirm payment
3. Updates Payment status to `done`
4. Creates Subscription record
5. Updates User payment status

### 4. Subscription Activation
1. Subscription sets `is_active: true`
2. Updates User `is_paid: true` and `valid_until`
3. User role updated to `paid`
4. User gains access to premium features

## Pricing Plans

### Season Pass
- **Price:** ₩10,000 KRW
- **Duration:** 90 days
- **Features:**
  - Unlimited material uploads
  - AI-powered error notes
  - 3D knowledge graph visualization
  - Personalized learning recommendations

### VIP Pass
- **Price:** ₩50,000 KRW
- **Duration:** 365 days
- **Features:**
  - All Season Pass features
  - Priority customer support
  - Beta feature access
  - 1-year subscription

## Security Considerations

1. **Authentication Required:** All payment operations except success/fail pages require user authentication
2. **CSRF Protection:** All POST requests include CSRF token
3. **Amount Validation:** Payment amount verified before confirmation
4. **Secret Key Security:** Toss secret key stored in environment variables
5. **Payment Key Validation:** Payment keys validated against Toss API

## Error Handling

### Payment Errors
- Invalid plan type
- Amount mismatch
- Network errors
- Toss API errors
- Missing parameters

### Subscription Errors
- Invalid date ranges
- Expired subscriptions
- Inactive subscriptions

## API Integration Points

### Toss Payments API
- **Base URL:** `https://api.tosspayments.com/v1`
- **Authentication:** Basic Auth (Secret Key)
- **Endpoints Used:**
  - `POST /payments/confirm` - Confirm payment
  - `POST /payments/{paymentKey}/cancel` - Cancel payment
  - `GET /payments/{paymentKey}` - Get payment details

## Database Indexes

For optimal performance, the following indexes are created:
- `payments.order_id` (unique)
- `payments.payment_key`
- `payments.status`
- `subscriptions.status`
- `subscriptions.is_active`
- `subscriptions.[user_id, is_active]`
- `users.is_paid`
- `users.valid_until`

## Migration Instructions

To apply the payment system to the database:

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api

# Run migrations
rails db:migrate

# Run tests
rails test test/models/payment_test.rb
rails test test/models/subscription_test.rb
rails test test/services/toss_payment_service_test.rb
rails test test/controllers/payments_controller_test.rb
```

## Next Steps

1. **Environment Setup:**
   - Copy `.env.example` to `.env`
   - Add real Toss Payments credentials

2. **Testing:**
   - Run test suite to verify implementation
   - Test payment flow in development

3. **Production Deployment:**
   - Update environment variables for production
   - Switch from test keys to live keys
   - Configure production URLs

4. **Monitoring:**
   - Set up payment monitoring
   - Configure error notifications
   - Track subscription metrics

## Dependencies

Required gems (already in Gemfile):
- `httparty` - HTTP requests to Toss API
- `devise` - User authentication
- `sqlite3` - Database (development)

For testing:
- `webmock` - API mocking (needs to be added to Gemfile)

## File Structure

```
rails-api/
├── app/
│   ├── controllers/
│   │   └── payments_controller.rb
│   ├── models/
│   │   ├── payment.rb
│   │   ├── subscription.rb
│   │   └── user.rb (updated)
│   ├── services/
│   │   └── toss_payment_service.rb
│   └── views/
│       └── payments/
│           ├── checkout.html.erb
│           ├── success.html.erb
│           └── fail.html.erb
├── config/
│   └── routes.rb (updated)
├── db/
│   └── migrate/
│       ├── 20260115021336_create_payments.rb
│       ├── 20260115021337_create_subscriptions.rb
│       └── 20260115021338_add_payment_fields_to_users.rb
├── test/
│   ├── controllers/
│   │   └── payments_controller_test.rb
│   ├── fixtures/
│   │   ├── payments.yml
│   │   └── subscriptions.yml
│   ├── models/
│   │   ├── payment_test.rb
│   │   ├── subscription_test.rb
│   │   └── user_test.rb
│   └── services/
│       └── toss_payment_service_test.rb
├── .env.example (updated)
└── docs/
    └── PAYMENT_IMPLEMENTATION.md (this file)
```

## Support

For issues or questions:
- Toss Payments Documentation: https://developers.tosspayments.com/
- Project Repository: /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api

## Changelog

### 2026-01-15 - Initial Implementation
- ✅ Created Payment and Subscription models
- ✅ Implemented TossPaymentService
- ✅ Created PaymentsController with all endpoints
- ✅ Designed payment checkout, success, and fail views
- ✅ Added payment routes
- ✅ Updated User model with payment methods
- ✅ Wrote comprehensive test suite (67 tests)
- ✅ Updated environment configuration
- ✅ Created implementation documentation
