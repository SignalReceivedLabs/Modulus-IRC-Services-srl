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
        line = line.chomp

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
              @configuration[section][lineArr[0].chomp] = nil
            else
              @configuration[section][lineArr[0].chomp] = lineArr[1].chomp
            end

          rescue => e
              $stderr.puts "Fatal error while reading configuration file #{fileName}:"
              $stderr.puts "#{e}"
              $stderr.puts "#{e.backtrace}"
              exit -1
          end

        end
      end

      configFile.close

      puts @configuration.to_s

    end

  end # class Config

end # module Modulus
