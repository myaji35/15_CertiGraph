class Option < ApplicationRecord
  belongs_to :question

  validates :content, presence: true
  validates :is_correct, inclusion: { in: [true, false] }

  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
  scope :ordered, -> { order(:id) }

  # Get option label (①, ②, etc.)
  def label
    index = question.options.find_index { |opt| opt.id == id }
    return "①" unless index

    case index
    when 0 then "①"
    when 1 then "②"
    when 2 then "③"
    when 3 then "④"
    when 4 then "⑤"
    else "⑥"
    end
  end

  # Check if option has image
  def has_image?
    content.to_s.include?('![') || content.to_s.include?('[image')
  end

  # Check if option has table
  def has_table?
    content.to_s.include?('|')
  end

  # Get clean text without markdown
  def clean_text
    content.to_s.gsub(/!\[.*?\]\(.*?\)/, '[이미지]')
             .gsub(/\[image.*?\]/, '[이미지]')
             .strip
  end
end
