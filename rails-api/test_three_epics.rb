#!/usr/bin/env ruby
# Test script for Epic 1 (User Authentication), Epic 14 (Payment Integration), Epic 18 (Exam Schedule Calendar)

require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

class EpicTester
  attr_reader :results

  def initialize
    @results = {
      total_tests: 0,
      passed: 0,
      failed: 0,
      bugs: [],
      recommendations: []
    }
    @auth_token = nil
    @current_user = nil
  end

  def run_all_tests
    puts "\n=========================================="
    puts "Testing Epic 1: User Authentication"
    puts "==========================================\n"
    test_epic1_authentication

    puts "\n=========================================="
    puts "Testing Epic 14: Payment Integration"
    puts "==========================================\n"
    test_epic14_payments

    puts "\n=========================================="
    puts "Testing Epic 18: Exam Schedule Calendar"
    puts "==========================================\n"
    test_epic18_exam_schedules

    print_summary
  end

  private

  def test_epic1_authentication
    # Test 1: POST /signup - User Registration
    test("POST /signup - User Registration") do
      response = make_request(:post, '/signup', {
        user: {
          email: "test_#{Time.now.to_i}@example.com",
          password: 'Password123!',
          password_confirmation: 'Password123!',
          name: 'Test User'
        }
      })

      if response.code.to_i == 201 || response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['success'] || body['user']
          @current_user = body['user']
          @auth_token = body['token']
          { success: true, message: "User created successfully" }
        else
          { success: false, error: "Response missing user/success field", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 2: POST /signin - User Login
    test("POST /signin - User Login") do
      if @current_user
        response = make_request(:post, '/signin', {
          user: {
            email: @current_user['email'],
            password: 'Password123!'
          }
        })

        if response.code.to_i == 200
          body = JSON.parse(response.body)
          if body['success'] || body['token']
            @auth_token = body['token'] || @auth_token
            { success: true, message: "Login successful" }
          else
            { success: false, error: "Missing success/token in response", response: body }
          end
        else
          { success: false, error: "HTTP #{response.code}", body: response.body }
        end
      else
        { success: false, error: "No user created in previous test" }
      end
    end

    # Test 3: GET /users/profile - Get Profile
    test("GET /users/profile - Get Profile") do
      response = make_authenticated_request(:get, '/users/profile')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['user']
          { success: true, message: "Profile retrieved successfully" }
        else
          { success: false, error: "Response missing user field", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 4: POST /users/two_factor/setup - Setup 2FA
    test("POST /users/two_factor/setup - Setup 2FA") do
      response = make_authenticated_request(:post, '/users/two_factor/setup')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['qr_code'] || body['secret']
          { success: true, message: "2FA setup initiated successfully" }
        else
          { success: false, error: "Response missing qr_code/secret", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 5: POST /users/two_factor/enable - Enable 2FA (expected to fail without valid OTP)
    test("POST /users/two_factor/enable - Enable 2FA (expect validation error)") do
      response = make_authenticated_request(:post, '/users/two_factor/enable', {
        otp_code: '123456'
      })

      if response.code.to_i == 422
        { success: true, message: "Correctly rejects invalid OTP" }
      elsif response.code.to_i == 200
        { success: false, error: "Should not accept random OTP code" }
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 6: POST /users/two_factor/verify - Verify 2FA
    test("POST /users/two_factor/verify - Verify 2FA (expect validation error)") do
      response = make_authenticated_request(:post, '/users/two_factor/verify', {
        otp_code: '123456'
      })

      # Should fail since 2FA is not enabled or code is invalid
      if response.code.to_i == 401 || response.code.to_i == 422
        { success: true, message: "Correctly rejects invalid verification" }
      else
        { success: false, error: "Unexpected response: HTTP #{response.code}" }
      end
    end

    # Test 7: DELETE /logout - User Logout
    test("DELETE /logout - User Logout") do
      response = make_authenticated_request(:delete, '/logout')

      if response.code.to_i == 200 || response.code.to_i == 204
        body = response.body.empty? ? {} : JSON.parse(response.body)
        { success: true, message: "Logout successful" }
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end
  end

  def test_epic14_payments
    # Need to login first for payment tests
    login_for_payment_tests

    # Test 1: POST /payments/request - Request Payment
    test("POST /payments/request - Request Payment") do
      response = make_authenticated_request(:post, '/payments/request', {
        plan_type: 'season_pass'
      })

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['success'] && body['payment']
          @test_payment_id = body['payment']['id']
          @test_order_id = body['payment']['order_id']
          { success: true, message: "Payment request created successfully" }
        else
          { success: false, error: "Response missing success/payment", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 2: GET /payments/history - Get Payment History
    test("GET /payments/history - Get Payment History") do
      response = make_authenticated_request(:get, '/payments/history')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['success'] && body['payments']
          { success: true, message: "Payment history retrieved successfully" }
        else
          { success: false, error: "Response format incorrect", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 3: GET /payments/:id - Get Payment Details
    test("GET /payments/:id - Get Payment Details") do
      if @test_payment_id
        response = make_authenticated_request(:get, "/payments/#{@test_payment_id}")

        if response.code.to_i == 200
          body = JSON.parse(response.body)
          { success: true, message: "Payment details retrieved successfully" }
        else
          { success: false, error: "HTTP #{response.code}", body: response.body }
        end
      else
        { success: false, error: "No payment ID available from previous test" }
      end
    end

    # Test 4: POST /payments/confirm - Confirm Payment (expect to fail without Toss data)
    test("POST /payments/confirm - Confirm Payment (expect validation error)") do
      response = make_authenticated_request(:post, '/payments/confirm', {
        orderId: 'test_order_123',
        paymentKey: 'test_payment_key',
        amount: 39000
      })

      # This should fail because it's a test payment key
      if response.code.to_i == 422 || response.code.to_i == 400
        { success: true, message: "Correctly validates payment confirmation" }
      elsif response.code.to_i == 200
        { success: false, error: "Should not accept fake payment confirmation" }
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 5: GET /payments/subscription/status - Get Subscription Status
    test("GET /payments/subscription/status - Get Subscription Status") do
      response = make_authenticated_request(:get, '/payments/subscription/status')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body.key?('has_subscription')
          { success: true, message: "Subscription status retrieved successfully" }
        else
          { success: false, error: "Response missing has_subscription", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 6: POST /payments/subscription/upgrade - Upgrade Subscription
    test("POST /payments/subscription/upgrade - Upgrade Subscription") do
      response = make_authenticated_request(:post, '/payments/subscription/upgrade')

      # Expected to fail if no active subscription
      if response.code.to_i == 422 || response.code.to_i == 200
        { success: true, message: "Upgrade endpoint responding correctly" }
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end
  end

  def test_epic18_exam_schedules
    # Test 1: GET /exam_schedules - Get All Exam Schedules
    test("GET /exam_schedules - Get All Exam Schedules") do
      response = make_request(:get, '/exam_schedules')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['schedules'] || body.is_a?(Array)
          { success: true, message: "Exam schedules retrieved successfully" }
        else
          { success: false, error: "Unexpected response format", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 2: GET /exam_schedules/upcoming - Get Upcoming Exams
    test("GET /exam_schedules/upcoming - Get Upcoming Exams") do
      response = make_request(:get, '/exam_schedules/upcoming')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['upcoming_exams']
          { success: true, message: "Upcoming exams retrieved successfully" }
        else
          { success: false, error: "Response missing upcoming_exams", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 3: GET /exam_schedules/open_registrations - Get Open Registrations
    test("GET /exam_schedules/open_registrations - Get Open Registrations") do
      response = make_request(:get, '/exam_schedules/open_registrations')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['open_registrations']
          { success: true, message: "Open registrations retrieved successfully" }
        else
          { success: false, error: "Response missing open_registrations", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 4: GET /exam_schedules/years - Get Available Years
    test("GET /exam_schedules/years - Get Available Years") do
      response = make_request(:get, '/exam_schedules/years')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['years'] && body['current_year']
          { success: true, message: "Available years retrieved successfully" }
        else
          { success: false, error: "Response missing years/current_year", response: body }
        end
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 5: GET /exam_schedules/:id - Get Specific Exam Schedule (test with ID 1)
    test("GET /exam_schedules/:id - Get Specific Exam Schedule") do
      # Try with ID 1, expect 404 if no data exists
      response = make_request(:get, '/exam_schedules/1')

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['schedule']
          { success: true, message: "Exam schedule retrieved successfully" }
        else
          { success: false, error: "Response missing schedule", response: body }
        end
      elsif response.code.to_i == 404
        { success: true, message: "Correctly returns 404 for non-existent schedule" }
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end

    # Test 6: POST /exam_schedules/:id/register_notification - Register Notification (requires auth)
    test("POST /exam_schedules/:id/register_notification - Register Notification") do
      login_for_exam_schedule_tests if @auth_token.nil?

      response = make_authenticated_request(:post, '/exam_schedules/1/register_notification', {
        notification_type: 'registration_open',
        channel: 'email'
      })

      if response.code.to_i == 200
        body = JSON.parse(response.body)
        if body['success']
          { success: true, message: "Notification registered successfully" }
        else
          { success: false, error: "Response missing success", response: body }
        end
      elsif response.code.to_i == 404
        { success: true, message: "Correctly handles non-existent schedule" }
      elsif response.code.to_i == 422
        { success: true, message: "Correctly validates notification request" }
      else
        { success: false, error: "HTTP #{response.code}", body: response.body }
      end
    end
  end

  def login_for_payment_tests
    return if @auth_token && @current_user

    # Create and login a user for payment tests
    email = "payment_test_#{Time.now.to_i}@example.com"

    # Sign up
    response = make_request(:post, '/signup', {
      user: {
        email: email,
        password: 'Password123!',
        password_confirmation: 'Password123!',
        name: 'Payment Test User'
      }
    })

    if response.code.to_i == 200 || response.code.to_i == 201
      body = JSON.parse(response.body)
      @current_user = body['user']
      @auth_token = body['token']
    end
  end

  def login_for_exam_schedule_tests
    return if @auth_token && @current_user

    # Create and login a user for exam schedule tests
    email = "exam_test_#{Time.now.to_i}@example.com"

    # Sign up
    response = make_request(:post, '/signup', {
      user: {
        email: email,
        password: 'Password123!',
        password_confirmation: 'Password123!',
        name: 'Exam Test User'
      }
    })

    if response.code.to_i == 200 || response.code.to_i == 201
      body = JSON.parse(response.body)
      @current_user = body['user']
      @auth_token = body['token']
    end
  end

  def test(name, &block)
    @results[:total_tests] += 1
    print "Testing: #{name}... "

    begin
      result = block.call

      if result[:success]
        @results[:passed] += 1
        puts "✓ PASSED - #{result[:message]}"
      else
        @results[:failed] += 1
        puts "✗ FAILED"

        bug = {
          test_name: name,
          error: result[:error],
          details: result[:response] || result[:body]
        }
        @results[:bugs] << bug

        puts "  Error: #{result[:error]}"
        puts "  Details: #{result[:response] || result[:body]}" if result[:response] || result[:body]
      end
    rescue StandardError => e
      @results[:failed] += 1
      puts "✗ ERROR - #{e.message}"

      @results[:bugs] << {
        test_name: name,
        error: e.message,
        backtrace: e.backtrace.first(5)
      }
    end
  end

  def make_request(method, path, body = nil)
    uri = URI("#{BASE_URL}#{path}")

    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
              when :get then Net::HTTP::Get.new(uri)
              when :post then Net::HTTP::Post.new(uri)
              when :patch then Net::HTTP::Patch.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              end

    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = body.to_json if body

    http.request(request)
  rescue StandardError => e
    puts "Request failed: #{e.message}"
    raise e
  end

  def make_authenticated_request(method, path, body = nil)
    uri = URI("#{BASE_URL}#{path}")

    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
              when :get then Net::HTTP::Get.new(uri)
              when :post then Net::HTTP::Post.new(uri)
              when :patch then Net::HTTP::Patch.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              end

    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request['Authorization'] = "Bearer #{@auth_token}" if @auth_token
    request.body = body.to_json if body

    http.request(request)
  rescue StandardError => e
    puts "Authenticated request failed: #{e.message}"
    raise e
  end

  def print_summary
    puts "\n" + "=" * 60
    puts "TEST SUMMARY"
    puts "=" * 60
    puts "Total Tests: #{@results[:total_tests]}"
    puts "Passed: #{@results[:passed]} (#{(@results[:passed].to_f / @results[:total_tests] * 100).round(2)}%)"
    puts "Failed: #{@results[:failed]} (#{(@results[:failed].to_f / @results[:total_tests] * 100).round(2)}%)"
    puts "=" * 60

    if @results[:bugs].any?
      puts "\nBUGS FOUND:"
      puts "-" * 60
      @results[:bugs].each_with_index do |bug, index|
        puts "#{index + 1}. #{bug[:test_name]}"
        puts "   Error: #{bug[:error]}"
        puts "   Details: #{bug[:details]}" if bug[:details]
        puts ""
      end
    end

    analyze_and_recommend

    puts "\n" + "=" * 60
    puts "JSON REPORT:"
    puts "=" * 60
    puts JSON.pretty_generate(@results)
  end

  def analyze_and_recommend
    # Analyze bugs and provide recommendations
    if @results[:bugs].any?
      puts "\nRECOMMENDATIONS:"
      puts "-" * 60

      auth_failures = @results[:bugs].select { |b| b[:test_name].include?('Authentication') || b[:test_name].include?('signin') || b[:test_name].include?('signup') }
      payment_failures = @results[:bugs].select { |b| b[:test_name].include?('Payment') }
      exam_failures = @results[:bugs].select { |b| b[:test_name].include?('Exam') }

      if auth_failures.any?
        @results[:recommendations] << "Fix authentication endpoints - #{auth_failures.count} test(s) failed"
        puts "• Fix authentication endpoints (Epic 1)"
        puts "  - Check Devise configuration"
        puts "  - Verify user registration flow"
        puts "  - Ensure JWT token generation"
      end

      if payment_failures.any?
        @results[:recommendations] << "Fix payment integration - #{payment_failures.count} test(s) failed"
        puts "• Fix payment integration (Epic 14)"
        puts "  - Verify TossPaymentService integration"
        puts "  - Check payment model associations"
        puts "  - Ensure proper authentication for payment endpoints"
      end

      if exam_failures.any?
        @results[:recommendations] << "Fix exam schedule endpoints - #{exam_failures.count} test(s) failed"
        puts "• Fix exam schedule endpoints (Epic 18)"
        puts "  - Verify ExamSchedule model and scopes"
        puts "  - Check database seeding for exam schedules"
        puts "  - Ensure notification registration logic"
      end
    else
      puts "\nNo bugs found! All tests passed. 🎉"
    end
  end
end

# Run the tests
tester = EpicTester.new
tester.run_all_tests
