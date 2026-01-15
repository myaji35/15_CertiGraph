require "test_helper"

class EmbeddingServiceTest < ActiveSupport::TestCase
  setup do
    @service = EmbeddingService.new
    @user = User.create!(email: 'test@test.com', password: 'password')
    @study_set = @user.study_sets.create!(title: 'Test Set')
    @study_material = @study_set.study_materials.create!(
      name: 'Test Material',
      extracted_data: {
        text: 'Test document content',
        questions: [
          { content: 'Test question 1', options: ['Option 1', 'Option 2'] }
        ]
      }
    )
  end

  test "should estimate token count correctly" do
    text = "This is a test sentence with some words."
    # 대략 1 토큰 = 4 문자
    estimated = @service.send(:estimate_token_count, text)
    assert_equal (text.length / 4.0).ceil, estimated
  end

  test "should prepare question text correctly" do
    question = @study_material.questions.create!(
      content: 'What is OOP?',
      options: { '①' => 'Object Oriented Programming', '②' => 'Something else' },
      answer: '①'
    )

    text = @service.send(:prepare_question_text, question)

    assert_includes text, 'What is OOP?'
    assert_includes text, 'Object Oriented Programming'
  end

  test "should calculate magnitude correctly" do
    vector = [3, 4]  # Should have magnitude 5
    magnitude = @service.send(:calculate_magnitude, vector)
    assert_equal 5.0, magnitude
  end

  test "should calculate magnitude for empty vector" do
    magnitude = @service.send(:calculate_magnitude, [])
    assert_equal 1.0, magnitude
  end

  test "should extract text from study material" do
    text = @service.send(:extract_text_from_study_material, @study_material)
    assert text.present?
    assert_includes text, 'Test document content'
  end

  test "should create document chunks" do
    chunks = @service.send(:create_document_chunks, @study_material)
    assert chunks.present?
    assert chunks.all? { |c| c.persisted? }
  end

  test "should return empty array for blank study material" do
    chunks = @service.send(:create_document_chunks, nil)
    assert_equal [], chunks
  end
end
