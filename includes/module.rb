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

  class Module

    attr_reader :name, :description, :author, :version

    def initialize(name, description, author, version)
      @name = name
      @description = description
      @author = author
      @version = version
      @commands = Hash.new
    end

    def addCommand(command, triggers)
      @commands[trigger] = Hash.new unless @commands.has_key? trigger

      triggers.each { |trigger|
        if @commands[trigger].has_key? command.commandText
          $log.warn 'module', "Command #{command.commandText} registered twice. Overwriting."
        end

        @comamands[trigger][command.commandText] = command
        $log.debug 'module', "Command #{command.commandText} added."
      }
    end

    def hasCommand?(command, trigger)
      if @commands.has_key? trigger
        return @commands[trigger].has_key? command
      end
      return false
    end

    def getCommand(command, trigger)
      if self.hasCommand? command, trigger
        return @commands[trigger][command]
      end
      return false
    end

  end #class 

end #module Modulus
