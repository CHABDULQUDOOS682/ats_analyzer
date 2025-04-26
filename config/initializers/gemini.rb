require "gemini-ai"

unless Rails.env.test?
  begin
    GEMINI_CLIENT = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV.fetch("GENAI_API_KEY")
      },
      options: {
        model: "gemini-1.5-pro",
        server_sent_events: true,
        timeout: 30
      }
    )

    Rails.logger.info "Gemini client initialized successfully"
  rescue => e
    Rails.logger.error "Failed to initialize Gemini client: #{e.message}"
    raise "Gemini initialization failed: #{e.message}" unless Rails.env.development?
  end
end
