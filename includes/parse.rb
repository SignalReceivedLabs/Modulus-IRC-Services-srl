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

  class Parser

    def initialize(cmdList, services)
      @cmdList = cmdList
      @services = services
    end

    def parse(line)

      line = line.strip

      # No sense in parsing an empty line.
      return if line.length == 0

      origin = ""
      cmd = ""
      lineArr = line.split(" ")

      if line[0] == ":"
        # First bit is going to be a source of some kind!
        origin = lineArr[0][1..lineArr[0].length-1]
        cmd = lineArr[1]
        cmdName = @cmdList[cmd]

        if cmdName == nil
          $log.warning 'parse', "Received unknown message type #{cmd} from server."
          puts "--> #{origin} sent unknown cmd #{cmd} (#{line})"
          return
        else

          line[0] = ""
          msg = ""
          if line.include? ":"
            splt = line.split(":")
            msg = splt[1..splt.length-1].join(" ")
          else
            msg = line
          end

          origin = OriginInfo.new(line, origin, lineArr[2], msg, cmdName)
          #puts "--> #{origin} sent #{cmdName} (#{line})"
        end
      else
        cmd = lineArr[0]
        cmdName = @cmdList[cmd]

        origin = OriginInfo.new(line, origin, lineArr[1], cmd, cmdName)
        #puts "->> unknown sent (#{line})"
      end

      if origin.type == :ping
        @services.link.sendPong(origin)
      end

      puts "#{origin}"
      @services.link.parse(origin)
    end

    def work(origin)
      $log.debug 'parser', "Doing work on #{origin}"
      @services.runHooks(origin)
    end

    def handleNick(origin)
      # Have the protocol handler figure out how to make it a user object since
      # nobody follows 2813 just right.
      # TODO: Move part of this to protocol handler
      if origin.arr.length == 4
        #nick cahnge
        @services.users.changeNick(origin.source, origin.arr[2], origin.arr[3])
      else
        user = @services.link.createUser(origin)
        $log.debug "parser", "Added user #{user.nick}!#{user.username}@#{user.hostname} (#{user.svid} / #{user.timestamp}) after receiving NICK."

        # Add the user to whatever this is.
        @services.users.addUser(user)
      end

      self.work(origin)
    end

    def handleKill(origin)
      if @services.clients.isMyClient? origin.target
        @services.clients.connect origin.target
      else
        @services.users.delete origin.target
      end

      self.work(origin)
    end

    def handleKick(origin)
      self.handleOther origin
    end
    
    def handlePrivmsg(origin)
      @services.runCmds(origin)
      self.handleOther origin
    end

    def handleNotice(origin)
      @services.runCmds(origin)
      self.handleOther origin
    end

    def handleQuit(origin)
      @services.users.delete origin.target
      self.work(origin)
    end

    def handleJoin(origin)
      $log.debug "parser", "Handling join for #{origin.source} -> #{origin.message}"
      self.handleOther origin
    end

    def handlePart(origin)
      self.handleOther origin

    end

    def handleMode(origin)
      self.handleOther origin

    end

    def handleServer(origin)
      self.handleOther origin

    end

    def handleServerQuit(origin)
      self.handleOther origin

    end

    def handleOther(origin)
      self.work(origin)
    end

  end #class 

end #module Modulus
