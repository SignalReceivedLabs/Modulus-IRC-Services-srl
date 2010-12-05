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

  class Config

    def initialize(fileName = "services.conf")
      unless File.exists? fileName
        $stderr.puts "Fatal error: Configuration file does not exist at #{fileName}"
        exit -1
      end

      @configuration = Hash.new
      section = nil

      configFile = File.new(fileName, "r")
      
      while(line = configFile.gets)
        line = line.strip

        next if line[0] == "#" or line.length == 0
        
        if line =~ /\[(.+)\]/
          section = $1
          if @configuration.has_key? section
            $stderr.puts "Warning: Duplicate configuration sections found in #{fileName}"
          else
            @configuration[section] = Hash.new
          end
        else
          begin
            lineArr = line.split("=")

            next if lineArr[0] == nil

            if lineArr[1] == nil
              @configuration[section][lineArr[0].strip] = nil
            else
              @configuration[section][lineArr[0].strip] = lineArr[1].strip
            end

          rescue => e
              $stderr.puts "Fatal error while reading configuration file #{fileName}:"
              $stderr.puts "#{e}"
              $stderr.puts "#{e.backtrace}"
              configFile.close
              exit -1
          end

        end
      end

      configFile.close

      if @configuration.has_key? "NoLoad"
        if @configuration["NoLoad"]["do_not_start"] == "yes"
          $stderr.puts "Fatal error: The do_not_start option is enabled. Read the *entire* configuration file before starting services!"
          exit -1
        end
      end

      #puts @configuration.to_s
      return true
    end

    def getBool(section, key)
      opt = self.getOption(section,key)
      return (opt == "yes" or opt == "on" or opt == "true")
    end

    def getOption(section, key)
      if @configuration.has_key? section
        return @configuration[section][key]
      end
      return nil
    end

  end # class Config

end # module Modulus
