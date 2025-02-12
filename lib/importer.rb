require 'yaml'
require 'json'
require 'syslog/logger'

require_relative 'directus_show'
require_relative 'directus_client'
require_relative 'raar_client'

class Importer

  def run
    website_client.shows.each do |show|
      handle_show(show)
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    logger.fatal("#{e}\n#{e.backtrace.join("\n")}")
  end

  private

  def handle_show(show)
    raar_show = raar_client.fetch_show(show.name)
    if raar_show
      handle_raar_show(raar_show, show)
    else
      logger.info("No show with name '#{show.name}' found")
    end
  end

  def handle_raar_show(raar_show, show)
    if should_change_description?(raar_show)
      change_description(raar_show, show)
    else
      logger.debug("Kept description for show #{show.name}")
    end
  end

  def should_change_description?(raar_show)
    settings.dig('importer', 'overwrite') ||
      raar_show['attributes']['details'].to_s.strip.empty?
  end

  def change_description(raar_show, show)
    if show.description?
      update_description(raar_show, show)
    else
      logger.debug("No description found for show #{show.name}")
    end
  end

  def update_description(raar_show, show)
    previous = raar_show['attributes']['details']
    if show.description == previous
      logger.debug("Unchanged description for show #{show.name}")
    else
      dry_run = settings.dig('importer', 'dry_run')
      raar_client.update_description(raar_show, show.description) unless dry_run
      logger.info("#{dry_run ? "Would update" : "Updated"} description for show #{show.name}")
      logger.debug("- Before:\n#{previous}")
      logger.debug("- After:\n#{show.description}")
    end
  end

  def website_client
    @website_client ||= DirectusClient.new(settings['scraper'], logger)
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
      Syslog::Logger.new('raar-show-descriptor').tap do |logger|
        logger.formatter = proc { |severity, _datetime, _prog, msg|
          "#{Logger::SEV_LABEL[severity]} #{msg}"
        }
      end
    else
      Logger.new($stdout)
    end
  end

end
