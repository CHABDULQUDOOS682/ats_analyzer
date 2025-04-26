module ApplicationHelper
  def format_analysis(text)
    return content_tag(:div, "No analysis available", class: "text-gray-500") if text.blank?

    # Replace **bold** text
    html = text.gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>') # Bold

    # Replace *italic* text
    html.gsub!(/\*(.*?)\*/, '<em>\1</em>') # Italic

    # Centered main heading for ##
    html.gsub!(/^##\s+(.*)/) do
      "<h1 class='text-4xl font-bold text-center text-[#f7f7f7] my-10'>#{$1}</h1>"
    end

    # Subheading for **Strengths**, **Weaknesses**, etc.
    html.gsub!(/^\*\*(.*?):\*\*/) do
      "<h2 class='text-3xl font-semibold mt-10 mb-6 text-[#e5e5e5]'>#{$1}</h2>"
    end

    # For bullet points like * **Quantifiable Achievements:** text
    html.gsub!(/^\*\s+\*\*(.*?):\*\*\s+(.*)/) do
      "<div class='mb-6 p-4 bg-white text-[#d8d8d8] rounded-md'>
      <h3 class='text-xl font-bold mb-2 text-[#d8d8d8]'>#{$1}</h3>
      <p class='text-[#d8d8d8]'>#{$2}</p>
    </div>"
    end

    # Use simple_format to convert text into paragraphs (this ensures clean line breaks and spacing)
    formatted_html = simple_format(html)

    formatted_html.html_safe
  end

end