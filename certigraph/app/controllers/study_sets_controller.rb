class StudySetsController < ApplicationController
  def index
    @study_sets = [
      {
        id: 1,
        name: '정보처리기사 필기 2023',
        total_materials: 8,
        total_questions: 240,
        created_at: 1.month.ago
      },
      {
        id: 2,
        name: 'AWS Solutions Architect',
        total_materials: 15,
        total_questions: 450,
        created_at: 2.weeks.ago
      },
      {
        id: 3,
        name: '정보처리기사 필기 2024',
        total_materials: 12,
        total_questions: 360,
        created_at: 1.week.ago
      }
    ]
  end

  def show
    @study_set = {
      id: params[:id],
      name: '정보처리기사 필기 2024',
      certification_id: 'cert_123',
      total_materials: 12,
      total_questions: 360,
      created_at: 1.week.ago
    }
  end
end