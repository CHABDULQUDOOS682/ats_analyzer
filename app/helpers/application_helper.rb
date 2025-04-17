module ApplicationHelper
  def format_analysis(text)
    return content_tag(:div, "No analysis available", class: "text-gray-500") if text.blank?

    html = text.gsub(/\*\*(.*?)\*\*/, '<strong>\1</strong>')
               .gsub(/\*(.*?)\*/, '<em>\1</em>')
               .gsub(/^#\s+(.*)/, '<h3 class="text-lg font-bold mt-4 mb-2">\1</h3>')
               .gsub(/^-\s+(.*)/, '<li class="ml-4 mb-1">\1</li>')
               .gsub(/(<li.*<\/li>)+/m, '<ul class="list-disc mb-3">\0</ul>')

    html.split("\n\n").map do |para|
      para.strip.empty? ? "" : "<p class='mb-3'>#{para}</p>"
    end.join.html_safe
  end
end