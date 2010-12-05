#    Modulus IRC Services
#    Copyright (C) 2010  Modulus IRC Services Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

module Modulus

  class ProtocolAbstraction

    require 'socket'

    def initialize(config)
      @config = config
      @sendq = Queue.new

    end

    def connect
      $log.debug "protocol-unreal32", "Starting connection to IRC server."
      host = @config.getOption('Network', 'link_address')
      port = @config.getOption('Network', 'link_port')
      bindAddr = @config.getOption('Network', 'bind_address')
      bindPort = @config.getOption('Network', 'bind_port')

      @socket = TCPSocket.new(host, port, bindAddr, bindPort)

      @socket.puts "PASS :#{@config.getOption('Network', 'link_password')}"

      @socket.puts "SERVER #{@config.getOption('Network', 'services_hostname')} 1 :#{@config.getOption('Network', 'services_name')}"
      #@socket.puts "SERVER #{@config.getOption('Network', 'services_hostname')} 1 :U2309-0 #{@config.getOption('Network', 'services_name')}"
      
      unless @socket.gets.chomp.include? "ESVID"
        p lastMsg
        $stderr.puts "Connection failed: Server does not support ESVID."
        exit -1
      end

      unless @socket.gets.chomp == "PASS :#{@config.getOption('Network', 'link_password')}"
        p lastMsg
        $stderr.puts "Connection failed: Server replied with incorrect password."
        exit -1
      end

      @socket.puts "PROTOCTL ESVID NICKv2 TOKEN NICKIP SJ3 VHP UMODE2 CHANMODES CLK"
      @socket.puts "ES"
      @socket.puts "AO 0 #{Time.now.utc.to_i} 0 * 0 0 0 :#{@config.getOption('Network', 'network_name')}"

      self.startSendThread
      return self.startRecvThread
    end

    def startRecvThread
      @readThread = Thread.new {

        $log.debug "protocol-unreal32", "Socket reader thread started."

        while line = @socket.gets
            puts "<-- #{line}"
        end

        $log.debug "protocol-unreal32", "Socket reader thread ending."
      }
    end

    def startSendThread
      @sendThread = Thread.new {

        $log.debug "protocol-unreal32", "Socket send thread started."

        while str = @sendq.pop
          puts "--> #{str}"
          @socket.puts str
          sleep 0.001 # Let other threads work. This is horrible, I know. It's temporary!
        end

        $log.debug "protocol-unreal32", "Socket send thread stopping."

      }

    end

    def closeConnection
      if @socket != nil
        name = @config.getOption('Network', 'services_hostname')
        @socket.puts ":#{name} SQUIT #{name} :Services is shutting down."
      end
    end

    def sendPrivmsg(source, target, str)
      @sendq << ":#{source} ! #{target} :#{str}"
    end

    def sendNotice(source, target, str)
      @sendq << ":#{source} B #{target} :#{str}"
    end

    def createClient(nick, user, host)
      @sendq << "NICK #{nick} 0 0 #{user} #{host} #{@config.getOption('Network', 'services_hostname')} 0 +oS #{host} :#{@config.getOption('Network', 'services_name')}"
    end

    def joinChannel(nick, channel)
      @sendq << ":#{nick} C #{channel}"
      # Yeah, we're assigning ourselves +a on join in every case right now.
      # Should this be done separately?
      @sendq << ":#{nick} G #{channel} +a #{nick}"
    end

    def partChannel(nick, channel)
      @sendq << ":#{nick} D #{channel}"      
    end

    def channelKick(nick, channel, target, reason="")
      @sendq << ":#{nick} H #{channel} #{target} :#{reason}"
    end

    def channelMode(source, target, modeChanges, modeParams)
      @sendq << ":#{source} G #{target} #{modeChanges} #{modeParams}"
    end

    def channelInvite(source, target, channel)
      @sendq << ":#{source} * #{target} #{channel}"
    end

    def channelTopic(source, target, topic)
      @sendq << ":#{source} ) #{target} #{source} #{Time.now.utc.to_i} :#{topic}"
    end

    def forceChannelJoin(source, target, channel)
      @sendq << ":#{source} AX #{target} #{channel}"
    end

    def forceChannelPart(source, target, channel, reason=nil)
      @sendq << ":#{source} AY #{target} #{channel} #{":#{reason}" unless reason == nil}"
    end

    def forceChannelMode(source, target, modeChanges, modeParams)
      @sendq << ":#{source} o #{target} #{modeChanges} #{modeParams}"
    end
  end #class ProtocolAbstraction

end #module Modulus
