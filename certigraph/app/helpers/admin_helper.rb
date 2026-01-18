# frozen_string_literal: true

module AdminHelper
  # Returns CSS classes for difficulty badge based on difficulty level
  # @param difficulty [Integer] Difficulty level (1-5)
  # @return [String] CSS classes for badge styling
  def difficulty_badge_class(difficulty)
    return 'bg-gray-100 text-gray-800' if difficulty.nil?

    case difficulty
    when 1..2
      'bg-green-100 text-green-800'
    when 3
      'bg-yellow-100 text-yellow-800'
    when 4..5
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end
end
