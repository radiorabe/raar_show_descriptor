class RaarClient

  JSON_API_CONTENT_TYPE = 'application/vnd.api+json'.freeze

  attr_reader :settings, :logger

  def initialize(settings, logger)
    @settings = settings
    @logger = logger
  end

  def fetch_show(title)
    search_shows(title).find do |show|
      same_title?(show, title)
    end
  end

  def update_description(show, description)
    update_show(show, description.body)
  end

  private

  def search_shows(title)
    response = raar_request(:get,
                            'shows',
                            nil,
                            params: { q: title },
                            accept: JSON_API_CONTENT_TYPE,
                            authorization: "Token token=\"#{api_token}\"")
    json = JSON.parse(response.body)
    json['data']
  end

  def update_show(show, details)
    raar_request(:patch,
                 "admin/shows/#{show['id']}",
                 update_payload(show, details).to_json,
                 content_type: JSON_API_CONTENT_TYPE,
                 accept: JSON_API_CONTENT_TYPE,
                 authorization: "Token token=\"#{api_token}\"")
  end

  def update_payload(show, details)
    {
      data: {
        id: show['id'],
        type: show['type'],
        attributes: {
          details: details
        }
      }
    }
  end

  def same_title?(show, title)
    stem_title(show['attributes']['name']) == stem_title(title)
  end

  def stem_title(string)
    string.downcase.gsub(/[^a-z0-9]/, '')
  end

  def api_token
    @api_token ||= login_user.headers[:x_auth_token]
  end

  def login_user
    credentials = {
      username: settings['username'],
      password: settings['password']
    }
    raar_request(:post, 'login', credentials)
  end

  def raar_request(method, path, payload = nil, headers = {})
    RestClient::Request.execute(
      http_options.merge(
        method: method,
        payload: payload,
        url: "#{raar_url}/#{path}",
        headers: headers
      )
    )
  end

  def http_options
    @http_options ||=
      (settings['options'] || {})
      .each_with_object({}) do |(key, val), hash|
        hash[key.to_sym] = val
      end
  end

  def raar_url
    settings['url']
  end

end
