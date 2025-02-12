class DirectusClient

  attr_reader :settings, :logger

  def initialize(settings, logger)
    @settings = settings
    @logger = logger
  end

  def shows
    get_json.lazy.map { |data| DirectusShow.new(data) }
  end

  private

  def get_json
    logger.debug("Getting shows from #{endpoint_url} ...")
    response = RestClient.get("#{endpoint_url}?limit=-1")
    json = JSON.parse(response.body)
    json['data']
  end

  def endpoint_url
    settings['endpoint']
  end
end
