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

  class OriginInfo

    attr_reader :raw, :source, :target, :message, :cmd, :type, :arr, :args, :argsArr

    def initialize(raw, source, target, message, type)
      @raw = raw
      @source = source
      @target = target
      @type = type
      @message = message
      @arr = raw.split(" ")
      @messageArr = message.split(" ")
      @cmd = @messageArr[0].upcase
      @argsArr = @messageArr[1..@messageArr.length-1]
      @args = @argsArr.join(" ")
    end

    def to_s
      "[#{@type}] #{@source} -> #{@target} [#{@raw}] :#{@message}"
    end

  end #class OriginInfo

end #module Modulus
