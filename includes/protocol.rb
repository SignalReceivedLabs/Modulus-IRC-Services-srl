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

  class ProtocolAbstractionMixin

    attr_reader :userModePrefixes, :channelPrefixes

    def startRecvThread
      @readThread = Thread.new {

        #while not @services.quitting
        # TODO: Reconnections!

          $log.debug "protocol", "Socket reader thread started."
          @parser = Modulus::Parser.new(@cmdList, @services)

          while line = @socket.gets
            #TODO: Parse this, hand it off to something else.
            #puts "<-- #{line}"
            @parser.parse line
          end

          $log.info "protocol", "Connection to the server has been lost."

        #end

        $log.debug "protocol", "Socket reader thread ending."

      }
    end

    def startSendThread
      @sendThread = Thread.new {

        $log.debug "protocol", "Socket send thread started."

        while str = @sendq.pop
          puts "SENT --> #{str}"
          @socket.puts str
          sleep 0.001 # Let other threads work. This is horrible, I know. It's temporary!
        end

        $log.debug "protocol", "Socket send thread stopping."
      }

    end
  end #class ProtocolAbstraction

end #module Modululs
