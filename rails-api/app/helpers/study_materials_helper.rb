# frozen_string_literal: true

module StudyMaterialsHelper
  def status_badge(status)
    case status
    when 'pending'
      content_tag(:span, '대기 중', class: 'px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800')
    when 'processing'
      content_tag(:span, '처리 중', class: 'px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800')
    when 'completed'
      content_tag(:span, '완료', class: 'px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800')
    when 'failed'
      content_tag(:span, '실패', class: 'px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800')
    else
      content_tag(:span, status, class: 'px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-800')
    end
  end

  def processing_progress_class(progress)
    if progress < 30
      'bg-red-600'
    elsif progress < 70
      'bg-yellow-600'
    else
      'bg-green-600'
    end
  end
end
