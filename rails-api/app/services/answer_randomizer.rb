# app/services/answer_randomizer.rb
class AnswerRandomizer
  STRATEGIES = %w[full_random constrained_random block_random].freeze

  attr_reader :strategy, :seed, :random

  def initialize(strategy: 'full_random', seed: nil)
    @strategy = validate_strategy(strategy)
    @seed = seed || generate_seed
    @random = Random.new(@seed.to_i(16))
  end

  # Randomize options for a single question
  # Returns: { randomized_options: [...], option_map: {...}, original_correct: ..., new_correct: ... }
  def randomize_question_options(question)
    options = extract_options(question)
    return default_response(options) if options.empty?

    original_correct_index = find_correct_option_index(question, options)

    case @strategy
    when 'full_random'
      randomized = fisher_yates_shuffle(options)
    when 'constrained_random'
      randomized = constrained_shuffle(options, original_correct_index)
    when 'block_random'
      randomized = block_shuffle(options, original_correct_index)
    else
      randomized = options
    end

    new_correct_index = randomized.index { |opt| opt[:is_correct] }

    {
      randomized_options: randomized,
      option_map: build_option_map(options, randomized),
      original_correct_index: original_correct_index,
      new_correct_index: new_correct_index,
      seed: @seed,
      strategy: @strategy
    }
  end

  # Randomize options for multiple questions (exam session)
  def randomize_exam_questions(questions)
    questions.map do |question|
      {
        question_id: question.id,
        randomization: randomize_question_options(question)
      }
    end
  end

  # Restore original option order using seed and option map
  def restore_original_order(randomized_options, option_map)
    original_order = Array.new(randomized_options.size)

    option_map.each do |original_idx, new_idx|
      original_order[original_idx] = randomized_options[new_idx]
    end

    original_order
  end

  # Fisher-Yates shuffle algorithm (unbiased)
  def fisher_yates_shuffle(array)
    shuffled = array.dup
    (shuffled.size - 1).downto(1) do |i|
      j = @random.rand(i + 1)
      shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    shuffled
  end

  # Constrained shuffle: ensures correct answer doesn't appear in same position too often
  # Limits correct answer to middle positions (1, 2, 3) more frequently
  def constrained_shuffle(options, correct_index)
    max_attempts = 10
    attempt = 0

    loop do
      shuffled = fisher_yates_shuffle(options)
      new_correct_index = shuffled.index { |opt| opt[:is_correct] }

      # Accept if correct answer is in middle positions (1, 2, 3) or after max attempts
      if [1, 2, 3].include?(new_correct_index) || attempt >= max_attempts
        return shuffled
      end

      attempt += 1
    end
  end

  # Block shuffle: shuffles within blocks of positions to ensure better distribution
  # For 5 options: first shuffle pairs, then shuffle within blocks
  def block_shuffle(options, correct_index)
    shuffled = options.dup

    # Divide into blocks of 2-3 items
    if options.size == 5
      # Shuffle first 3 and last 2 separately
      first_block = fisher_yates_shuffle(shuffled[0..2])
      second_block = fisher_yates_shuffle(shuffled[3..4])

      # Randomly decide whether to swap blocks
      if @random.rand(2) == 1
        first_block + second_block
      else
        second_block + first_block
      end
    elsif options.size == 4
      # Shuffle two pairs
      first_pair = fisher_yates_shuffle(shuffled[0..1])
      second_pair = fisher_yates_shuffle(shuffled[2..3])

      if @random.rand(2) == 1
        first_pair + second_pair
      else
        second_pair + first_pair
      end
    else
      fisher_yates_shuffle(shuffled)
    end
  end

  # Generate cryptographically secure seed
  def self.generate_seed
    SecureRandom.hex(16)
  end

  # Recreate randomizer from existing seed
  def self.from_seed(seed, strategy: 'full_random')
    new(strategy: strategy, seed: seed)
  end

  # Test randomization quality
  def test_uniformity(iterations: 1000, num_options: 5)
    position_counts = Array.new(num_options) { Hash.new(0) }

    iterations.times do
      options = (0...num_options).map { |i| { id: i, content: "Option #{i}", is_correct: i == 0 } }
      shuffled = fisher_yates_shuffle(options)

      shuffled.each_with_index do |option, position|
        position_counts[position][option[:id]] += 1
      end
    end

    position_counts
  end

  private

  def generate_seed
    self.class.generate_seed
  end

  def validate_strategy(strategy)
    return 'full_random' unless STRATEGIES.include?(strategy)
    strategy
  end

  def extract_options(question)
    if question.respond_to?(:options) && question.options.is_a?(Hash)
      # Options stored as Hash in question model
      question.options.map.with_index do |(key, content), index|
        {
          id: index,
          label: key,
          content: content,
          is_correct: (key == question.answer)
        }
      end
    elsif question.respond_to?(:options) && question.options.respond_to?(:map)
      # Options stored as ActiveRecord relation
      question.options.ordered.map do |option|
        {
          id: option.id,
          label: option.label,
          content: option.content,
          is_correct: option.is_correct
        }
      end
    else
      []
    end
  end

  def find_correct_option_index(question, options)
    options.index { |opt| opt[:is_correct] } || 0
  end

  def build_option_map(original, randomized)
    map = {}

    original.each_with_index do |orig_opt, orig_idx|
      new_idx = randomized.index { |rand_opt| rand_opt[:id] == orig_opt[:id] }
      map[orig_idx] = new_idx if new_idx
    end

    map
  end

  def default_response(options)
    {
      randomized_options: options,
      option_map: {},
      original_correct_index: 0,
      new_correct_index: 0,
      seed: @seed,
      strategy: @strategy
    }
  end
end
