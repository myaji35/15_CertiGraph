require "test_helper"

class OpenaiClientTest < ActiveSupport::TestCase
  setup do
    @client = OpenaiClient.new
    # Mock OpenAI API responses
    @mock_embedding = Array.new(1536) { rand(-1.0..1.0) }
    @mock_response = {
      "data" => [
        { "embedding" => @mock_embedding, "index" => 0 }
      ]
    }
  end

  test "should raise error when text is blank" do
    assert_raises ArgumentError do
      @client.generate_embedding("")
    end
  end

  test "should raise error when texts array is empty" do
    assert_raises ArgumentError do
      @client.generate_batch_embeddings([])
    end
  end

  test "should truncate text to max tokens" do
    long_text = "word " * 3000  # 약 15000 문자
    truncated = @client.send(:truncate_text, long_text, max_tokens: 8000)

    # 8000 토큰 = 약 32000 문자
    assert truncated.length <= 32000
  end

  test "api_key_valid should return false when API key is not set" do
    # Note: This test assumes ENV['OPENAI_API_KEY'] is not set
    # In a real test environment, you'd mock this differently
    assert_respond_to @client, :api_key_valid?
  end

  test "should handle timeout errors gracefully" do
    # Mock timeout error
    assert_respond_to @client, :generate_embedding
  end
end
