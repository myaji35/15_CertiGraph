class StudyMaterialsController < ApplicationController
  before_action :set_study_set

  def index
    @materials = mock_materials
    
    # Filter by status if provided
    if params[:status].present? && params[:status] != 'all'
      @materials = @materials.select { |m| m[:status] == params[:status] }
    end
    
    # Sort materials
    case params[:sort]
    when 'name'
      @materials = @materials.sort_by { |m| m[:title] }
    when 'questions'
      @materials = @materials.sort_by { |m| -m[:total_questions] }
    else # 'date' or default
      @materials = @materials.sort_by { |m| -m[:created_at].to_i }
    end
    
    # Search filter
    if params[:search].present?
      query = params[:search].downcase
      @materials = @materials.select { |m| m[:title].downcase.include?(query) }
    end

    render partial: 'materials_table', locals: { materials: @materials } if request.xhr?
  end

  def create
    # Handle file upload
    # In a real app, this would process the PDF and create questions
    redirect_to study_set_study_materials_path(@study_set), notice: '학습자료가 업로드되었습니다.'
  end

  def destroy
    # Delete material
    redirect_to study_set_study_materials_path(@study_set), notice: '학습자료가 삭제되었습니다.'
  end

  def retry
    # Retry processing
    redirect_to study_set_study_materials_path(@study_set), notice: '재처리가 시작되었습니다.'
  end

  def questions
    # Return questions for a material
    @questions = mock_questions
    render json: { questions: @questions }
  end

  private

  def set_study_set
    @study_set = params[:study_set_id]
  end

  def mock_materials
    [
      {
        id: '1',
        title: '2024년 1회 기출문제',
        pdf_url: '/materials/1.pdf',
        file_size_bytes: 2_516_582,
        status: 'completed',
        total_questions: 30,
        processing_progress: 100,
        created_at: 1.day.ago,
        processing_logs: []
      },
      {
        id: '2',
        title: '2023년 3회 기출문제',
        pdf_url: '/materials/2.pdf',
        file_size_bytes: 2_202_010,
        status: 'processing',
        total_questions: 30,
        processing_progress: 65,
        created_at: 2.days.ago,
        processing_logs: [
          { timestamp: 5.minutes.ago, progress: 50, message: 'PDF 파싱 중...', status: 'processing' },
          { timestamp: 2.minutes.ago, progress: 65, message: '질문 추출 중...', status: 'processing' }
        ]
      },
      {
        id: '3',
        title: '데이터베이스 핵심정리',
        pdf_url: '/materials/3.pdf',
        file_size_bytes: 1_887_436,
        status: 'failed',
        total_questions: 0,
        processing_progress: 0,
        created_at: 3.days.ago,
        processing_error: 'PDF 파싱 중 오류가 발생했습니다.',
        processing_logs: [
          { timestamp: 1.hour.ago, progress: 10, message: 'PDF 파싱 시작', status: 'processing' },
          { timestamp: 50.minutes.ago, progress: 10, message: 'PDF 형식 오류', status: 'failed' }
        ]
      },
      {
        id: '4',
        title: '운영체제 문제집',
        pdf_url: '/materials/4.pdf',
        file_size_bytes: 2_097_152,
        status: 'completed',
        total_questions: 28,
        processing_progress: 100,
        created_at: 4.days.ago,
        processing_logs: []
      },
      {
        id: '5',
        title: '소프트웨어공학 요약',
        pdf_url: '/materials/5.pdf',
        file_size_bytes: 1_572_864,
        status: 'completed',
        total_questions: 22,
        processing_progress: 100,
        created_at: 5.days.ago,
        processing_logs: []
      }
    ]
  end

  def mock_questions
    [
      {
        id: 1,
        question_number: 1,
        question_text: '다음 중 데이터베이스의 특징이 아닌 것은?',
        options: [
          { number: 1, text: '실시간 접근성' },
          { number: 2, text: '계속적인 변화' },
          { number: 3, text: '동시 공유' },
          { number: 4, text: '종속성' }
        ],
        correct_answer: 4,
        explanation: '데이터베이스는 데이터 독립성을 가지므로 종속성은 특징이 아닙니다.'
      }
    ]
  end
end