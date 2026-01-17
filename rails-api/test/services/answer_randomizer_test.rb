# test/services/answer_randomizer_test.rb
require 'test_helper'

class AnswerRandomizerTest < ActiveSupport::TestCase
  def setup
    @randomizer = AnswerRandomizer.new(strategy: 'full_random')
    @question = create_test_question
  end

  test "generates unique seed" do
    seed1 = AnswerRandomizer.generate_seed
    seed2 = AnswerRandomizer.generate_seed

    assert_not_equal seed1, seed2
    assert_equal 32, seed1.length # 16 bytes hex = 32 chars
  end

  test "fisher-yates shuffle is reproducible with same seed" do
    seed = "abc123def456"
    randomizer1 = AnswerRandomizer.new(seed: seed)
    randomizer2 = AnswerRandomizer.new(seed: seed)

    array = [1, 2, 3, 4, 5]
    result1 = randomizer1.fisher_yates_shuffle(array)
    result2 = randomizer2.fisher_yates_shuffle(array)

    assert_equal result1, result2
  end

  test "randomizes question options" do
    result = @randomizer.randomize_question_options(@question)

    assert result[:randomized_options].present?
    assert result[:option_map].present?
    assert result[:seed].present?
    assert_equal 'full_random', result[:strategy]
  end

  test "constrained randomization favors middle positions" do
    randomizer = AnswerRandomizer.new(strategy: 'constrained_random')
    middle_positions = 0

    100.times do
      result = randomizer.randomize_question_options(@question)
      correct_position = result[:new_correct_index]
      middle_positions += 1 if [1, 2, 3].include?(correct_position)
    end

    # At least 70% should be in middle positions
    assert middle_positions >= 70, "Expected >= 70 middle positions, got #{middle_positions}"
  end

  test "block randomization strategy works" do
    randomizer = AnswerRandomizer.new(strategy: 'block_random')
    result = randomizer.randomize_question_options(@question)

    assert result[:randomized_options].present?
    assert_equal 5, result[:randomized_options].size
  end

  test "can restore original order using seed" do
    seed = @randomizer.seed
    result = @randomizer.randomize_question_options(@question)
    randomized = result[:randomized_options]
    option_map = result[:option_map]

    restored = @randomizer.restore_original_order(randomized, option_map)

    # Check that first option is back in first position
    assert_equal restored[0][:id], 0
  end

  test "validates strategy" do
    assert AnswerRandomizer::STRATEGIES.include?('full_random')
    assert AnswerRandomizer::STRATEGIES.include?('constrained_random')
    assert AnswerRandomizer::STRATEGIES.include?('block_random')
    assert_equal 3, AnswerRandomizer::STRATEGIES.size
  end

  test "randomize from existing seed" do
    seed = "test_seed_123"
    randomizer = AnswerRandomizer.from_seed(seed, strategy: 'full_random')

    assert_equal seed, randomizer.seed
    assert_equal 'full_random', randomizer.strategy
  end

  test "test uniformity distribution" do
    randomizer = AnswerRandomizer.new(strategy: 'full_random')
    position_counts = randomizer.test_uniformity(iterations: 100, num_options: 5)

    assert_equal 5, position_counts.size
    position_counts.each do |position_hash|
      assert_equal 5, position_hash.keys.size # Each position should have all 5 options
    end
  end

  private

  def create_test_question
    # Mock question object
    question = OpenStruct.new(
      id: 1,
      answer: "①",
      options: {
        "①" => "Option 1",
        "②" => "Option 2",
        "③" => "Option 3",
        "④" => "Option 4",
        "⑤" => "Option 5"
      }
    )
    question
  end
end
