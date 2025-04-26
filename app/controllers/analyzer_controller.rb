# app/controllers/analyzer_controller.rb
class AnalyzerController < ApplicationController
  before_action :validate_file, only: [:analyze]

  def index
  end

  def analyze
    service = ResumeAnalysisService.new(
      job_title: params[:job_title],
      job_description: params[:job_description],
      resume_file: params[:resume],
      prompt_type: params[:prompt_type]
    )

    response = service.call

    render turbo_stream: turbo_stream.update(
      "analysis_result",
      partial: "analysis_result",
      locals: { response: response, prompt_type: params[:prompt_type] }
    )
  end

  private

  def validate_file
    unless params[:resume]&.content_type == "application/pdf"
      flash[:alert] = "Please upload a PDF file"
      redirect_to root_path
    end
  end
end
