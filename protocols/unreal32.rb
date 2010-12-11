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

    def initialize
      @sendq = Queue.new

      @channelPrefixes = [ "#" ]

      @userModePrefixes = {
        "~" => :owner,
        "&" => :protected,
        "@" => :operator,
        "%" => :halfop,
        "+" => :voice
      }

      @userModes = {
        "A" => :server_admin,
        "a" => :services_admin,
        "B" => :bot,
        "C" => :co_admin,
        "d" => :deaf,
        "G" => :censored,
        "g" => :read_globops,
        "H" => :hidden_op,
        "h" => :help_op,
        "i" => :invisible,
        "N" => :network_administrator,
        "O" => :local_operator,
        "o" => :global_operator,
        "p" => :whois_hide,
        "q" => :no_kicks,
        "R" => :registered_privmsgs_only,
        "r" => :registered,
        "S" => :services_daemon,
        "s" => :read_server_notices,
        "T" => :no_ctcps,
        "t" => :using_vhost,
        "V" => :webtv_user,
        "v" => :read_dcc_rejection,
        "W" => :read_whois,
        "w" => :read_wallops,
        "x" => :hidden_hostname,
        "z" => :using_ssl
      }

      @operModes = [ "A", "a", "C", "N", "O", "o" ]

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
        "AA" => :sethost,
        "AL" => :chghost,
        "CHGHOST" => :chghost,


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
      host = Modulus.config.getOption('Network', 'link_address')
      port = Modulus.config.getOption('Network', 'link_port')
      bindAddr = Modulus.config.getOption('Network', 'bind_address')
      bindPort = Modulus.config.getOption('Network', 'bind_port')

      @socket = TCPSocket.new(host, port, bindAddr, bindPort)

      @socket.puts "PASS :#{Modulus.config.getOption('Network', 'link_password')}"

      @socket.puts "SERVER #{Modulus.config.getOption('Network', 'services_hostname')} 1 :#{Modulus.config.getOption('Network', 'services_name')}"
      #@socket.puts "SERVER #{Modulus.config.getOption('Network', 'services_hostname')} 1 :U2309-0 #{Modulus.config.getOption('Network', 'services_name')}"
      
      lastMsg = @socket.gets.chomp
      puts lastMsg
      unless lastMsg.include? "ESVID"
        $stderr.puts "Connection failed: Server does not support ESVID."
        exit -1
      end

      lastMsg = @socket.gets.chomp
      puts lastMsg
      unless lastMsg == "PASS :#{Modulus.config.getOption('Network', 'link_password')}"
        $stderr.puts "Connection failed: Server replied with incorrect password."
        exit -1
      end

      host = Modulus.config.getOption('Network', 'services_hostname')
      user = Modulus.config.getOption('Network', 'services_user')

      clients.each { |client|
        puts "#{client.nick}"
        @socket.puts "NICK #{client.nick} 0 #{Time.now.utc.to_i} #{user} #{host} #{host} #{Time.now.utc.to_i} +oS #{host} :#{client.realName}"
      }

      @socket.puts "PROTOCTL ESVID TOKEN SJ3 VHP UMODE2 CHANMODES NOQUIT"
      @socket.puts "ES"
      @socket.puts "AO 0 #{Time.now.utc.to_i} 0 * 0 0 0 :#{Modulus.config.getOption('Network', 'network_name')}"

      self.startSendThread
      return self.startRecvThread
    end

    def closeConnection(reason="Services is shutting down.")
      if @socket != nil
        $log.info "protocol-unreal32", "Closing connection: #{reason}"

        name = Modulus.config.getOption('Network', 'services_hostname')
        @socket.puts ":#{name} SQUIT #{name} :Services is shutting down."
      end
    end

    def parse(origin)
      case origin.type
        when :join
          arr = origin.message.split(" ")
          arr[2].split(",").each { |c|
            @parser.handleJoin(OriginInfo.new(origin.raw, origin.source, origin.cmd, c, :join))
          }
        when :privmsg
          @parser.handlePrivmsg(origin)
        when :notice
          @parser.handlePrivmsg(origin)
        when :nick
          @parser.handleNick(origin)
        when :sjoin
          @parser.handleJoin(OriginInfo.new(origin.raw, origin.message, origin.cmd, origin.arr[3], :join))
        else
          @parser.handleOther(origin)
      end
    end

    def createUser(origin)
      #TODO: Are we using NICKv2?
      # (We never do, despite asking for it. Annoying!)
      # &     nick   hopcount timestamp   username hostname   server                  servicestamp  :realname
      # NICK  Kabaka 1        1291720576  kabaka   localhost  draco.vacantminded.com  *             :kabaka
      # 0     1      2        3           4        5          6                       7             8
      User.new(origin.arr[1], origin.arr[7], origin.arr[5], origin.arr[5], origin.arr[3])
    end

    def isChannel?(str)
      @channelPrefixes.each { |prefix|
        return true if str.start_with? prefix
      }
      return false
    end

    def sendPong(origin)
      origin.arr[1][0] = "" if origin.arr[1].start_with? ":"

      if origin.arr.length == 2
        @sendq << "PONG #{Modulus.config.getOption('Network', 'services_hostname')} #{origin.arr[1]}"
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

      host = Modulus.config.getOption('Network', 'services_hostname')
      user = Modulus.config.getOption('Network', 'services_user')

      @sendq << "NICK #{nick} 1 #{Time.now.utc.to_i} #{user} #{host} #{host} * +oS * :#{realName}"
    end

    def sendKill(source, target, reason)
      @sendq << ":#{source} KILL #{target} :#{reason}"
    end

    def destroyClient(nick, reason="")
      @sendq << ":#{nick} QUIT :#{reason}"
    end

    def changeHostname(target, source, host)
      @sendq << ":#{source} CHGHOST #{target} #{host}"
    end

    def removeHostname(target, source)
      @sendq << ":#{source} SVSMODE #{target} -xt"
      @sendq << ":#{source} SVSMODE #{target} +x"
    end

    def svsmode(target, mode)
      @sendq << ":#{Modulus.config.getOption('Network', 'services_hostname')} n #{target } #{mode}"
    end

    def svs2mode(target, mode)
      @sendq << ":#{Modulus.config.getOption('Network', 'services_hostname')} v #{target } #{mode}"
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

    def channelMode(source, target, modeChanges, modeParams="")
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
