# Knowledge Graphs Controller (Web UI)
class KnowledgeGraphsController \u003c ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material

  # GET /study_sets/:study_set_id/study_materials/:study_material_id/knowledge_graphs
  def show
    @study_set = @study_material.study_set
    
    # Check if user has access to this study material
    unless @study_set.user_id == current_user.id
      redirect_to root_path, alert: '권한이 없습니다.'
      return
    end
    
    # Render the knowledge graph visualization view
    render 'knowledge_graphs/show'
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: '학습 자료를 찾을 수 없습니다.'
  end
end
