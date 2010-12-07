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

  class Events
    
    def initialize
      @events = Hash.new
    end

    def register(event, sender, func)
      $log.debug 'events', "#{sender.class}.#{func} registered for event: #{event}"
      @events[event] = Array.new unless @events.has_key? event

      @events[event] << EventCallback.new(sender, func)
    end

    def event(event, *args)
      if @events.has_key? event
        $log.debug 'events', "Event fired: #{event}"
        @events[event].each { |c| c.run(args) }
      else
        $log.warning 'events', "Attempted to fire event with no recipients: #{event}"
      end
    end

  end #class EVents

  class EventCallback
    attr_reader :obj, :func
    
    def initialize(obj, func)
      @obj = obj
      @func = func
    end

    def run(args)
      eval ("@obj.#{@func}#{"(#{args})" unless args.length == 0}")
    end
  end #class EventCallback

end #module Modulus
