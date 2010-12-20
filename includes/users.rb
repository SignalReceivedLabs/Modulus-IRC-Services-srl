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

  class Users

    def initialize
      @nicks = Hash.new # Nick => ESVID
      @users = Hash.new # ESVID => User Object

      Modulus.events.register(:sethost, self, "on_set_host")
      Modulus.events.register(:mode, self, "on_mode")
    end

    def addUser(user)
      if @nicks.has_key? user.nick
        $log.warning 'users', "Duplicate nick being added to internal list: #{user.nick}. Overwriting."
      end

      if @users.has_key? user.svid
        $log.warning 'users', "Duplicate SVID being added to internal list: #{user.svid}. Overwriting."
      end

      @nicks[user.nick] = user.svid
      @users[user.svid] = user
    end

    def on_set_host(origin)
      origin = origin[0]
      user = self.find(origin.source)
      user.vhost = origin.target
    end

    def on_mode(origin)
      origin = origin[0]
      return if Modulus.link.isChannel? origin.target

      $log.debug 'users', "Doing modes for #{origin.target}"

      user = self.find(origin.target)
      return if user == nil

      user.modes(origin.message)
    end

    def logIn(ind, svid)
      #TODO: Make sure the network supports ESVID
      user = self.find(ind)
      user.svid = svid
      user.loggedIn = true
    end

    def logOut(ind)
      #TODO: Make sure the network supports ESVID
      user = self.find(ind)
      user.svid = '*'
      user.loggedIn = false
    end

    def changeNick(ind, newNick, newTimestamp)
      user = self.find(ind)

      if user == nil
        $log.error "user", "While performing a nick change, user #{ind} could not be found."
        return
      end

      user.nick = newNick
      user.timestamp = newTimestamp
    end

    def changeUsername(ind, newUser)
      user = self.find(ind)
      user.username = newUser
    end

    def changeHostname(ind, newHost)
      user = self.find(ind)
      user.hostname = newHost
    end

    def changeModes(ind, newModes)
      user = self.find(ind)
      user.modes = newModes
    end

    def changeSVID(ind, newSVID)
      user = self.find(ind)
      user.svid = newSVID
    end

    def find(ind)
      if @nicks.has_key? ind
        self.findByNick(ind)
      else
        self.findBySVID(ind)
      end
    end

    def findByNick(nick)
      @users[@nicks[nick]]
    end

    def findBySVID(svid)
      @users[svid]
    end

    def delete(ind)
      if @nicks.has_key? ind
        self.delByNick(ind)
      else
        self.delBySVID(ind)
      end
    end

    def delBySVID(svid)
      @nicks.delete @users[svid].nick
      @users.delete svid
    end

    def delByNick(nick)
      @users.delete @nicks[nick]
      @nicks.delete nick
    end

  end #class Users

end #module Modulus
