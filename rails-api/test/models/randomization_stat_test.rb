# test/models/randomization_stat_test.rb
require 'test_helper'

class RandomizationStatTest < ActiveSupport::TestCase
  # Test validations
  test "requires option_id" do
    stat = RandomizationStat.new(option_label: "①", bias_score: 10.0)
    assert_not stat.valid?
    assert stat.errors[:option_id].present?
  end

  test "requires option_label" do
    stat = RandomizationStat.new(option_id: 1, bias_score: 10.0)
    assert_not stat.valid?
    assert stat.errors[:option_label].present?
  end

  test "bias_score must be between 0 and 100" do
    stat = RandomizationStat.new(
      option_id: 1,
      option_label: "①",
      bias_score: -5
    )
    assert_not stat.valid?

    stat.bias_score = 150
    assert_not stat.valid?

    stat.bias_score = 50
    assert stat.valid?
  end

  # Test instance methods
  test "position_count returns correct count" do
    stat = RandomizationStat.new(
      position_0_count: 10,
      position_1_count: 20,
      position_2_count: 30,
      position_3_count: 40,
      position_4_count: 50
    )

    assert_equal 10, stat.position_count(0)
    assert_equal 30, stat.position_count(2)
    assert_equal 50, stat.position_count(4)
    assert_equal 0, stat.position_count(5) # Out of range
  end

  test "position_counts returns array" do
    stat = RandomizationStat.new(
      position_0_count: 10,
      position_1_count: 20,
      position_2_count: 30,
      position_3_count: 40,
      position_4_count: 50
    )

    counts = stat.position_counts
    assert_equal [10, 20, 30, 40, 50], counts
  end

  test "expected_frequency calculation" do
    stat = RandomizationStat.new(total_randomizations: 100)
    assert_equal 20.0, stat.expected_frequency
  end

  test "significantly_biased? detection" do
    stat = RandomizationStat.new(
      p_value: 0.03,
      bias_score: 20.0
    )
    assert stat.significantly_biased?

    stat.p_value = 0.1
    assert_not stat.significantly_biased?

    stat.p_value = 0.03
    stat.bias_score = 10.0
    assert_not stat.significantly_biased?
  end

  test "quality_rating categorization" do
    stat = RandomizationStat.new

    stat.bias_score = 3.0
    assert_equal 'excellent', stat.quality_rating

    stat.bias_score = 7.0
    assert_equal 'good', stat.quality_rating

    stat.bias_score = 15.0
    assert_equal 'acceptable', stat.quality_rating

    stat.bias_score = 25.0
    assert_equal 'poor', stat.quality_rating

    stat.bias_score = 40.0
    assert_equal 'very_poor', stat.quality_rating
  end

  test "most_frequent_position" do
    stat = RandomizationStat.new(
      position_0_count: 10,
      position_1_count: 50,
      position_2_count: 20,
      position_3_count: 15,
      position_4_count: 5
    )

    assert_equal 1, stat.most_frequent_position
  end

  test "least_frequent_position" do
    stat = RandomizationStat.new(
      position_0_count: 10,
      position_1_count: 50,
      position_2_count: 20,
      position_3_count: 15,
      position_4_count: 5
    )

    assert_equal 4, stat.least_frequent_position
  end

  test "distribution_variance calculation" do
    stat = RandomizationStat.new(
      position_0_count: 20,
      position_1_count: 20,
      position_2_count: 20,
      position_3_count: 20,
      position_4_count: 20
    )

    # Perfect uniform distribution should have 0 variance
    assert_equal 0.0, stat.distribution_variance
  end
end
