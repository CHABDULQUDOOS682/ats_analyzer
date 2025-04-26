# app/services/resume_analysis_service.rb
class ResumeAnalysisService
  def initialize(job_title:, job_description:, resume_file:, prompt_type:)
    @job_title = job_title
    @job_description = job_description
    @resume_file = resume_file
    @prompt_type = prompt_type
  end

  def call
    pdf_content = extract_pdf_content(@resume_file)
    prompt = build_prompt
    response = analyze_with_gemini(pdf_content, prompt)
    extract_response_text(response)
  end

  private

  def extract_pdf_content(uploaded_file)
    PDF::Reader.new(uploaded_file.tempfile).pages.map(&:text).join("\n")
  end

  def build_prompt
    case @prompt_type.to_s
    when "analyze"
      analyze_prompt
    when "recommend"
      recommend_prompt
    when "missing"
      missing_keywords_prompt
    when "match"
      match_percentage_prompt
    else
      default_prompt
    end
  end

  def analyze_prompt
    <<~PROMPT
      You are an expert HR and ATS specialist with deep knowledge of #{@job_title}.
      Evaluate the resume based on the provided job description: #{@job_description}.
      Your response must include:
      - A detailed assessment of resume strengths and weaknesses.
      - Critical gaps and missing elements.
      - Direct and actionable improvement recommendations.
      Format all suggestions as clear bullet points.
    PROMPT
  end

  def recommend_prompt
    <<~PROMPT
      You are a professional career coach and resume reviewer specialized in #{@job_title}.
      Review the resume against the job description: #{@job_description}.
      Provide:
      - Concrete skill improvement recommendations.
      - Career development suggestions.
      - Steps to enhance the resume's chances of shortlisting.
      Keep the suggestions professional and ATS-focused.
    PROMPT
  end

  def missing_keywords_prompt
    <<~PROMPT
      As an ATS and recruitment expert in #{@job_title}, your task is:
      - Identify essential keywords and skills present in the job description: #{@job_description} but missing from the resume.
      - Present the missing items as a bullet point list.
      Only include highly relevant and impactful keywords for ATS scoring.
    PROMPT
  end

  def match_percentage_prompt
    <<~PROMPT
      Act as a strict ATS evaluator for #{@job_title}.
      Your task:
      - Compare the resume to the job description: #{@job_description}.
      - Calculate a realistic match percentage based on ATS standards.
      - Briefly justify the percentage.
      Be unbiased and professional.
    PROMPT
  end

  def default_prompt
    "Please analyze this resume for the #{@job_title} position."
  end

  def analyze_with_gemini(resume_text, prompt)
    full_content = "#{prompt}\n\nResume Content:\n#{resume_text}"

    begin
      response = GEMINI_CLIENT.generate_content({
                                                  contents: [{
                                                               parts: [{
                                                                         text: full_content
                                                                       }]
                                                             }]
                                                })
      response
    rescue Gemini::Error => e
      Rails.logger.error "Gemini API Error: #{e.message}"
      { error: "Gemini API Error: #{e.message}" }
    rescue => e
      Rails.logger.error "Unexpected Error: #{e.message}"
      { error: "Unexpected Error: #{e.message}" }
    end
  end

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
