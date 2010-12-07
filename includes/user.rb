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

    attr_accessor :nick, :svid, :username, :hostname, :channels, :timestamp, :modes, :loggedIn

    def initialize(nick, svid, username, hostname, timestamp)
      @nick = nick
      @svid = svid
      @username = username
      @hostname = hostname
      @timestamp = timestamp
      @modes = Array.new
      @loggedIn = (svid != '*')
    end

    def loggedIn?
      @loggedIn
    end

  end #class User
end #module Modulus
