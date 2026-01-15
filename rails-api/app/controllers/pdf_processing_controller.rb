# PDF Processing Controller
# PDF 업로드 및 처리 상태 관리 API

class PdfProcessingController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [:show, :retry, :cancel]

  # POST /api/pdf_processing
  # PDF 파일 업로드 및 처리 시작
  def create
    @study_material = current_user.study_materials.build(study_material_params)

    if @study_material.save
      # 백그라운드에서 PDF 처리 시작
      ProcessPdfJob.perform_later(@study_material.id)

      render json: {
        success: true,
        message: 'PDF upload successful. Processing started.',
        study_material: {
          id: @study_material.id,
          filename: @study_material.pdf_file.filename.to_s,
          status: @study_material.status,
          uploaded_at: @study_material.created_at
        }
      }, status: :created
    else
      render json: {
        success: false,
        errors: @study_material.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/pdf_processing/:id
  # PDF 처리 상태 조회
  def show
    render json: {
      success: true,
      study_material: {
        id: @study_material.id,
        filename: @study_material.pdf_file.filename.to_s,
        status: @study_material.status,
        progress: calculate_progress(@study_material),
        extracted_data: @study_material.extracted_data,
        error_message: @study_material.error_message,
        created_at: @study_material.created_at,
        updated_at: @study_material.updated_at
      }
    }
  end

  # POST /api/pdf_processing/:id/retry
  # 실패한 PDF 처리 재시도
  def retry
    if @study_material.status == 'failed'
      @study_material.update(
        status: 'pending',
        error_message: nil
      )

      ProcessPdfJob.perform_later(@study_material.id)

      render json: {
        success: true,
        message: 'PDF processing retry started.',
        study_material: {
          id: @study_material.id,
          status: @study_material.status
        }
      }
    else
      render json: {
        success: false,
        message: "Cannot retry. Current status: #{@study_material.status}"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/pdf_processing/:id/cancel
  # PDF 처리 취소
  def cancel
    if @study_material.status == 'processing'
      @study_material.update(status: 'cancelled')

      render json: {
        success: true,
        message: 'PDF processing cancelled.',
        study_material: {
          id: @study_material.id,
          status: @study_material.status
        }
      }
    else
      render json: {
        success: false,
        message: "Cannot cancel. Current status: #{@study_material.status}"
      }, status: :unprocessable_entity
    end
  end

  # GET /api/pdf_processing
  # 사용자의 모든 PDF 처리 현황 조회
  def index
    @study_materials = current_user.study_materials
                                   .order(created_at: :desc)
                                   .page(params[:page])
                                   .per(params[:per_page] || 20)

    render json: {
      success: true,
      study_materials: @study_materials.map do |sm|
        {
          id: sm.id,
          filename: sm.pdf_file.attached? ? sm.pdf_file.filename.to_s : 'N/A',
          status: sm.status,
          progress: calculate_progress(sm),
          total_questions: sm.extracted_data&.dig('total_questions') || 0,
          created_at: sm.created_at,
          updated_at: sm.updated_at
        }
      end,
      pagination: {
        current_page: @study_materials.current_page,
        total_pages: @study_materials.total_pages,
        total_count: @study_materials.total_count
      }
    }
  end

  # GET /api/pdf_processing/stats
  # PDF 처리 통계
  def stats
    study_materials = current_user.study_materials

    render json: {
      success: true,
      stats: {
        total: study_materials.count,
        pending: study_materials.where(status: 'pending').count,
        processing: study_materials.where(status: 'processing').count,
        completed: study_materials.where(status: 'completed').count,
        failed: study_materials.where(status: 'failed').count,
        total_questions: study_materials.sum { |sm| sm.extracted_data&.dig('total_questions') || 0 }
      }
    }
  end

  private

  def set_study_material
    @study_material = current_user.study_materials.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Study material not found'
    }, status: :not_found
  end

  def study_material_params
    params.require(:study_material).permit(:pdf_file, :title, :description, :study_set_id)
  end

  def calculate_progress(study_material)
    case study_material.status
    when 'pending'
      0
    when 'processing'
      50 # 중간 진행
    when 'completed'
      100
    when 'failed', 'cancelled'
      0
    else
      0
    end
  end
end
