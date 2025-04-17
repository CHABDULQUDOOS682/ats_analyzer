class AnalyzerController < ApplicationController
  before_action :validate_file, only: [:analyze]

  def index
  end

  def analyze
    job_title = params[:job_title]
    job_description = params[:job_description]
    pdf_content = extract_pdf_content(params[:resume])
    prompt_type = params[:prompt_type]

    # response = analyze_with_gemini(job_title, job_description, pdf_content, prompt_type)
    #
    # render turbo_stream: turbo_stream.update("analysis_result", partial: "analysis_result", locals: { response: response })

    @analysis_result = analyze_with_gemini(job_title, job_description, pdf_content, prompt_type)

    respond_to do |format|
      format.html # Will render analyze.html.erb
      format.json { render json: { result: @analysis_result } }
    end

  end

  private

  # PDF validation and processing
  def validate_file
    unless params[:resume]&.content_type == "application/pdf"
      flash[:alert] = "Please upload a PDF file"
      redirect_to root_path
    end
  end

  def extract_pdf_content(uploaded_file)
    PDF::Reader.new(uploaded_file.tempfile).pages.map(&:text).join("\n")
  end

  # Gemini API interaction
  def analyze_with_gemini(job_title, job_description, resume_text, prompt_type)
    prompt = build_prompt(job_title, job_description, prompt_type)
    full_content = "#{prompt}\n\nResume Content:\n#{resume_text}"

    begin
      response = GEMINI_CLIENT.generate_content({
                                                  contents: [{
                                                               parts: [{
                                                                         text: full_content
                                                                       }]
                                                             }]
                                                })

      extract_response_text(response)
    rescue Gemini::Error => e
      Rails.logger.error "Gemini API Error: #{e.message}"
      "Gemini API Error: #{e.message}"
    rescue => e
      Rails.logger.error "Unexpected Error: #{e.message}"
      "Unexpected Error: #{e.message}"
    end
  end

  # Prompt building
  def build_prompt(job_title, job_description, prompt_type)
    case prompt_type.to_s
    when "analyze"
      analyze_prompt(job_title, job_description)
    when "recommend"
      recommend_prompt(job_title, job_description)
    when "missing"
      missing_keywords_prompt(job_title, job_description)
    when "match"
      match_percentage_prompt(job_title, job_description)
    else
      default_prompt(job_title)
    end
  end

  def analyze_prompt(job_title, job_description)
    <<~PROMPT
      You are an expert HR and ATS specialist with deep knowledge of #{job_title}.
      Evaluate the resume based on the provided job description: #{job_description}.
      Your response must include:
      - A detailed assessment of resume strengths and weaknesses.
      - Critical gaps and missing elements.
      - Direct and actionable improvement recommendations.
      Format all suggestions as clear bullet points.
    PROMPT
  end

  def recommend_prompt(job_title, job_description)
    <<~PROMPT
      You are a professional career coach and resume reviewer specialized in #{job_title}.
      Review the resume against the job description: #{job_description}.
      Provide:
      - Concrete skill improvement recommendations.
      - Career development suggestions.
      - Steps to enhance the resume's chances of shortlisting.
      Keep the suggestions professional and ATS-focused.
    PROMPT
  end

  def missing_keywords_prompt(job_title, job_description)
    <<~PROMPT
      As an ATS and recruitment expert in #{job_title}, your task is:
      - Identify essential keywords and skills present in the job description: #{job_description} but missing from the resume.
      - Present the missing items as a bullet point list.
      Only include highly relevant and impactful keywords for ATS scoring.
    PROMPT
  end

  def match_percentage_prompt(job_title, job_description)
    <<~PROMPT
      Act as a strict ATS evaluator for #{job_title}.
      Your task:
      - Compare the resume to the job description: #{job_description}.
      - Calculate a realistic match percentage based on ATS standards.
      - Briefly justify the percentage.
      Be unbiased and professional.
    PROMPT
  end

  def default_prompt(job_title)
    "Please analyze this resume for the #{job_title} position."
  end

  # Response handling
  def extract_response_text(response)
    if response["candidates"]&.first
      response.dig("candidates", 0, "content", "parts", 0, "text") ||
        "Analysis complete but no text returned"
    else
      Rails.logger.error "Unexpected response format: #{response.inspect}"
      "Unexpected response format from API"
    end
  end


end
