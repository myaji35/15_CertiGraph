# app/controllers/widgets_controller.rb
class WidgetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_widget, only: [:show, :update, :destroy, :toggle_visibility, :reset]

  # GET /widgets
  def index
    @widgets = current_user.dashboard_widgets.ordered

    if params[:visible_only]
      @widgets = @widgets.visible
    end

    render json: {
      success: true,
      data: @widgets.as_json(
        only: [:id, :widget_type, :title, :position, :visible, :layout, :width, :height, :refresh_interval, :configuration]
      )
    }
  end

  # GET /widgets/:id
  def show
    render json: {
      success: true,
      data: @widget.as_json(
        only: [:id, :widget_type, :title, :position, :visible, :layout, :width, :height, :refresh_interval, :configuration],
        include: {
          user: { only: [:id, :email] }
        }
      )
    }
  end

  # POST /widgets
  def create
    @widget = current_user.dashboard_widgets.new(widget_params)

    if @widget.save
      # Broadcast widget creation
      realtime_service = RealtimeAnalyticsService.new(current_user)
      ActionCable.server.broadcast(
        "dashboard_#{current_user.id}",
        {
          type: 'widget_created',
          widget: @widget.as_json(only: [:id, :widget_type, :title, :position, :visible, :layout]),
          timestamp: Time.current.iso8601
        }
      )

      render json: {
        success: true,
        data: @widget,
        message: 'Widget created successfully'
      }, status: :created
    else
      render json: {
        success: false,
        errors: @widget.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /widgets/:id
  def update
    old_position = @widget.position

    if @widget.update(widget_params)
      # Broadcast widget update
      ActionCable.server.broadcast(
        "dashboard_#{current_user.id}",
        {
          type: 'widget_updated',
          widget: @widget.as_json(only: [:id, :widget_type, :title, :position, :visible, :layout, :configuration]),
          old_position: old_position,
          timestamp: Time.current.iso8601
        }
      )

      render json: {
        success: true,
        data: @widget,
        message: 'Widget updated successfully'
      }
    else
      render json: {
        success: false,
        errors: @widget.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /widgets/:id
  def destroy
    @widget.destroy

    # Broadcast widget deletion
    ActionCable.server.broadcast(
      "dashboard_#{current_user.id}",
      {
        type: 'widget_deleted',
        widget_id: @widget.id,
        timestamp: Time.current.iso8601
      }
    )

    render json: {
      success: true,
      message: 'Widget deleted successfully'
    }
  end

  # POST /widgets/:id/toggle_visibility
  def toggle_visibility
    @widget.update(visible: !@widget.visible)

    # Broadcast visibility change
    ActionCable.server.broadcast(
      "dashboard_#{current_user.id}",
      {
        type: 'widget_visibility_changed',
        widget_id: @widget.id,
        visible: @widget.visible,
        timestamp: Time.current.iso8601
      }
    )

    render json: {
      success: true,
      data: { visible: @widget.visible },
      message: "Widget #{@widget.visible ? 'shown' : 'hidden'}"
    }
  end

  # POST /widgets/:id/reset
  def reset
    @widget.reset_to_default

    render json: {
      success: true,
      data: @widget,
      message: 'Widget reset to default configuration'
    }
  end

  # POST /widgets/batch_update
  def batch_update
    updates = params[:widgets]

    results = []
    errors = []

    updates.each do |widget_update|
      widget = current_user.dashboard_widgets.find_by(id: widget_update[:id])

      if widget
        if widget.update(
          position: widget_update[:position],
          width: widget_update[:width],
          height: widget_update[:height],
          visible: widget_update[:visible]
        )
          results << { id: widget.id, success: true }
        else
          errors << { id: widget.id, errors: widget.errors.full_messages }
        end
      else
        errors << { id: widget_update[:id], errors: ['Widget not found'] }
      end
    end

    # Broadcast batch update
    ActionCable.server.broadcast(
      "dashboard_#{current_user.id}",
      {
        type: 'widgets_batch_updated',
        updated_count: results.count,
        timestamp: Time.current.iso8601
      }
    )

    render json: {
      success: errors.empty?,
      data: {
        updated: results,
        errors: errors
      },
      message: "#{results.count} widgets updated"
    }
  end

  # POST /widgets/reorder
  def reorder
    widget_ids = params[:widget_ids]

    widget_ids.each_with_index do |widget_id, index|
      widget = current_user.dashboard_widgets.find_by(id: widget_id)
      widget&.update(position: index)
    end

    # Broadcast reorder
    ActionCable.server.broadcast(
      "dashboard_#{current_user.id}",
      {
        type: 'widgets_reordered',
        widget_ids: widget_ids,
        timestamp: Time.current.iso8601
      }
    )

    render json: {
      success: true,
      message: 'Widgets reordered successfully'
    }
  end

  # GET /widgets/presets
  def presets
    presets = {
      default: default_preset,
      analytics_focus: analytics_focus_preset,
      minimal: minimal_preset
    }

    render json: {
      success: true,
      data: presets
    }
  end

  # POST /widgets/apply_preset
  def apply_preset
    preset_name = params[:preset_name]

    # Clear existing widgets
    current_user.dashboard_widgets.destroy_all

    # Apply preset
    preset_config = case preset_name
                    when 'default'
                      default_preset
                    when 'analytics_focus'
                      analytics_focus_preset
                    when 'minimal'
                      minimal_preset
                    else
                      return render json: { success: false, error: 'Invalid preset' }, status: :bad_request
                    end

    created_widgets = []
    preset_config.each do |widget_config|
      widget = current_user.dashboard_widgets.create(widget_config)
      created_widgets << widget if widget.persisted?
    end

    # Broadcast preset application
    ActionCable.server.broadcast(
      "dashboard_#{current_user.id}",
      {
        type: 'preset_applied',
        preset_name: preset_name,
        widget_count: created_widgets.count,
        timestamp: Time.current.iso8601
      }
    )

    render json: {
      success: true,
      data: created_widgets,
      message: "Preset '#{preset_name}' applied successfully"
    }
  end

  # GET /widgets/data/:id
  def widget_data
    widget = current_user.dashboard_widgets.find(params[:id])
    chart_service = ChartDataService.new(current_user)
    analytics_service = ProgressAnalyticsService.new(current_user)

    data = case widget.widget_type
           when 'progress'
             analytics_service.overall_progress
           when 'recent_scores'
             chart_service.performance_line_chart(period: widget.config['period'] || 'week')
           when 'weakness_analysis'
             analytics_service.learning_patterns[:weak_areas]
           when 'goal_achievement'
             # Would need Goal model
             { goals: [], completion: 0 }
           when 'study_time'
             analytics_service.weekly_stats
           when 'ranking'
             # Would need Leaderboard implementation
             { rank: 0, total_users: 0 }
           when 'upcoming_exams'
             # Would need ExamSchedule model
             []
           when 'recommendations'
             # Would need Recommendation model
             []
           when 'achievements'
             analytics_service.calculate_achievements
           when 'learning_patterns'
             analytics_service.learning_patterns
           else
             { error: 'Unknown widget type' }
           end

    render json: {
      success: true,
      widget_id: widget.id,
      widget_type: widget.widget_type,
      data: data,
      timestamp: Time.current.iso8601
    }
  end

  private

  def set_widget
    @widget = current_user.dashboard_widgets.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Widget not found' }, status: :not_found
  end

  def widget_params
    params.require(:widget).permit(
      :widget_type,
      :title,
      :position,
      :visible,
      :layout,
      :width,
      :height,
      :refresh_interval,
      configuration: {}
    )
  end

  # Preset configurations
  def default_preset
    [
      { widget_type: 'progress', title: 'Overall Progress', position: 0, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'recent_scores', title: 'Recent Performance', position: 1, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'weakness_analysis', title: 'Weak Areas', position: 2, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'study_time', title: 'Study Time', position: 3, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'achievements', title: 'Achievements', position: 4, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'learning_patterns', title: 'Learning Patterns', position: 5, layout: 'medium', width: 6, height: 4 }
    ]
  end

  def analytics_focus_preset
    [
      { widget_type: 'progress', title: 'Progress Overview', position: 0, layout: 'large', width: 12, height: 6 },
      { widget_type: 'recent_scores', title: 'Performance Trend', position: 1, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'weakness_analysis', title: 'Weakness Analysis', position: 2, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'learning_patterns', title: 'Activity Heatmap', position: 3, layout: 'large', width: 12, height: 6 }
    ]
  end

  def minimal_preset
    [
      { widget_type: 'progress', title: 'Progress', position: 0, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'recent_scores', title: 'Recent Scores', position: 1, layout: 'medium', width: 6, height: 4 },
      { widget_type: 'achievements', title: 'Achievements', position: 2, layout: 'small', width: 6, height: 3 }
    ]
  end
end
