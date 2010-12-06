#    Modulus IRC Services
#    Copyright (C) 2010  Modulus IRC Services Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

module Modulus

  class Log

    require 'logger'

    DISABLED = -1
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
    FATAL = 4

    def initialize(services, config)
      @services = services

      logdir = config.getOption('Core', 'log_location')
      @logChannel = config.getOption('Core', 'log_channel')

      @chatVerbosity = self.verbToNum(config.getOption('Core', 'log_channel_verbosity')) # Logging to log chan

      unless Dir.exists? logdir
        begin    
          Dir.mkdir logdir
        rescue => e
          $stderr.puts "Fatal error: Cannot create log directory #{logdir}:"
          $stderr.puts "#{e}"
          $stderr.puts "#{e.backtrace}"
        end
      end
      @logger = Logger.new("./logs/services.log", config.getOption('Core', 'log_rotation_period'))
      self.setFileVerbosity(config.getOption('Core', 'log_verbosity')) # Logging to services.log

      self.info "logger", "Logging started."
    end

    def verbToNum(verbosity)
      case verbosity.downcase
        when "debug"
          return DEBUG
        when "info"
          return INFO
        when "warn"
          return WARN
        when "error"
          return ERROR
        when "fatal"
          return FATAL
      end
      return DISABLED
    end

    def setFileVerbosity(verbosity)
      case verbosity.downcase
        when "debug"
          @logger.sev_threshold = Logger::DEBUG
        when "info"
          @logger.sev_threshold = Logger::INFO
        when "warn"
          @logger.sev_threshold = Logger::WARN
        when "error"
          @logger.sev_threshold = Logger::ERROR
        when "fatal"
          @logger.sev_threshold = Logger::FATAL
      end
      @logger.sev_threshold = Logger::DEBUG
    end

    def logToChannel(severity, msg)
      return if @logChannel == nil or @services.link == nil

      if @chatVerbosity <= severity
        @services.link.sendPrivmsg("Global", @logChannel, msg)
      end
    end

    def debug(section, str)
      @logger.debug(section) { str }
      self.logToChannel(DEBUG, "DEBUG [#{section}] #{str}")
    end

    def info(section, str)
      @logger.info(section) { str }
      self.logToChannel(INFO, "INFO [#{section}] #{str}")
    end

    def warn(section, str)
      @logger.warn(section) { str }
      self.logToChannel(WARN, "WARNING [#{section}] #{str}")
    end

    def error(section, str)
      @logger.error(section) { str }
      self.logToChannel(ERROR, "ERROR [#{section}] #{str}")
    end

    def fatal(section, str)
      @logger.fatal(section) { str }
      self.logToChannel(FATAL, "FATAL [#{section}] #{str}")
    end

    def close
      @logger.close
    end

  end #class Logger

end #module Modulus
