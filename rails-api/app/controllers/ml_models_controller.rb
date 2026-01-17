class MlModelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ml_model, only: [:show, :update, :destroy, :deploy, :predict, :validate, :metrics]
  before_action :require_admin, except: [:index, :show, :predict, :metrics]

  # GET /ml_models
  def index
    @ml_models = MlModel.all.order(created_at: :desc)

    if params[:model_type]
      @ml_models = @ml_models.where(model_type: params[:model_type])
    end

    if params[:status]
      @ml_models = @ml_models.where(status: params[:status])
    end

    render json: {
      success: true,
      ml_models: @ml_models.map { |model| format_ml_model(model) }
    }
  end

  # GET /ml_models/:id
  def show
    render json: {
      success: true,
      ml_model: format_ml_model_detailed(@ml_model)
    }
  end

  # POST /ml_models
  def create
    @ml_model = MlModel.create!(
      model_params.merge(
        trained_by: current_user,
        version: '1.0'
      )
    )

    render json: {
      success: true,
      ml_model: format_ml_model(@ml_model),
      message: 'ML model created successfully'
    }, status: :created
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to create ML model: #{e.message}"
    }, status: :unprocessable_entity
  end

  # PATCH /ml_models/:id
  def update
    if @ml_model.update(model_params)
      render json: {
        success: true,
        ml_model: format_ml_model(@ml_model),
        message: 'ML model updated successfully'
      }
    else
      render json: {
        success: false,
        errors: @ml_model.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /ml_models/:id
  def destroy
    @ml_model.destroy

    render json: {
      success: true,
      message: 'ML model deleted successfully'
    }
  end

  # POST /ml_models/:id/train
  def train
    TrainMlModelJob.perform_later(@ml_model.id)

    render json: {
      success: true,
      message: 'ML model training started',
      ml_model: format_ml_model(@ml_model)
    }
  end

  # POST /ml_models/:id/deploy
  def deploy
    if @ml_model.deploy!
      render json: {
        success: true,
        ml_model: format_ml_model(@ml_model),
        message: 'ML model deployed successfully'
      }
    else
      render json: {
        success: false,
        message: 'Cannot deploy model. Model must be trained first.'
      }, status: :unprocessable_entity
    end
  end

  # POST /ml_models/:id/predict
  def predict
    input_features = params[:input_features] || {}
    context = params[:context] || {}

    result = @ml_model.predict(
      input_features,
      user: current_user,
      context: context.merge(prediction_type: params[:prediction_type])
    )

    render json: {
      success: true,
      prediction: result
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Prediction failed: #{e.message}"
    }, status: :unprocessable_entity
  end

  # POST /ml_models/:id/validate
  def validate
    prediction_id = params[:prediction_id]
    actual_outcome = params[:actual_outcome]

    @ml_model.validate_prediction(prediction_id, actual_outcome)

    render json: {
      success: true,
      message: 'Prediction validated'
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Validation failed: #{e.message}"
    }, status: :unprocessable_entity
  end

  # GET /ml_models/:id/metrics
  def metrics
    metrics = @ml_model.calculate_performance_metrics

    render json: {
      success: true,
      metrics: metrics
    }
  end

  # POST /ml_models/:id/create_version
  def create_version
    new_model = @ml_model.create_new_version

    render json: {
      success: true,
      ml_model: format_ml_model(new_model),
      message: 'New model version created'
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to create version: #{e.message}"
    }, status: :unprocessable_entity
  end

  private

  def set_ml_model
    @ml_model = MlModel.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'ML model not found'
    }, status: :not_found
  end

  def model_params
    params.require(:ml_model).permit(
      :name,
      :model_type,
      :description,
      :algorithm,
      model_parameters: {},
      features: []
    )
  end

  def require_admin
    unless current_user.role == 'admin'
      render json: {
        success: false,
        message: 'Admin access required'
      }, status: :forbidden
    end
  end

  def format_ml_model(model)
    {
      id: model.id,
      name: model.name,
      model_type: model.model_type,
      version: model.version,
      status: model.status,
      algorithm: model.algorithm,
      accuracy: model.accuracy,
      is_active: model.is_active,
      trained_at: model.trained_at,
      prediction_count: model.prediction_count
    }
  end

  def format_ml_model_detailed(model)
    format_ml_model(model).merge(
      description: model.description,
      training_samples_count: model.training_samples_count,
      features: model.features,
      feature_importance: model.feature_importance,
      precision: model.precision,
      recall: model.recall,
      f1_score: model.f1_score,
      training_history: model.training_history,
      deployed_at: model.deployed_at,
      last_used_at: model.last_used_at
    )
  end
end
