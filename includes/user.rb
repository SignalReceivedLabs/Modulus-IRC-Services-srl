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

    def initialize(services, nick, svid, username, hostname, timestamp)
      @services = services
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

    def loggedIn?
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
      @services.events.event(:logged_in, self)
    end

  end #class User
end #module Modulus
