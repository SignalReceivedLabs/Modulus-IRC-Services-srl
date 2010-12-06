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

  class ProtocolAbstraction < ProtocolAbstractionMixin

    require 'socket'

    def initialize(config, parent)
      @parent = parent
      @config = config
      @sendq = Queue.new

      @cmdList = {

        # Server Commands

        "8" => :ping,
        "PING" => :ping,
        "9" => :pong,
        "PONG" => :ping,

        "PASS" => :pass,
        "PROTOCTL" => :protoctl,
        "SERVER" => :server,
        "ES" => :endOfSync,
        "EOS" => :endOfSync,
        "NETINFO" => :netInfo,
        "AO" => :netInfo,
        "&" => :nick,
        "NICK" => :nick,

        "," => :quit,
        "QUIT" => :quit,

        "~" => :sjoin,
        "SJOIN" => :sjoin,
        "AP" => :sendumode,
        "SENDUMODE" => :sendumode,
        "AU" => :smo,
        "SMO" => :smo,
        "Ss" => :sendsno,
        "SENDSNO" => :sendsno,
        "TKL" => :tkl,
        "BD" => :tkl,
        "KILL" => :kill,
        "SETHOST" => :sethost,
        "SWHOIS" => :swhois,

        "#" => :whois,
        "WHOIS" => :whois,

        # Channel Commands

        "C" => :join,
        "JOIN" => :join,
        "D" => :part,
        "PART" => :part,

        "H" => :kick,
        "KICK" => :kick,
        "G" => :mode,
        "MODE" => :mode,
        "*" => :channelInvite,
        "INVITE" => :channelInvite,
        "AX" => :sajoin,
        "SAJOIN" => :sajoin,
        "AY" => :sapart,
        "SAPART" => :sapart,
        "o" => :samode,
        "SAMODE" => :samode,
        ")" => :topic,
        "TOPIC" => :topic,

        # Services Commands

        "h" => :svskill,
        "SVSKILL" => :svskill,
        "n" => :svsmode,
        "SVSMODE" => :svsmode,
        "v" => :svs2mode,
        "SVS2MODE" => :svs2mode,
        "BV" => :svssno,
        "SVSSNO" => :svssno,
        "BW" => :svs2sno,
        "SVS2SNO" => :svs2sno,
        "e" => :svsnick,
        "SVSNICK" => :svsnick,
        "BX" => :svsjoin,
        "SVSJOIN" => :svsjoin,
        "BT" => :svspart,
        "SVSPART" => :svspart,
        "BB" => :svso,
        "SVSO" => :svso,
        "f" => :svsnoop,
        "SVSNOOP" => :svsnoop,
        "BR" => :svsnline,
        "SVSNLINE" => :svsnline,
        "BC" => :svsfline,
        "SVSFLINE" => :svsfline,

        # Chat Commands

        "!" => :privmsg,
        "PRIVMSG" => :privmsg,
        "B" => :notice,
        "NOTICE" => :notice,
        "p" => :chatops,
        "CHATOPS" => :chatops,
        "=" => :wallops,
        "WALLOPS" => :wallops,
        "]" => :globops,
        "GLOBOPS" => :globops,
        "x" => :adchat,
        "ADCHAT" => :adchat,
        "AC" => :nachat,
        "NACHAT" => :nachat,

        # TKL Commands

        "c" => :sqline,
        "SQLINE" => :sqline,
        "d" => :unsqline,
        "UNSQLINE" => :unsqline
      }
    end

    def connect(clients)
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

      host = @config.getOption('Network', 'services_hostname')
      user = @config.getOption('Network', 'services_user')

      clients.each { |client|
        puts "#{client.nick}"
        @socket.puts "NICK #{client.nick} 0 #{Time.now.utc.to_i} #{user} #{host} #{host} #{Time.now.utc.to_i} +oS #{host} :#{client.realName}"
      }

      @socket.puts "PROTOCTL ESVID NICKv2 TOKEN NICKIP SJ3 VHP UMODE2 CHANMODES CLK NOQUIT"
      @socket.puts "ES"
      @socket.puts "AO 0 #{Time.now.utc.to_i} 0 * 0 0 0 :#{@config.getOption('Network', 'network_name')}"

      self.startSendThread
      return self.startRecvThread
    end

    def closeConnection(reason="Services is shutting down.")
      if @socket != nil
        $log.info "protocol-unreal32", "Closing connection: #{reason}"

        name = @config.getOption('Network', 'services_hostname')
        @socket.puts ":#{name} SQUIT #{name} :Services is shutting down."
      end
    end

    def sendPong(origin)
      origin.arr[1][0] = "" if origin.arr[1].start_with? ":"

      if origin.arr.length == 2
        @sendq << "PONG #{@config.getOption('Network', 'services_hostname')} #{origin.arr[1]}"
      else
        @sendq << "PONG #{origin.arr[2]} #{origin.arr[1]}"
      end
    end

    def sendPrivmsg(source, target, str)
      @sendq << ":#{source} ! #{target} :#{str}"
    end

    def sendNotice(source, target, str)
      @sendq << ":#{source} NOTICE #{target} :#{str}"
    end

    def createClient(nick, realName)
      #@sendq << ":#{nick} SVSKILL #{nick} :Collision with services."

      host = @config.getOption('Network', 'services_hostname')
      user = @config.getOption('Network', 'services_user')

      @sendq << "NICK #{nick} 1 #{Time.now.utc.to_i} #{user} #{host} #{host} * +oS * :#{realName}"
    end

    def sendKill(source, target, reason)
      @sendq << ":#{source} KILL #{target} :#{reason}"
    end

    def destroyClient(nick, reason="")
      @sendq << ":#{nick} QUIT :#{reason}"
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
