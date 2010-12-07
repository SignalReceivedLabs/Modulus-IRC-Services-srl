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

    def logIn(ind, svid)
      #TODO: Make sure the network supports ESVID
      user = self.find(ind)
      user.svid = svid
      user.loggedIn = true
      self.updateUser(ind, user)
    end

    def changeNick(ind, newNick)
      user = self.find(ind)
      user.nick = newNick
      self.updateUser(ind, user)
    end

    def changeUsername(ind, newUser)
      user = self.find(ind)
      user.username = newUser
      self.updateUser(ind, user)
    end

    def changeHostname(ind, newHost)
      user = self.find(ind)
      user.hostname = newHost
      self.updateUser(ind, user)
    end

    def changeModes(ind, newModes)
      user = self.find(ind)
      user.modes = newModes
      self.updateUser(ind, user)
    end

    def changeTimestamp(ind, newTimestamp)
      user = self.find(ind)
      user.timestamp = newTimestamp
      self.updateUser(ind, user)
    end

    def changeSVID(ind, newSVID)
      user = self.find(ind)
      user.svid = newSVID
      self.updateUser(ind, user)
    end

    def updateUser(ind, new)
      self.del(ind)
      self.addUser(new)
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
