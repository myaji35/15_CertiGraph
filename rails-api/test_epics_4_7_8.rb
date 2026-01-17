#!/usr/bin/env ruby
# Test script for Epic 4 (Question Extraction), Epic 7 (Concept Extraction), Epic 8 (Prerequisite Mapping)

require 'net/http'
require 'json'
require 'uri'

class EpicTester
  BASE_URL = 'http://localhost:3000'

  attr_reader :results, :test_count, :passed_count, :failed_count, :bugs

  def initialize
    @results = []
    @test_count = 0
    @passed_count = 0
    @failed_count = 0
    @bugs = []
    @recommendations = []
    @user_token = nil
    @study_material_id = nil
    @question_id = nil
    @concept_id = nil
    @node_id = nil
    @learning_path_id = nil
  end

  def run_all_tests
    puts "=" * 80
    puts "Testing Epic 4 (Question Extraction), Epic 7 (Concept Extraction), Epic 8 (Prerequisite Mapping)"
    puts "=" * 80
    puts ""

    # Setup: Login and create test data
    setup_test_data

    # Epic 4: Question Extraction Tests
    puts "\n" + "=" * 80
    puts "EPIC 4: QUESTION EXTRACTION TESTS"
    puts "=" * 80
    test_epic_4_questions

    # Epic 7: Concept Extraction Tests
    puts "\n" + "=" * 80
    puts "EPIC 7: CONCEPT EXTRACTION TESTS"
    puts "=" * 80
    test_epic_7_concepts

    # Epic 8: Prerequisite Mapping Tests
    puts "\n" + "=" * 80
    puts "EPIC 8: PREREQUISITE MAPPING TESTS"
    puts "=" * 80
    test_epic_8_prerequisites

    # Generate final report
    generate_report
  end

  private

  def setup_test_data
    puts "\n--- Setting up test data ---"

    # Try to login or create a test user
    response = post('/api/v1/auth/register', {
      email: "test_#{Time.now.to_i}@example.com",
      password: "password123",
      password_confirmation: "password123"
    })

    if response.code == "201" || response.code == "200"
      data = JSON.parse(response.body)
      @user_token = data['token'] || data['jwt']
      puts "✓ User created and authenticated"
    else
      # Try to login with existing test user
      response = post('/api/v1/auth/login', {
        email: "test@example.com",
        password: "password123"
      })

      if response.code == "200"
        data = JSON.parse(response.body)
        @user_token = data['token'] || data['jwt']
        puts "✓ Logged in with existing user"
      else
        puts "✗ Failed to authenticate - tests may fail"
      end
    end

    # Find or create a study material
    response = get('/api/v1/study_sets')
    if response.code == "200"
      data = JSON.parse(response.body)
      study_sets = data['study_sets'] || data['data'] || []

      if study_sets.any?
        @study_material_id = study_sets.first['id']
        puts "✓ Using existing study material ID: #{@study_material_id}"
      end
    end

    # If no study material, we'll need to create one
    unless @study_material_id
      puts "✗ No study materials found - some tests may be skipped"
    end
  end

  # ============================================================================
  # EPIC 4: QUESTION EXTRACTION TESTS
  # ============================================================================

  def test_epic_4_questions
    # Note: Routes are nested under study_materials
    # Based on routes.rb: resources :study_materials do resources :questions

    # Test 1: Extract questions from markdown
    test_extract_questions

    # Test 2: Get question by ID
    test_get_question

    # Test 3: Update question
    test_update_question

    # Test 4: Validate question
    test_validate_question

    # Test 5: Get questions by material
    test_get_questions_by_material

    # Test 6: Delete question (last to avoid breaking other tests)
    # test_delete_question # Commenting out to preserve test data
  end

  def test_extract_questions
    return skip_test("Extract questions", "No study material ID") unless @study_material_id

    test_name = "POST /study_materials/:id/questions/extract"

    # Sample markdown content for extraction
    markdown = <<~MARKDOWN
      # 문제 1
      다음 중 OSI 7계층 모델에서 전송 계층(Transport Layer)의 역할은?

      1. 물리적 연결 관리
      2. 데이터 암호화
      3. 종단 간 신뢰성 있는 데이터 전송
      4. 라우팅

      정답: 3
      해설: 전송 계층은 종단 간 신뢰성 있는 데이터 전송을 담당합니다.
    MARKDOWN

    response = post("/study_materials/#{@study_material_id}/questions/extract", {
      markdown_content: markdown
    })

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['success'] && data['questions']
        @question_id = data['questions'].first['id'] if data['questions'].any?
        pass_test(test_name, "Extracted #{data['questions'].size} questions")
      else
        fail_test(test_name, "Unexpected response structure: #{data}")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_get_question
    return skip_test("GET /questions/:id", "No question ID") unless @question_id

    test_name = "GET /questions/:id"

    response = get("/questions/#{@question_id}")

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['id'] || data['question']
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_update_question
    return skip_test("PUT /questions/:id", "No question ID") unless @question_id

    test_name = "PUT /questions/:id"

    response = put("/questions/#{@question_id}", {
      question: {
        explanation: "Updated explanation for testing"
      }
    })

    if response.code == "200"
      pass_test(test_name)
    elsif response.code == "404"
      fail_test(test_name, "Question not found - route may not be implemented")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_validate_question
    return skip_test("POST /questions/:id/validate", "No question ID") unless @question_id

    test_name = "POST /questions/:id/validate"

    response = post("/questions/#{@question_id}/validate", {})

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['success'] != nil || data['validation_status']
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    elsif response.code == "404"
      fail_test(test_name, "Route not found - may not be implemented")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_get_questions_by_material
    return skip_test("GET /study_materials/:id/questions", "No study material ID") unless @study_material_id

    test_name = "GET /study_materials/:material_id/questions"

    response = get("/study_materials/#{@study_material_id}/questions")

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['questions'] || data.is_a?(Array)
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  # ============================================================================
  # EPIC 7: CONCEPT EXTRACTION TESTS
  # ============================================================================

  def test_epic_7_concepts
    # API routes: /api/v1/study_materials/:id/concepts

    # Test 1: Extract concepts
    test_extract_concepts

    # Test 2: Get concept by ID
    test_get_concept

    # Test 3: Update concept
    test_update_concept

    # Test 4: Get concepts hierarchy
    test_concepts_hierarchy

    # Test 5: Cluster concepts
    test_cluster_concepts

    # Test 6: Merge concepts (skipping to avoid data corruption)
    # test_merge_concepts
  end

  def test_extract_concepts
    return skip_test("POST /api/v1/study_materials/:id/concepts/extract_all", "No study material ID") unless @study_material_id

    test_name = "POST /api/v1/study_materials/:id/concepts/extract_all"

    response = post("/api/v1/study_materials/#{@study_material_id}/concepts/extract_all", {})

    if response.code == "200" || response.code == "202"
      data = JSON.parse(response.body)
      if data['result'] || data['message']
        pass_test(test_name, data['message'] || "Concepts extracted")
      else
        fail_test(test_name, "Unexpected response structure")
      end
    elsif response.code == "404"
      fail_test(test_name, "Study material not found")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_get_concept
    return skip_test("GET /api/v1/concepts/:id", "No study material ID") unless @study_material_id

    # First, get list of concepts
    response = get("/api/v1/study_materials/#{@study_material_id}/concepts")

    if response.code == "200"
      data = JSON.parse(response.body)
      concepts = data['concepts'] || []

      if concepts.any?
        @concept_id = concepts.first['id']

        # Now test getting individual concept
        test_name = "GET /api/v1/concepts/:id"
        response = get("/api/v1/concepts/#{@concept_id}")

        if response.code == "200"
          concept_data = JSON.parse(response.body)
          if concept_data['concept'] || concept_data['id']
            pass_test(test_name)
          else
            fail_test(test_name, "Unexpected response structure")
          end
        else
          fail_test(test_name, "HTTP #{response.code}: #{response.body}")
        end
      else
        skip_test("GET /api/v1/concepts/:id", "No concepts found")
      end
    else
      skip_test("GET /api/v1/concepts/:id", "Could not fetch concepts list")
    end
  rescue => e
    fail_test("GET /api/v1/concepts/:id", "Exception: #{e.message}")
  end

  def test_update_concept
    return skip_test("PATCH /api/v1/concepts/:id", "No concept ID") unless @concept_id

    test_name = "PATCH /api/v1/concepts/:id"

    response = patch("/api/v1/concepts/#{@concept_id}", {
      concept: {
        description: "Updated concept description for testing"
      }
    })

    if response.code == "200"
      pass_test(test_name)
    elsif response.code == "404"
      fail_test(test_name, "Concept not found")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_concepts_hierarchy
    return skip_test("GET /api/v1/study_materials/:id/concepts/hierarchy", "No study material ID") unless @study_material_id

    test_name = "GET /api/v1/study_materials/:id/concepts/hierarchy"

    response = get("/api/v1/study_materials/#{@study_material_id}/concepts/hierarchy")

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['hierarchy'] != nil
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_cluster_concepts
    return skip_test("GET /api/v1/study_materials/:id/concepts/cluster", "No study material ID") unless @study_material_id

    test_name = "GET /api/v1/study_materials/:id/concepts/cluster"

    response = get("/api/v1/study_materials/#{@study_material_id}/concepts/cluster?type=similarity&threshold=0.7")

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['clusters'] != nil
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  # ============================================================================
  # EPIC 8: PREREQUISITE MAPPING TESTS
  # ============================================================================

  def test_epic_8_prerequisites
    # API routes: /api/v1/study_materials/:id/prerequisites

    # First, ensure we have a node_id
    get_or_create_node_id

    # Test 1: Analyze prerequisites
    test_analyze_prerequisites

    # Test 2: Get prerequisites for a node
    test_get_node_prerequisites

    # Test 3: Create prerequisite relationship
    test_create_prerequisite

    # Test 4: Get learning path
    test_generate_learning_paths

    # Test 5: Get learning path by ID
    test_get_learning_path
  end

  def get_or_create_node_id
    return if @node_id
    return unless @study_material_id

    # Try to get concepts/nodes
    response = get("/api/v1/study_materials/#{@study_material_id}/concepts")

    if response.code == "200"
      data = JSON.parse(response.body)
      concepts = data['concepts'] || []

      if concepts.any?
        @node_id = concepts.first['id']
        puts "  Using node ID: #{@node_id}"
      else
        puts "  ✗ No nodes found for prerequisite tests"
      end
    end
  end

  def test_analyze_prerequisites
    return skip_test("POST /api/v1/study_materials/:id/prerequisites/analyze_all", "No study material ID") unless @study_material_id

    test_name = "POST /api/v1/study_materials/:id/prerequisites/analyze_all"

    response = post("/api/v1/study_materials/#{@study_material_id}/prerequisites/analyze_all", {})

    if response.code == "200" || response.code == "202"
      data = JSON.parse(response.body)
      if data['message'] || data['results']
        pass_test(test_name, data['message'] || "Prerequisites analyzed")
      else
        fail_test(test_name, "Unexpected response structure")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_get_node_prerequisites
    return skip_test("GET /api/v1/study_materials/:id/nodes/:node_id/prerequisites", "No node ID") unless @node_id && @study_material_id

    test_name = "GET /api/v1/study_materials/:id/prerequisites/nodes/:node_id/prerequisites"

    response = get("/api/v1/study_materials/#{@study_material_id}/prerequisites/nodes/#{@node_id}/prerequisites")

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['direct_prerequisites'] || data['node']
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    elsif response.code == "404"
      fail_test(test_name, "Node not found or route not implemented")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_create_prerequisite
    return skip_test("POST /api/v1/study_materials/:id/prerequisites/paths", "No node ID") unless @node_id && @study_material_id

    test_name = "POST /api/v1/study_materials/:id/prerequisites/paths"

    response = post("/api/v1/study_materials/#{@study_material_id}/prerequisites/paths", {
      path: {
        target_node_id: @node_id,
        path_type: 'shortest',
        path_name: 'Test Learning Path'
      }
    })

    if response.code == "201" || response.code == "200"
      data = JSON.parse(response.body)
      if data['path'] && data['path']['id']
        @learning_path_id = data['path']['id']
        pass_test(test_name, "Created learning path ID: #{@learning_path_id}")
      else
        fail_test(test_name, "Path created but no ID returned")
      end
    elsif response.code == "422"
      fail_test(test_name, "Could not generate path - may need more concepts/prerequisites")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_generate_learning_paths
    return skip_test("GET /api/v1/study_materials/:id/prerequisites/nodes/:node_id/generate_paths", "No node ID") unless @node_id && @study_material_id

    test_name = "POST /api/v1/study_materials/:id/prerequisites/nodes/:node_id/generate_paths"

    response = post("/api/v1/study_materials/#{@study_material_id}/prerequisites/nodes/#{@node_id}/generate_paths", {})

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['paths'] || data['target_node']
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    elsif response.code == "404"
      fail_test(test_name, "Route not implemented or node not found")
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  def test_get_learning_path
    return skip_test("GET /api/v1/learning_paths/:id", "No learning path ID") unless @learning_path_id

    test_name = "GET /api/v1/learning_paths/:id"

    response = get("/api/v1/learning_paths/#{@learning_path_id}")

    if response.code == "200"
      data = JSON.parse(response.body)
      if data['path'] || data['id']
        pass_test(test_name)
      else
        fail_test(test_name, "Unexpected response structure")
      end
    else
      fail_test(test_name, "HTTP #{response.code}: #{response.body}")
    end
  rescue => e
    fail_test(test_name, "Exception: #{e.message}")
  end

  # ============================================================================
  # HTTP HELPERS
  # ============================================================================

  def get(path)
    uri = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    add_auth_header(request)
    http.request(request)
  end

  def post(path, data)
    uri = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    add_auth_header(request)
    request.body = data.to_json
    http.request(request)
  end

  def put(path, data)
    uri = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    add_auth_header(request)
    request.body = data.to_json
    http.request(request)
  end

  def patch(path, data)
    uri = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Patch.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    add_auth_header(request)
    request.body = data.to_json
    http.request(request)
  end

  def delete(path)
    uri = URI.parse("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Delete.new(uri.request_uri)
    add_auth_header(request)
    http.request(request)
  end

  def add_auth_header(request)
    request['Authorization'] = "Bearer #{@user_token}" if @user_token
  end

  # ============================================================================
  # TEST RESULT TRACKING
  # ============================================================================

  def pass_test(name, message = nil)
    @test_count += 1
    @passed_count += 1
    @results << { test: name, status: 'PASS', message: message }
    puts "✓ PASS: #{name}"
    puts "        #{message}" if message
  end

  def fail_test(name, reason)
    @test_count += 1
    @failed_count += 1
    @results << { test: name, status: 'FAIL', message: reason }
    @bugs << { test: name, issue: reason, severity: 'high' }
    puts "✗ FAIL: #{name}"
    puts "        #{reason}"
  end

  def skip_test(name, reason)
    @results << { test: name, status: 'SKIP', message: reason }
    puts "⊘ SKIP: #{name} (#{reason})"
  end

  def generate_report
    puts "\n" + "=" * 80
    puts "TEST SUMMARY"
    puts "=" * 80

    puts "\nTotal Tests: #{@test_count}"
    puts "Passed: #{@passed_count} (#{(@passed_count.to_f / @test_count * 100).round(1)}%)" if @test_count > 0
    puts "Failed: #{@failed_count} (#{(@failed_count.to_f / @test_count * 100).round(1)}%)" if @test_count > 0

    if @bugs.any?
      puts "\n" + "-" * 80
      puts "BUGS FOUND (#{@bugs.size})"
      puts "-" * 80
      @bugs.each_with_index do |bug, i|
        puts "\n#{i + 1}. Test: #{bug[:test]}"
        puts "   Issue: #{bug[:issue]}"
        puts "   Severity: #{bug[:severity]}"
      end
    end

    # Recommendations
    @recommendations << "Ensure all study materials have questions before testing question extraction"
    @recommendations << "Verify authentication middleware is properly configured for API routes"
    @recommendations << "Add more comprehensive error messages for failed validations"
    @recommendations << "Consider implementing batch operations for better performance"
    @recommendations << "Add rate limiting to prevent abuse of AI-powered endpoints"

    puts "\n" + "-" * 80
    puts "RECOMMENDATIONS"
    puts "-" * 80
    @recommendations.each_with_index do |rec, i|
      puts "#{i + 1}. #{rec}"
    end

    # JSON Report
    report = {
      total_tests: @test_count,
      passed: @passed_count,
      failed: @failed_count,
      pass_rate: @test_count > 0 ? (@passed_count.to_f / @test_count * 100).round(2) : 0,
      bugs: @bugs,
      recommendations: @recommendations,
      detailed_results: @results
    }

    puts "\n" + "=" * 80
    puts "JSON REPORT"
    puts "=" * 80
    puts JSON.pretty_generate(report)

    # Save to file
    File.write('/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/test_report_epics_4_7_8.json', JSON.pretty_generate(report))
    puts "\n✓ Report saved to: test_report_epics_4_7_8.json"
  end
end

# Run the tests
tester = EpicTester.new
tester.run_all_tests
