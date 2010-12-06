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

  class ChanServ

    def initialize(services)
      @services = services

      services.addService("ChanServ", self,
                         "Channel Registration Services
                         
                         ChanServ allows users to register channels, maintain
                         channel settings, and maintain channel operator lists.")

      services.events.register(:database_connected, self, "dbConnected")

      services.clients.addClient(@services, "ChanServ", "Channel Registration Service")

      services.addCmd(self, "ChanServ", "REGISTER", "cmd_cs_register",
                     "Register the specified channel")

      services.addCmd(self, "ChanServ", "JOIN", "cmd_cs_join",
                     "Force ChanServ to join the specified channel.")
    end

    def cmd_cs_join(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.args.length == 0
        @services.reply(origin, "ChanServ", "Usage: JOIN channel")
      else
        @services.link.joinChannel("ChanServ", origin.args)
        @services.reply(origin, "ChanServ", "I have joined #{origin.args}.")
      end
    end

    def cmd_cs_register(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.args.length == 0
        @services.reply(origin, "ChanServ", "Usage: REGISTER channel")
      else
        if Channel.find_by_name(origin.args)
          @services.reply(origin, "ChanServ", "The channel #{origin.args} is already registered.")
        else
          Channel.create(
            :name => origin.args,
            :dateRegistered => DateTime.now,
            :note => "Test Channel")

          @services.link.joinChannel("ChanServ", origin.args)
          @services.reply(origin, "ChanServ", "You have registered #{origin.args}.")
        end
      end
    end

    def dbConnected
      $log.debug "ChanServ", "Received database_connected callback. Beginning database check."

      unless Channel.table_exists?
        ActiveRecord::Schema.define do
          create_table :channels do |t|
            t.column :owner_id, :integer
            t.column :name, :string, :null => false
            t.column :lastTopic, :string
            t.column :dateRegistered, :datetime, :null => false
            t.column :dateLastActive, :datetime
            t.column :heir, :integer
            t.column :note, :text
          end
        end
      end

      joinRegistered
      
    end

    def joinRegistered
      Channel.find(:all).each { |c|
        @services.link.joinChannel("ChanServ", c.name)
      }
    end

    class Channel < ActiveRecord::Base
    #  belongs_to :user
    end

  end #class 

end #module Modulus
