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

  class Clients

    attr_reader :clients

    def initialize
      @clients = Hash.new
    end

    def addClient(nick, realName)
      @clients[nick] = Pseudoclient.new(nick, realName)
    end

    def getAll
      return @clients
    end

    def disconnectClients
      @clients.each { |client|
        client.disconnect
      }
    end

    def isMyClient?(nick)
      @clients.has_key? nick
    end

    def joinLogChan
      $log.debug "clients", "Sending all connected pseudoclients to the log channel, if it is configured."
      @clients.values.each { |client| client.joinLogChan }
    end

    def connectAll
      @clients.keys.each { |nick| self.connect(nick) }
    end

    def connect(nick)
      return false unless self.isMyClient? nick

      $log.debug "clients", "Attempting to connect #{nick}"
      @clients[nick].connect
      @clients[nick].joinAllChannels
      
    end

  end #class 

end #module Modulus
