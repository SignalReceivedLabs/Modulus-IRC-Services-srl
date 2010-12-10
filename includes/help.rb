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

  class Services

    def sendHelp(origin, command)
      return unless @cmdHooks.has_key? origin.target
      return unless @cmdHooks[origin.target].has_key? command

      shortHelp = @cmdHooks[origin.target][command].shortDesc
      longHelp = @cmdHooks[origin.target][command].longDesc

      self.reply(origin, "#{command}  #{shortHelp}")
      self.reply(origin, " ")
      self.reply(origin, longHelp)
    end

    def sendHelpList(origin)
      return unless @cmdHooks.has_key? origin.target
      return unless @serviceModules.modules.has_key? origin.target

      self.reply(origin, @serviceModules.modules[origin.target].description)
      self.reply(origin, " ")

      @cmdHooks[origin.target].values.each { |cmd|
        self.reply(origin, sprintf("  %15.15s  %s", cmd.commandText, cmd.shortDesc))
      }
      self.reply(origin, " ")
      self.reply(origin, "Use HELP COMMAND for more information on a specific command, if available.")
    end

    def doHelp(origin)
      origin = origin[0]
      return unless origin.type == :privmsg or origin.type == :notice
      
      return unless origin.message.upcase.start_with? "HELP"

      arr = origin.message.upcase.split(" ")
      if arr.length == 1
        sendHelpList(origin)
      else
        sendHelp(origin, arr[1])
      end
    end

  end #class  Help

end #module Modulus
