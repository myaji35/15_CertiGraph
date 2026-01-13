class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    @recent_study_sets = current_user.study_sets.order(created_at: :desc).limit(5)
  end
end