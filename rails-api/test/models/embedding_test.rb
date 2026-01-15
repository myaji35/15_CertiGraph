require "test_helper"

class EmbeddingTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: 'test@test.com', password: 'password')
    @study_set = @user.study_sets.create!(title: 'Test Set')
    @study_material = @study_set.study_materials.create!(name: 'Test Material')
    @chunk = @study_material.document_chunks.create!(
      content: "Test content",
      token_count: 10,
      chunk_index: 0,
      start_position: 0,
      end_position: 100
    )
    @embedding_vector = Array.new(1536) { rand(-1.0..1.0) }
  end

  test "should create a valid embedding" do
    magnitude = Math.sqrt(@embedding_vector.sum { |v| v ** 2 })
    embedding = Embedding.new(
      document_chunk: @chunk,
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    assert embedding.valid?
  end

  test "should require vector, magnitude, and generated_at" do
    embedding = Embedding.new(document_chunk: @chunk)

    assert_not embedding.valid?
    assert embedding.errors[:vector].present?
    assert embedding.errors[:magnitude].present?
    assert embedding.errors[:generated_at].present?
  end

  test "should convert vector array correctly" do
    magnitude = Math.sqrt(@embedding_vector.sum { |v| v ** 2 })
    embedding = @chunk.create_embedding!(
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    vector_array = embedding.vector_array
    assert_equal @embedding_vector.length, vector_array.length
    assert_equal @embedding_vector, vector_array
  end

  test "should calculate similarity correctly" do
    magnitude = Math.sqrt(@embedding_vector.sum { |v| v ** 2 })
    embedding1 = @chunk.create_embedding!(
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    # Similar vector (same vector)
    similarity = embedding1.similarity_to(@embedding_vector)
    assert similarity > 0.9  # Should be very similar

    # Different vector
    different_vector = Array.new(1536) { rand(-1.0..1.0) }
    similarity2 = embedding1.similarity_to(different_vector)
    assert similarity2 >= 0  # Should be between 0 and 1
  end

  test "should return 0 similarity for empty vectors" do
    magnitude = Math.sqrt(@embedding_vector.sum { |v| v ** 2 })
    embedding = @chunk.create_embedding!(
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    similarity = embedding.similarity_to([])
    assert_equal 0.0, similarity
  end

  test "should have model_version with default value" do
    magnitude = Math.sqrt(@embedding_vector.sum { |v| v ** 2 })
    embedding = @chunk.create_embedding!(
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    assert_equal 1, embedding.model_version
  end

  test "should be orderable by generated_at" do
    magnitude = Math.sqrt(@embedding_vector.sum { |v| v ** 2 })

    chunk1 = @study_material.document_chunks.create!(
      content: "Content 1",
      token_count: 10,
      chunk_index: 1,
      start_position: 0,
      end_position: 100
    )

    chunk2 = @study_material.document_chunks.create!(
      content: "Content 2",
      token_count: 10,
      chunk_index: 2,
      start_position: 100,
      end_position: 200
    )

    emb1 = chunk1.create_embedding!(
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: 1.day.ago
    )

    emb2 = chunk2.create_embedding!(
      vector: @embedding_vector,
      magnitude: magnitude,
      generated_at: Time.current
    )

    recent = Embedding.recent.first
    assert_equal emb2.id, recent.id
  end
end
