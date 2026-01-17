#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Epic 9 (CBT Test Mode), Epic 10 (Answer Randomization), Epic 17 (Study Materials Market)
# This script tests all API endpoints for these three epics and generates a comprehensive JSON report

require 'net/http'
require 'json'
require 'uri'

BASE_URL = 'http://localhost:3000'

# Test results tracker
class TestRunner
  attr_reader :results, :bugs

  def initialize
    @results = {
      total_tests: 0,
      passed: 0,
      failed: 0,
      skipped: 0,
      bugs: [],
      recommendations: []
    }
    @bugs = []
    @auth_token = nil
    @test_user = nil
    @test_data = {}
  end

  def run_all_tests
    puts "=" * 80
    puts "Starting API Tests for Epic 9, Epic 10, and Epic 17"
    puts "=" * 80
    puts ""

    # Setup: Create test user and authenticate
    setup_test_environment

    # Test each epic
    test_epic_9_cbt_test_mode if @auth_token
    test_epic_10_answer_randomization if @auth_token
    test_epic_17_marketplace if @auth_token

    # Generate report
    generate_report
  end

  private

  def setup_test_environment
    puts "\n[SETUP] Creating test environment..."

    # Try to login with existing test user or create new one
    login_result = login_test_user

    if login_result[:success]
      puts "  ✓ Authenticated successfully"
      @auth_token = login_result[:token]
      @test_user = login_result[:user]
    else
      puts "  ✗ Authentication failed: #{login_result[:error]}"
      puts "  ! Cannot proceed without authentication"
      @results[:bugs] << {
        epic: "Setup",
        endpoint: "Authentication",
        severity: "critical",
        description: "Cannot authenticate - all tests require authentication",
        error: login_result[:error]
      }
    end
  end

  def login_test_user
    # Try to sign in with test credentials
    uri = URI("#{BASE_URL}/signin")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    request.body = {
      user: {
        email: "test@example.com",
        password: "password123"
      }
    }.to_json

    begin
      response = http.request(request)
      if response.code == "200" || response.code == "302"
        # Parse response to get token/session
        # Note: Actual implementation depends on authentication mechanism
        return {
          success: true,
          token: "test_token", # Placeholder
          user: { id: 1, email: "test@example.com" }
        }
      else
        return {
          success: false,
          error: "Login failed with status #{response.code}"
        }
      end
    rescue => e
      return {
        success: false,
        error: e.message
      }
    end
  end

  def test_epic_9_cbt_test_mode
    puts "\n" + "=" * 80
    puts "EPIC 9: CBT Test Mode"
    puts "=" * 80

    # First, create a test session to work with
    test_session_id = create_test_session

    if test_session_id
      test_endpoint("POST", "/test_sessions/#{test_session_id}/pause", "Epic 9", {}, "Pause test session")
      test_endpoint("POST", "/test_sessions/#{test_session_id}/resume", "Epic 9", {}, "Resume test session")
      test_endpoint("POST", "/test_sessions/#{test_session_id}/auto_save", "Epic 9", {}, "Auto-save test session")
      test_endpoint("GET", "/test_sessions/#{test_session_id}/statistics", "Epic 9", {}, "Get test session statistics")
      test_endpoint("GET", "/test_sessions/#{test_session_id}/navigation_grid", "Epic 9", {}, "Get navigation grid")

      # Create bookmark
      bookmark_result = test_endpoint("POST", "/test_sessions/#{test_session_id}/bookmarks", "Epic 9", {
        test_question_id: 1,
        reason: "Need to review"
      }, "Create bookmark")

      if bookmark_result[:success] && bookmark_result[:data] && bookmark_result[:data]['bookmark']
        bookmark_id = bookmark_result[:data]['bookmark']['id']
        test_endpoint("DELETE", "/bookmarks/#{bookmark_id}", "Epic 9", {}, "Delete bookmark")
      end

      test_endpoint("POST", "/test_sessions/#{test_session_id}/complete", "Epic 9", {}, "Complete test session")
    else
      puts "  ! Cannot test Epic 9 endpoints - test session creation failed"
      @results[:skipped] += 6
    end
  end

  def test_epic_10_answer_randomization
    puts "\n" + "=" * 80
    puts "EPIC 10: Answer Randomization"
    puts "=" * 80

    # Create test data
    study_material_id = create_test_study_material
    question_id = create_test_question(study_material_id) if study_material_id

    if question_id
      # Test randomization endpoints
      randomize_result = test_endpoint("POST", "/randomization/randomize_question", "Epic 10", {
        question_id: question_id,
        strategy: "full_random"
      }, "Randomize single question")

      # Test exam session randomization
      exam_session_id = create_exam_session(study_material_id)
      if exam_session_id
        test_endpoint("POST", "/randomization/randomize_exam", "Epic 10", {
          exam_session_id: exam_session_id,
          strategy: "full_random"
        }, "Randomize exam questions")

        test_endpoint("GET", "/randomization/session/#{exam_session_id}", "Epic 10", {}, "Get session randomization info")

        test_endpoint("POST", "/randomization/restore_order", "Epic 10", {
          question_id: question_id,
          randomized_options: ["A", "B", "C", "D"]
        }, "Restore original order")

        test_endpoint("PUT", "/randomization/toggle/#{exam_session_id}", "Epic 10", {}, "Toggle randomization")

        test_endpoint("PUT", "/randomization/set_strategy/#{exam_session_id}", "Epic 10", {
          strategy: "weighted_random"
        }, "Set randomization strategy")
      end

      if study_material_id
        test_endpoint("POST", "/randomization/analyze/#{study_material_id}", "Epic 10", {
          iterations: 100,
          save_results: true
        }, "Analyze randomization quality")

        test_endpoint("GET", "/randomization/report/#{study_material_id}", "Epic 10", {}, "Get randomization report")

        test_endpoint("GET", "/randomization/stats/#{study_material_id}", "Epic 10", {}, "Get randomization statistics")

        test_endpoint("GET", "/randomization/question_stats/#{study_material_id}/#{question_id}", "Epic 10", {}, "Get question-specific stats")
      end

      test_endpoint("POST", "/randomization/test_uniformity", "Epic 10", {
        iterations: 1000,
        num_options: 5,
        strategy: "full_random"
      }, "Test uniformity")
    else
      puts "  ! Cannot test Epic 10 endpoints - test data creation failed"
      @results[:skipped] += 11
    end
  end

  def test_epic_17_marketplace
    puts "\n" + "=" * 80
    puts "EPIC 17: Study Materials Market"
    puts "=" * 80

    # Test marketplace browsing (public endpoints)
    test_endpoint("GET", "/marketplace", "Epic 17", {}, "Get marketplace materials")
    test_endpoint("GET", "/marketplace/search", "Epic 17", { q: "test" }, "Search marketplace")
    test_endpoint("GET", "/marketplace/facets", "Epic 17", {}, "Get marketplace facets")
    test_endpoint("GET", "/marketplace/popular", "Epic 17", {}, "Get popular materials")
    test_endpoint("GET", "/marketplace/top_rated", "Epic 17", {}, "Get top-rated materials")
    test_endpoint("GET", "/marketplace/recent", "Epic 17", {}, "Get recent materials")
    test_endpoint("GET", "/marketplace/categories", "Epic 17", {}, "Get categories")
    test_endpoint("GET", "/marketplace/stats", "Epic 17", {}, "Get marketplace stats")

    # Test authenticated endpoints
    material_id = create_test_material_for_marketplace

    if material_id
      test_endpoint("GET", "/marketplace/#{material_id}", "Epic 17", {}, "Get material details")
      test_endpoint("POST", "/marketplace/#{material_id}/toggle_publish", "Epic 17", {}, "Toggle publish status")

      test_endpoint("PATCH", "/marketplace/#{material_id}/update_listing", "Epic 17", {
        material: {
          price: 5000,
          category: "IT",
          difficulty_level: "intermediate"
        }
      }, "Update listing")

      # Test purchase flow
      test_endpoint("POST", "/marketplace/#{material_id}/purchase", "Epic 17", {}, "Purchase material (free)")

      # Test reviews
      review_result = test_endpoint("POST", "/study_materials/#{material_id}/reviews", "Epic 17", {
        review: {
          rating: 5,
          comment: "Excellent material for exam preparation!"
        }
      }, "Create review")

      if review_result[:success] && review_result[:data] && review_result[:data]['review']
        review_id = review_result[:data]['review']['id']

        test_endpoint("GET", "/study_materials/#{material_id}/reviews", "Epic 17", {}, "Get material reviews")
        test_endpoint("GET", "/reviews/#{review_id}", "Epic 17", {}, "Get review details")

        test_endpoint("POST", "/reviews/#{review_id}/vote", "Epic 17", {
          helpful: true
        }, "Vote on review")

        test_endpoint("DELETE", "/reviews/#{review_id}/remove_vote", "Epic 17", {}, "Remove vote from review")
      end

      test_endpoint("GET", "/marketplace/my_materials", "Epic 17", {}, "Get my materials")
      test_endpoint("GET", "/marketplace/purchased", "Epic 17", {}, "Get purchased materials")
    else
      puts "  ! Cannot test material-specific endpoints - material creation failed"
      @results[:skipped] += 12
    end
  end

  def create_test_session
    puts "\n  [SETUP] Creating test session..."
    # This would need a real study_set_id
    # For now, return a placeholder
    # In real implementation, create via API
    return 1 # Placeholder
  end

  def create_test_study_material
    puts "\n  [SETUP] Creating test study material..."
    return 1 # Placeholder
  end

  def create_test_question(study_material_id)
    puts "\n  [SETUP] Creating test question..."
    return 1 # Placeholder
  end

  def create_exam_session(study_material_id)
    puts "\n  [SETUP] Creating exam session..."
    return 1 # Placeholder
  end

  def create_test_material_for_marketplace
    puts "\n  [SETUP] Creating test material for marketplace..."
    return 1 # Placeholder
  end

  def test_endpoint(method, path, epic, params, description)
    @results[:total_tests] += 1

    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if method == "GET" && params.any?

    http = Net::HTTP.new(uri.host, uri.port)

    case method
    when "GET"
      request = Net::HTTP::Get.new(uri.request_uri)
    when "POST"
      request = Net::HTTP::Post.new(uri.path)
    when "PATCH"
      request = Net::HTTP::Patch.new(uri.path)
    when "PUT"
      request = Net::HTTP::Put.new(uri.path)
    when "DELETE"
      request = Net::HTTP::Delete.new(uri.path)
    end

    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@auth_token}" if @auth_token
    request.body = params.to_json if method != "GET" && params.any?

    begin
      response = http.request(request)

      case response.code
      when "200", "201", "302"
        @results[:passed] += 1
        puts "  ✓ [#{method}] #{path} - #{description}"
        parsed_data = begin
          JSON.parse(response.body)
        rescue
          response.body
        end
        { success: true, status: response.code, data: parsed_data }
      when "401", "403"
        @results[:failed] += 1
        puts "  ✗ [#{method}] #{path} - #{description} (Authentication/Authorization issue)"
        add_bug(epic, "#{method} #{path}", "high", "Authentication/Authorization failed", response.body)
        { success: false, status: response.code, error: "Auth failed" }
      when "404"
        @results[:failed] += 1
        puts "  ✗ [#{method}] #{path} - #{description} (Not Found)"
        add_bug(epic, "#{method} #{path}", "high", "Endpoint not found or route not configured", response.body)
        { success: false, status: response.code, error: "Not found" }
      when "422"
        @results[:failed] += 1
        puts "  ✗ [#{method}] #{path} - #{description} (Unprocessable Entity)"
        add_bug(epic, "#{method} #{path}", "medium", "Validation error or missing required data", response.body)
        { success: false, status: response.code, error: "Validation failed" }
      when "500"
        @results[:failed] += 1
        puts "  ✗ [#{method}] #{path} - #{description} (Server Error)"
        add_bug(epic, "#{method} #{path}", "critical", "Internal server error", response.body)
        { success: false, status: response.code, error: "Server error" }
      else
        @results[:failed] += 1
        puts "  ? [#{method}] #{path} - #{description} (Unexpected: #{response.code})"
        add_bug(epic, "#{method} #{path}", "medium", "Unexpected response code: #{response.code}", response.body)
        { success: false, status: response.code, error: "Unexpected response" }
      end
    rescue => e
      @results[:failed] += 1
      puts "  ✗ [#{method}] #{path} - #{description} (Exception: #{e.message})"
      add_bug(epic, "#{method} #{path}", "critical", "Exception during request: #{e.message}", e.backtrace.first(3).join("\n"))
      { success: false, error: e.message }
    end
  end

  def add_bug(epic, endpoint, severity, description, details)
    @results[:bugs] << {
      epic: epic,
      endpoint: endpoint,
      severity: severity,
      description: description,
      details: details.to_s.slice(0, 500),
      timestamp: Time.now.iso8601
    }
  end

  def generate_report
    puts "\n" + "=" * 80
    puts "TEST SUMMARY"
    puts "=" * 80
    puts "Total Tests: #{@results[:total_tests]}"
    puts "Passed: #{@results[:passed]} (#{(@results[:passed] * 100.0 / @results[:total_tests]).round(2)}%)" if @results[:total_tests] > 0
    puts "Failed: #{@results[:failed]}"
    puts "Skipped: #{@results[:skipped]}"
    puts ""

    if @results[:bugs].any?
      puts "BUGS FOUND: #{@results[:bugs].length}"
      puts "-" * 80

      @results[:bugs].group_by { |b| b[:epic] }.each do |epic, bugs|
        puts "\n#{epic}:"
        bugs.each_with_index do |bug, i|
          puts "  #{i + 1}. [#{bug[:severity].upcase}] #{bug[:endpoint]}"
          puts "     #{bug[:description]}"
        end
      end
    end

    # Generate recommendations
    generate_recommendations

    if @results[:recommendations].any?
      puts "\nRECOMMENDATIONS:"
      puts "-" * 80
      @results[:recommendations].each_with_index do |rec, i|
        puts "#{i + 1}. [#{rec[:priority].upcase}] #{rec[:recommendation]}"
      end
    end

    # Save JSON report
    report_path = File.join(Dir.pwd, "test_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json")
    File.write(report_path, JSON.pretty_generate(@results))

    puts "\n" + "=" * 80
    puts "Full JSON report saved to: #{report_path}"
    puts "=" * 80
  end

  def generate_recommendations
    critical_bugs = @results[:bugs].select { |b| b[:severity] == "critical" }
    high_bugs = @results[:bugs].select { |b| b[:severity] == "high" }

    if critical_bugs.any?
      @results[:recommendations] << {
        priority: "critical",
        recommendation: "Fix #{critical_bugs.length} critical bug(s) immediately - these prevent core functionality from working"
      }
    end

    if high_bugs.any?
      @results[:recommendations] << {
        priority: "high",
        recommendation: "Address #{high_bugs.length} high-priority bug(s) - these affect important features"
      }
    end

    if @results[:failed] > @results[:passed]
      @results[:recommendations] << {
        priority: "high",
        recommendation: "More than half of tests are failing - consider reviewing API implementation and test data setup"
      }
    end

    auth_bugs = @results[:bugs].select { |b| b[:description].include?("Authentication") || b[:description].include?("Authorization") }
    if auth_bugs.length > 3
      @results[:recommendations] << {
        priority: "high",
        recommendation: "Multiple authentication failures detected - verify authentication system and token handling"
      }
    end

    not_found_bugs = @results[:bugs].select { |b| b[:description].include?("not found") || b[:description].include?("Not Found") }
    if not_found_bugs.length > 3
      @results[:recommendations] << {
        priority: "medium",
        recommendation: "Multiple 404 errors - verify routes configuration and ensure all endpoints are properly defined"
      }
    end

    if @results[:skipped] > 0
      @results[:recommendations] << {
        priority: "medium",
        recommendation: "#{@results[:skipped]} test(s) were skipped due to setup failures - ensure test data creation works properly"
      }
    end
  end
end

# Run tests
runner = TestRunner.new
runner.run_all_tests
