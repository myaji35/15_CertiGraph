class StudyMaterialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set
  before_action :set_study_material, only: [:destroy, :process_pdf]

  def create
    @study_material = @study_set.study_materials.build(study_material_params)

    # Check for duplicate file name
    if @study_material.pdf_file.present?
      filename = @study_material.pdf_file.filename.to_s
      if @study_set.study_materials.joins(pdf_file_attachment: :blob)
                   .where(active_storage_blobs: { filename: filename }).exists?
        redirect_to study_set_path(@study_set), alert: "이미 동일한 이름의 파일이 업로드되어 있습니다: #{filename}"
        return
      end
    end

    if @study_material.save
      # Auto-start PDF processing
      @study_material.update(status: 'processing')
      ProcessPdfJob.perform_later(@study_material.id)

      respond_to do |format|
        format.html { redirect_to study_set_path(@study_set), notice: 'PDF 업로드 완료! 자동으로 문제 추출을 시작합니다...' }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append('study-materials-list',
                                                   partial: 'study_materials/study_material',
                                                   locals: { study_material: @study_material, study_set: @study_set })
        end
      end
    else
      redirect_to study_set_path(@study_set), alert: "PDF 업로드에 실패했습니다: #{@study_material.errors.full_messages.join(', ')}"
    end
  end

  def process_pdf
    if @study_material.status == 'pending'
      # 백그라운드 잡으로 PDF 처리 시작
      ProcessPdfJob.perform_later(@study_material.id)
      @study_material.update(status: 'processing')

      respond_to do |format|
        format.html { redirect_to study_set_path(@study_set), notice: 'PDF 파싱을 시작했습니다. 잠시만 기다려주세요...' }
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@study_material, partial: 'study_materials/study_material', locals: { study_material: @study_material, study_set: @study_set }) }
      end
    else
      redirect_to study_set_path(@study_set), alert: '이미 처리 중이거나 완료된 파일입니다.'
    end
  end

  def destroy
    @study_material.destroy
    redirect_to study_set_path(@study_set), notice: '학습 자료가 삭제되었습니다.'
  end

  private

  def set_study_set
    @study_set = current_user.study_sets.find(params[:study_set_id])
  end

  def set_study_material
    @study_material = @study_set.study_materials.find(params[:id])
  end

  def study_material_params
    params.require(:study_material).permit(:name, :pdf_file)
  end
end