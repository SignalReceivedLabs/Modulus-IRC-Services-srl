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

  class Channels

    attr_reader :channels

    def initialize
      @channels = Hash.new
      Modulus.events.register(:join, self, "on_join")
      Modulus.events.register(:mode, self, "on_mode")
    end

    def on_join(origin)
      origin = origin[0]

      unless @channels.has_key? origin.message
        @channels[origin.message] = Channel.new(origin.message)
      end

      @channels[origin.message].join origin.source
    end

    def on_mode(origin)
      origin = origin[0]
      return unless Modulus.link.isChannel? origin.target

      if @channels.has_key? origin.target
        last = (origin.arr.length == 5 ? 4 : origin.arr.length - 1)
        $log.debug 'channels', "Last position for parameters: #{last} Length: #{origin.arr.length} Origin: #{origin}"
        @channels[origin.target].modes(origin.arr[3], origin.arr[4..last])
      end
    end

    def is_op?(nick, channel)
      if @channels.has_key? channel
        return @channels[channel].is_op? nick
      end

      return false
    end

  end #class 

end #module Modulus
