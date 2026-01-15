class KnowledgeVisualizationController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [:show]

  # GET /knowledge_map/:id
  def show
    @study_material = StudyMaterial.find(params[:id])
    @page_title = "3D Knowledge Map - #{@study_material.name}"

    unless @study_material.user_id == current_user.id
      redirect_to dashboard_index_path, alert: "You don't have access to this study material"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_index_path, alert: "Study material not found"
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:id])
  end
end
