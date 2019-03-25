class WebsiteClient

  attr_reader :settings, :logger

  def initialize(settings, logger)
    @settings = settings
    @logger = logger
  end

  def show_links
    agent = Mechanize.new
    page = agent.get(settings['start_page'])
    page.links_with(css: settings['links'])
  end

  def fetch_show_description(link)
    page = link.click
    title = page.search(settings['title']).text.strip
    description = normalize(page.search(settings['description']).first)
    Description.new(title, description)
  end

  private

  def normalize(element)
    return nil unless element

    element.children.map { |x| x.to_html.strip }.join.tr("\n", ' ')
  end

end
