# UpstageClient 테스트
require 'test_helper'

class UpstageClientTest < ActiveSupport::TestCase
  setup do
    # 환경변수 설정
    ENV['UPSTAGE_API_KEY'] = 'test_api_key_12345'
    @client = UpstageClient.new
  end

  teardown do
    ENV['UPSTAGE_API_KEY'] = nil
  end

  test 'client initializes with API key' do
    assert_not_nil @client
  end

  test 'raises error when API key is not configured' do
    ENV['UPSTAGE_API_KEY'] = nil
    assert_raises(UpstageConfigurationError) do
      UpstageClient.new
    end
  end

  test 'configured? returns true when API key is set' do
    assert UpstageClient.configured?
  end

  test 'configured? returns false when API key is not set' do
    ENV['UPSTAGE_API_KEY'] = nil
    refute UpstageClient.configured?
  end

  test 'api_key returns the configured key' do
    assert_equal 'test_api_key_12345', UpstageClient.api_key
  end

  test 'validates file existence' do
    # 존재하지 않는 파일
    assert_raises(UpstageFileNotFoundError) do
      @client.parse_document('/nonexistent/file.pdf')
    end
  end

  test 'validates PDF file extension' do
    # 임시 파일 생성
    test_file = Tempfile.new('test.txt')
    begin
      assert_raises(UpstageInvalidFileError) do
        @client.parse_document(test_file.path)
      end
    ensure
      test_file.close
      test_file.unlink
    end
  end

  test 'raises error for invalid file type' do
    assert_raises(UpstageInvalidFileError) do
      @client.parse_document(123)  # Integer instead of file
    end
  end

  test 'batch_parse handles multiple files' do
    # 실제 API 호출 대신 mock을 사용해야 함
    # 이는 VCR 같은 라이브러리와 함께 사용
    skip('Requires mock/stub setup')
  end
end
