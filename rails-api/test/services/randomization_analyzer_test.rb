# test/services/randomization_analyzer_test.rb
require 'test_helper'

class RandomizationAnalyzerTest < ActiveSupport::TestCase
  test "chi-square test identifies uniform distribution" do
    analyzer = RandomizationAnalyzer.new(nil)

    # Perfectly uniform distribution
    uniform_counts = [20, 20, 20, 20, 20]
    result = analyzer.chi_square_test(uniform_counts)

    assert_equal 0.0, result[:statistic]
    assert_equal 1.0, result[:p_value]
    assert result[:is_uniform]
  end

  test "chi-square test identifies non-uniform distribution" do
    analyzer = RandomizationAnalyzer.new(nil)

    # Highly biased distribution
    biased_counts = [50, 10, 10, 10, 20]
    result = analyzer.chi_square_test(biased_counts)

    assert result[:statistic] > 0
    assert result[:p_value] < 0.5
  end

  test "calculates bias score correctly" do
    analyzer = RandomizationAnalyzer.new(nil)

    # Perfectly uniform: bias should be 0
    uniform_counts = [20, 20, 20, 20, 20]
    bias = analyzer.calculate_bias_score_for_distribution(uniform_counts)
    assert_equal 0.0, bias

    # Biased distribution: bias should be > 0
    biased_counts = [40, 10, 20, 15, 15]
    bias = analyzer.calculate_bias_score_for_distribution(biased_counts)
    assert bias > 0
  end

  test "handles empty distribution gracefully" do
    analyzer = RandomizationAnalyzer.new(nil)

    result = analyzer.chi_square_test([])
    assert_equal 0.0, result[:statistic]
    assert_equal 1.0, result[:p_value]
    assert result[:is_uniform]
  end

  test "calculates p-value approximation" do
    analyzer = RandomizationAnalyzer.new(nil)

    # Small chi-square should give high p-value
    p_value = analyzer.send(:chi_square_to_p_value, 2.0, 4)
    assert p_value >= 0.05

    # Large chi-square should give low p-value
    p_value = analyzer.send(:chi_square_to_p_value, 20.0, 4)
    assert p_value < 0.05
  end
end
