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

  class Pseudoclient

    attr_reader :nick, :realName, :services

    def initialize(parent, nick, realName)
      @services = parent
      @nick = nick
      @realName = realName
      @channels = Array.new
    end

    def joinLogChan
      logChan = @services.config.getOption("Core", "log_channel")

      if logChan != nil
        self.addChannel logChan
      end
    end

    def addChannel(channel)
      @channels << channel
      @services.link.joinChannel(@nick, channel)
    end

    def removeChannel(channel)
      @channels.delete channel
      @services.link.partChannel(@nick, channel)
    end

    def joinAllChannels
      @channels.each { |c|
        @services.link.joinChannel(@nick, c)
      }
    end

    def connect
      @services.link.createClient(@nick, @realName)
    end

    def disconnect(reason="")
      @services.link.destroyClient(@nick, reason)
    end

  end #class Pseudoclient

end #module Modulus
