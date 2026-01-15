require "test_helper"

class DocumentChunkTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: 'test@test.com', password: 'password')
    @study_set = @user.study_sets.create!(title: 'Test Set')
    @study_material = @study_set.study_materials.create!(name: 'Test Material')
  end

  test "should create a valid document chunk" do
    chunk = @study_material.document_chunks.build(
      content: "Test content",
      token_count: 10,
      chunk_index: 0,
      start_position: 0,
      end_position: 100
    )

    assert chunk.valid?
    assert chunk.save
  end

  test "should require content, token_count, chunk_index, start_position, end_position" do
    chunk = @study_material.document_chunks.build

    assert_not chunk.valid?
    assert chunk.errors[:content].present?
    assert chunk.errors[:token_count].present?
    assert chunk.errors[:chunk_index].present?
    assert chunk.errors[:start_position].present?
    assert chunk.errors[:end_position].present?
  end

  test "should enforce unique chunk_index per study_material" do
    @study_material.document_chunks.create!(
      content: "First chunk",
      token_count: 10,
      chunk_index: 0,
      start_position: 0,
      end_position: 100
    )

    duplicate_chunk = @study_material.document_chunks.build(
      content: "Second chunk",
      token_count: 10,
      chunk_index: 0,  # Same index
      start_position: 100,
      end_position: 200
    )

    assert_not duplicate_chunk.valid?
    assert duplicate_chunk.errors[:chunk_index].present?
  end

  test "should have many embeddings" do
    chunk = @study_material.document_chunks.create!(
      content: "Test content",
      token_count: 10,
      chunk_index: 0,
      start_position: 0,
      end_position: 100
    )

    assert_respond_to chunk, :embedding
  end

  test "should have text_preview method" do
    chunk = @study_material.document_chunks.create!(
      content: "This is a very long test content that should be truncated",
      token_count: 10,
      chunk_index: 0,
      start_position: 0,
      end_position: 100
    )

    preview = chunk.text_preview(20)
    assert preview.length <= 20
  end

  test "should check embedding_generated status" do
    chunk = @study_material.document_chunks.create!(
      content: "Test content",
      token_count: 10,
      chunk_index: 0,
      start_position: 0,
      end_position: 100
    )

    assert_not chunk.embedding_generated?

    # Add embedding
    embedding_vector = Array.new(1536) { rand(-1.0..1.0) }
    magnitude = Math.sqrt(embedding_vector.sum { |v| v ** 2 })
    chunk.create_embedding!(
      vector: embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    assert chunk.embedding_generated?
  end
end
