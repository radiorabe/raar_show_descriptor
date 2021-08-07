require 'yaml'
require 'json'
require 'syslog/logger'

require_relative 'description'
require_relative 'raar_client'
require_relative 'website_client'

class Importer

  def run
    website_client.show_links.each do |link|
      handle_link(link)
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    logger.fatal("#{e}\n#{e.backtrace.join("\n")}")
  end

  private

  def handle_link(link)
    show = raar_client.fetch_show(link.text)
    if show
      handle_show(show, link)
    else
      logger.info("No show with name '#{link.text}' found")
    end
  end

  def handle_show(show, link)
    if should_update_description?(show)
      update_description(show, link)
    else
      logger.debug("Kept description for show #{link.text}")
    end
  end

  def should_update_description?(show)
    settings.dig('importer', 'overwrite') ||
      show['attributes']['details'].to_s.strip.empty?
  end

  def update_description(show, link)
    description = fetch_description(link)
    if description.present?
      if description.body != show['attributes']['details']
        raar_client.update_description(show, description)
        logger.info("Updated description for show #{link.text}")
      else
        logger.debug("Unchanged description for show #{link.text}")
      end
    else
      logger.debug("No description found for show #{link.text}")
    end
  end

  def fetch_description(link)
    # logger.debug("Fetching description for show #{link.text}")
    website_client.fetch_show_description(link)
  end

  def website_client
    @website_client ||= WebsiteClient.new(settings['scraper'], logger)
  end

  def raar_client
    @raar_client ||= RaarClient.new(settings['raar'], logger)
  end

  def settings
    @settings ||= YAML.safe_load(File.read(settings_file))
  end

  def settings_file
    File.join(File.join(__dir__), '..', 'config', 'settings.yml')
  end

  def logger
    @logger ||= create_logger.tap do |logger|
      level = settings.dig('importer', 'log_level') || 'info'
      logger.level = Logger.const_get(level.upcase)
    end
  end

  def create_logger
    if settings.dig('importer', 'log') == 'syslog'
      Syslog::Logger.new('raar-show-descriptor')
    else
      Logger.new(STDOUT)
    end
  end

end
