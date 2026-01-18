# frozen_string_literal: true

module Api
  module V1
    class CheatSheetController < ApplicationController
      before_action :authenticate_user!
      before_action :set_study_set, only: [:show, :pdf]

      # GET /api/v1/study_sets/:id/cheat_sheet
      # Generate cheat sheet report for a study set
      def show
        service = CheatSheetGeneratorService.new
        report = service.generate_for_user(current_user, @study_set)

        render json: {
          success: true,
          data: report[:data],
          markdown: report[:markdown],
          html: report[:html],
          generated_at: Time.current
        }
      end

      # GET /api/v1/study_sets/:id/cheat_sheet/pdf
      # Download cheat sheet as PDF (future implementation)
      def pdf
        service = CheatSheetGeneratorService.new
        report = service.generate_for_user(current_user, @study_set)

        # TODO: Implement PDF generation using Prawn or WickedPDF
        # For now, return markdown
        send_data report[:markdown],
                  filename: "cheat_sheet_#{@study_set.name}_#{Date.today}.md",
                  type: 'text/markdown',
                  disposition: 'attachment'
      end

      private

      def set_study_set
        @study_set = StudySet.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Study set not found'
        }, status: :not_found
      end
    end
  end
end
