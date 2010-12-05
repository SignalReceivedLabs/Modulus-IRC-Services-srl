#    Modulus IRC Services
#    Copyright (C) 2010  Modulus IRC Services Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

module Modulus

  class Log

    require 'logger'

    def initialize(logdir, rotation)

      unless Dir.exists? logdir
        begin    
          Dir.mkdir logdir
        rescue => e
          $stderr.puts "Fatal error: Cannot create log directory #{logdir}:"
          $stderr.puts "#{e}"
          $stderr.puts "#{e.backtrace}"
        end
      end

      @logger = Logger.new("./logs/services.log", rotation)
    end

    def debug(section, str)
      @logger.debug(section) { str }
    end

    def info(section, str)
      @logger.info(section) { str }
    end

    def warn(section, str)
      @logger.warn(section) { str }
    end

    def error(section, str)
      @logger.error(section) { str }
    end

    def fatal(section, str)
      @logger.fatal(section) { str }
    end

    def close
      @logger.close
    end

  end #class Logger

end #module Modulus
