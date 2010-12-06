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

  class ChanServ

    def initialize(services)
      @services = services

      services.addService("ChanServ", self)

      services.clients.addClient(@services, "ChanServ", "Channel Registration Service")

      #services.addHook(self, "cmd_cs_join", :privmsg)
      services.addMessageHook(self, "cmd_cs_join", :privmsg, "ChanServ")
    end

    def cmd_cs_join(origin)
      $log.debug "ChanServ", "Got: #{origin.message}"
      @services.link.joinChannel("ChanServ", origin.message)
    end

  end #class 

end #module Modulus
