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

  class Channel

    attr_reader :name, :topic, :modes, :bans, :nicks

    def initialize(name)
      @name = name
      @topic = ""
      @modes = Hash.new
      @bans = Array.new
      @users = Hash.new
    end

    def join(nick)
      @users[nick] = ChannelUser.new(nick)
      $log.debug 'channel', "User #{nick} has joined #{@name}."
    end

    def topic(topic)
      @topic = topic
    end

    def modes(modes, params)
      plus = true

      paramModes = Array.new

      pos = 0

      modes.each_char { |c|
        if c == "+"
          plus = true
        elsif c == "-"
          plus = false
        else
          if Modulus.link.channelUserModes.has_key? c
            if @users.has_key? params[pos]
              @users[params[pos]].modeChange(plus, Modulus.link.channelUserModes[c])
              $log.debug 'channel', "params: #{params} paramModes: #{paramModes}"
            else
              $log.warning 'channel', "Could not find nick #{params[pos]} in channel user list for #{@name} when doing mode change."
            end
            pos += 1
          elsif Modulus.link.channelModes.has_key? c
            if Modulus.link.channelModes[c]
              param = params[pos]
              pos += 1
            else
              param = nil
            end

            $log.debug 'channel', "mode key: #{c} mode value: #{param}"

            if plus
              @modes[c] = param
            else
              @modes.delete(c) if @modes.has_key? c
            end
          end
        end
      }

      $log.debug 'channel', "Updated modes for #{@name}"
    end

    def is_op?(nick)
      if @users.has_key? nick
        modes = @users[nick].modes
        return (modes.include? :op or modes.include? :protected or modes.include? :owner)
      end

      return false
    end


  end #class Channel

end #module Modulus
