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

      services.addService("ChanServ", self,
                         "Channel Registration Services
                         
                         ChanServ allows users to register channels, maintain
                         channel settings, and maintain channel operator lists.")

      services.clients.addClient(@services, "ChanServ", "Channel Registration Service")

      #services.addHook(self, "cmd_cs_join", :privmsg)
      #services.addMessageHook(self, "cmd_cs_join", :privmsg, "ChanServ")
      services.addCmd(self, "ChanServ", "JOIN", "cmd_cs_join",
                     "Force ChanServ to join the specified channel.")
    end

    def cmd_cs_join(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.args.length == 0
        @services.reply(origin, "ChanServ", "Usage: JOIN channel")
      else
        @services.link.joinChannel("ChanServ", origin.args)
        @services.reply(origin, "ChanServ", "I have joined #{origin.args}.")
      end
    end

  end #class 

end #module Modulus
