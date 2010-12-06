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
          $log.warn 'parse', "Received unknown message type #{cmd} from server."
          puts "--> #{origin} sent unknown cmd #{cmd} (#{line})"
          return
        else

          line[0] = ""
          msg = ""
          if line.include? ":"
            splt = line.split(":")
            msg = splt[1..splt.length-1].join(" ")
          end

          origin = OriginInfo.new(line, origin, lineArr[2], msg, cmdName)
          #puts "--> #{origin} sent #{cmdName} (#{line})"
          puts "#{origin}"
        end
      else
        cmd = lineArr[0]
        cmdName = @cmdList[cmd]

        origin = OriginInfo.new(line, origin, lineArr[1], msg, cmdName)
        puts "#{origin}"
        #puts "->> unknown sent (#{line})"
      end

      if origin.type == :ping
        @services.link.sendPong(origin)
      end

      self.work(origin)
    end

    def work(origin)
      @services.runHooks(origin)

      if origin.message.length != 0

        if origin.type == :privmsg or origin.type == :notice
          # Could be a command!
          cmdOrigin = CommandOrigin.new(origin.raw, origin.source, origin.target, origin.message, origin.type)

          @services.runCmds(cmdOrigin)     
        end
      end
              
      if origin.type == :kill and @services.clients.isMyClient? origin.target
        # We check if this client is ours during connect, so this is fine.
        @services.link.sendKill(@services.hostname, origin.target, "Nick collision with services.")
      end
    end

  end #class 

end #module Modulus
