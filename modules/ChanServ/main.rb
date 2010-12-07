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
                     "Register the specified channel.")

      services.addCmd(self, "ChanServ", "DROP", "cmd_cs_drop",
                     "Drop the registration for the specified channel.")

      services.addCmd(self, "ChanServ", "LIST", "cmd_cs_list",
                     "List all channels registered to your services account.")

      services.addCmd(self, "ChanServ", "JOIN", "cmd_cs_join",
                     "Force ChanServ to join the specified channel.")
    end

    def cmd_cs_join(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        @services.reply(origin, "ChanServ", "Usage: JOIN channel")
      else
        @services.link.joinChannel("ChanServ", origin.args)
        @services.reply(origin, "ChanServ", "I have joined #{origin.args}.")
      end
    end

    def cmd_cs_list(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"
      
      user = @services.users.find(origin.source)

      unless user.loggedIn?
        @services.reply(origin, "ChanServ", "You must be logged in to a services account in order to use this command.")
        return
      end

      channels = Channel.find_all_by_owner_id(Account.find_by_email(user.svid))

      if channels.length != 0
      
        @services.reply(origin, "ChanServ", "Channels registered to #{user.svid}:")
        @services.reply(origin, "ChanServ", sprintf("%30.30s  %-25.25s", "Channel", "Date Registered"))

        channels.each { |channel|
          @services.reply(origin, "ChanServ", sprintf("%30.30s  %-25.25s", channel.name, channel.dateRegistered))
        }

        @services.reply(origin, "ChanServ", "Total channels registered: #{channels.length}.")
      else
        @services.reply(origin, "ChanServ", "There are currently no channels registered to #{user.svid}.")
      end
    end

    def cmd_cs_register(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        @services.reply(origin, "ChanServ", "Usage: REGISTER channel")
      else
        user = @services.users.find(origin.source)

        unless user.loggedIn?
          @services.reply(origin, "ChanServ", "You must be logged in to a services account in order to register a channel.")
          return
        end

        if Channel.find_by_name(origin.args)
          @services.reply(origin, "ChanServ", "The channel #{origin.args} is already registered.")
        else

          account = Account.find_by_email(user.svid)

          Channel.create(
            :name => origin.args,
            :owner_id => account.id,
            :dateRegistered => DateTime.now)

          @services.clients.clients["ChanServ"].addChannel(origin.args)
          @services.reply(origin, "ChanServ", "You have registered #{origin.args}.")
        end
      end
    end

    def cmd_cs_drop(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 2
        @services.reply(origin, "ChanServ", "Usage: DROP channel password")
      else
        channel = Channel.find_by_name(origin.argsArr[0])
        channel.destroy

        @services.clients.clients["ChanServ"].removeChannel(origin.argsArr[0])
        @services.reply(origin, "ChanServ", "You have dropped the registration for #{origin.argsArr[0]}.")
        $log.info 'ChanServ', "#{origin.source} has dropped the registration for #{origin.argsArr[0]}."
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
        #@services.link.joinChannel("ChanServ", c.name)
        @services.clients.clients["ChanServ"].addChannel(c.name)
      }
    end

    class Channel < ActiveRecord::Base
    #  belongs_to :user
    end

  end #class 

end #module Modulus
