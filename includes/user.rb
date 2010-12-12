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

  class User

    attr_accessor :nick, :svid, :username, :hostname, :channels, :timestamp, :modes, :loggedIn, :vhost, :modes

    def initialize(nick, svid, username, hostname, timestamp)
      @nick = nick
      @svid = svid
      @username = username
      @hostname = hostname
      @timestamp = timestamp
      @modes = Array.new
      @vhost = ""
      if svid != '*'
        self.logIn(svid)
      else
        @loggedIn = false
      end
    end

    def logged_in?
      @loggedIn
    end

    def modes(modes)
      plus = true

      modes.each_char { |c|
        if c == "+"
          plus = true
        elsif c == "-"
          plus = false
        else
          if plus
            @modes << c
          else
            @modes.delete(c) if @modes.include? c
          end
        end
      }
      $log.debug 'user', "Updated modes for #{nick}: #{@modes.join(", ")}"
    end

    def logIn(username)
      $log.debug 'user', "User at nick #{@nick} has logged in as #{username}"
      @svid = username
      @loggedIn = true
      Modulus.events.event(:logged_in, self)
    end

    def is_oper?
      @modes.each { |mode|
        if Modulus.link.operModes.include? mode
          return true
        end      
      }
      return false
    end

    def is_services_admin?
      @modes.each { |mode|

        mode = Modulus.link.userModes[mode]
        if mode == :services_admin or mode == :network_admin or mode == :co_admin or mode == :server_admin
          return true
        end      
      }
      return false
    end

  end #class User
end #module Modulus
