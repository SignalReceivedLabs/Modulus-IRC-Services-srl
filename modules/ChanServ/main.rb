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

    def initialize
      Modulus.addService("ChanServ", self,
                         "Channel Registration Services
                         
ChanServ allows users to register channels, maintain
channel settings, and maintain channel operator lists.")

      Modulus.events.register(:database_connected, self, "dbConnected")
      Modulus.events.register(:done_connecting, self, "joinRegistered")
      Modulus.events.register(:join, self, "on_join")

      Modulus.clients.addClient("ChanServ", "Channel Registration Service")

      Modulus.addCmd(self, "ChanServ", "GRANT", "cmd_cs_grant",
                     "Grant user privileges for the specified channel.",
                     "Usage: GRANT channel nick permissions
 
To use this command, you must have appropriate channel permissions.
Additionally, the nick specified must be on-line and
logged in to a services account.
 
Supported permissions include:
 
VOICE - User gains or may acquire voice. (+v)
HALFOP - User gains or may acquire half-op status. (+h)
OP - User gains or may acquire channel operator status. (+o)
PROTECT - User gains or may acquire protected channel status. (+a)
OWNER - User gains or may acquire channel owner status. (+q)
        User may also perform any channel administration tasks.")

      Modulus.addCmd(self, "ChanServ", "REGISTER", "cmd_cs_register",
                     "Register the specified channel.",
                     "Usage: REGISTER channel password
 
ChanServ will automatically join all registered channels.
Registered channels get access to ChanServ's interactive features,
such as channel ban management, and channel operator and permissions
management. If your network supports it, external control may be
provided, such as through a web portal.")

      Modulus.addCmd(self, "ChanServ", "DROP", "cmd_cs_drop",
                     "Drop the registration for the specified channel.",
                     "Usage: DROP channel password
 
You must give your services account password to use this command.
 
Dropping a channel deletes all ChanServ data for the channel from
the services database. This action cannot be undone. If you want to
re-register a previously dropped channel, even if it just happened,
you must re-register it.")

      Modulus.addCmd(self, "ChanServ", "LIST", "cmd_cs_list",
                     "List all channels registered to your services account.",
                     "Usag: LIST
 
All channel registrations are connected to your services account.
Using this command, you can see a list of all channels that you have registered
while logged in to your account.")

      Modulus.addCmd(self, "ChanServ", "JOIN", "cmd_cs_join",
                     "Force ChanServ to join the specified channel.")
    end

    def cmd_cs_join(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: JOIN channel")
      else
        Modulus.joinChannel("ChanServ", origin.args)
        Modulus.reply(origin, "I have joined #{origin.args}.")
      end
    end

    def cmd_cs_list(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"
      
      user = Modulus.users.find(origin.source)

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      channels = Channel.find_all_by_owner_id(Account.find_by_username(user.svid))

      if channels.length != 0
      
        Modulus.reply(origin, "Channels registered to #{user.svid}:")
        Modulus.reply(origin, sprintf("%30.30s  %-25.25s", "Channel", "Date Registered"))

        channels.each { |channel|
          Modulus.reply(origin, sprintf("%30.30s  %-25.25s", channel.name, channel.dateRegistered))
        }

        Modulus.reply(origin, "Total channels registered: #{channels.length}.")
      else
        Modulus.reply(origin, "There are currently no channels registered to #{user.svid}.")
      end
    end

    def cmd_cs_register(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: REGISTER channel")
      else
        user = Modulus.users.find(origin.source)

        unless user.logged_in?
          Modulus.reply(origin, "You must be logged in to a services account in order to register a channel.")
          return
        end

        if Channel.find_by_name(origin.args)
          Modulus.reply(origin, "The channel #{origin.args} is already registered.")
        else

          account = Account.find_by_username(user.svid)

          if account == nil
            Modulus.reply(origin, "You must be logged in to a services account in order to register a channel.")
            return
          end

          channel = Channel.create(
            :name => origin.args,
            :owner_id => account.id,
            :dateRegistered => DateTime.now)

          ChannelUsers.create(
            :channel_id => channel.id,
            :account_id => account.id,
            :access => "OWN")

          self.join origin.args

          Modulus.reply(origin, "You have registered #{origin.args}.")
        end
      end
    end

    def cmd_cs_drop(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      user = Modulus.users.find(origin.source)

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      Modulus.reply(origin, "Not yet implemented.")
      return

      channel = Channel.find_by_owner_id(Account.find_by_username(user.svid))

      if channel == nil
        Modulus.reply(origin, "That channel is not registered.")
      else
        channel = Channel.find_by_name(origin.argsArr[0])
        channel.destroy

        self.leave origin.argsArr[0]
        Modulus.reply(origin, "You have dropped the registration for #{origin.argsArr[0]}.")
        $log.info 'ChanServ', "#{origin.source} has dropped the registration for #{origin.argsArr[0]}."
      end
    end

    def cmd_cs_grant(origin)
      $log.debug "ChanServ", "Got: #{origin.raw}"

      user = Modulus.users.find(origin.source)

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      if origin.argsArr.length < 3
        Modulus.reply(origin, "Usage: GRANT #channel nick privileges")
        Modulus.reply(origin, "See HELP GRANT for more information. Valid privileges: VOICE HALFOP OP PROTECT OWNER BAN")
        return
      end

      channel = Channel.find_by_name(origin.argsArr[0])

      if channel == nil
        Modulus.reply(origin, "That channel is not registered.")
        return
      end

      user = Modulus.users.find(origin.argsArr[1])

      if user == nil
        Modulus.reply(origin, "The user must be on-line.")
        return
      end

      unless user.logged_in?
        Modulus.reply(origin, "The user must be logged in to a services account.")
        return
      end

      account = Account.find_by_username(user.svid)

      if account == nil
        Modulus.reply(origin, "The user must be logged in to a services account.")
        return
      end

      access = self.buildAccess(origin, origin.argsArr[2..origin.argsArr.length-1])

      return if access == nil

      if access.length == 0
        Modulus.reply(origin, "No valid permissions given. See HELP GRANT for more information.")
        return
      end

      chanAccess = self.getAccess(origin.argsArr[0], user)

      if chanAccess != nil
        chanAccess.access = access
        chanAccess.save!
      else
        ChannelUsers.create(
          :channel_id => channel.id,
          :account_id => account.id,
          :access => access)
      end

      Modulus.reply(origin, "Permissions for #{origin.argsArr[1]} have been changed.")
      $log.info 'ChanServ', "#{origin.source} updated channel access permissions: #{origin.args}."
    end

    ########################
    ##       EVENTS       ##
    ########################

    def on_join(origin)
      origin = origin[0]
      $log.debug "ChanServ", "on_join Got: #{origin}"
      unless Modulus.clients.isMyClient? origin.source
        user = Modulus.users.find(origin.source)
        return if user == nil

        chanAccess = self.getAccess(origin.message, user)

        if chanAccess != nil
          arr = self.parseAccess(origin, chanAccess.access)
        else
      
          chan = Channel.find_by_name(origin.message)
          return if chan == nil

          arr = self.parseAccess(origin, chan.defaultAccess)
        end

        Modulus.link.channelMode("ChanServ", origin.message, arr[0], arr[1])
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
            t.column :defaultAccess, :text, :default => ""
          end
        end
      end

      $log.debug 'ChanServ', "Checking for table: #{ChannelUsers.table_name}: #{ChannelUsers.table_exists?}"

      unless ChannelUsers.table_exists?
        ActiveRecord::Schema.define do
          create_table :channel_users do |t|
            t.column :channel_id, :integer, :null => false
            t.column :account_id, :integer, :null => false
            t.column :access, :text
          end
        end
      end
    end

    def joinRegistered
      Channel.find(:all).each { |c|
        self.join c.name
      }
    end

    def join(chan)
        Modulus.clients.clients["ChanServ"].addChannel(chan)
       Modulus.link.channelMode("ChanServ", chan, "+ntr")
    end

    def leave(chan)
       Modulus.link.channelMode("ChanServ", chan.name, "-r")
        Modulus.clients.clients["ChanServ"].removeChannel(chan.name)
    end

    def getAccess(chan, user)
      $log.debug 'ChanServ', "Getting channel access for #{user} on #{chan}"

      c = Channel.find_by_name(chan)
      return nil if c == nil
      
      a = Account.find_by_username(user.svid)
      return nil if a == nil
      
      ca = ChannelUsers.find_by_channel_id_and_account_id(c.id, a.id)
      return nil if ca == nil

      $log.debug 'ChanServ', "Got channel access for #{chan} #{user}: #{ca.access}"
      return ca
    end

    def parseAccess(origin, access)
      modeChange = "+"
      modeArgs = ""
      access.split(" ").each { |caItem|
        case caItem
          when "VOC"
            modeChange += "v"
            modeArgs += origin.source + " "
          when "HOP"
            modeChange += "h"
            modeArgs += origin.source + " "
          when "OPS"
            modeChange += "o"
            modeArgs += origin.source + " "
          when "PRT"
            modeChange += "a"
            modeArgs += origin.source + " "
          when "OWN"
            modeChange += "q"
            modeArgs += origin.source + " "
          when "BAN"
            modeChange += "b"
            modeArgs += origin.source + " "
        end
      }
      return [modeChange, modeArgs]
    end

    def buildAccess(origin, args)
      if args.length > 6
        Modulus.reply(origin, "Too many permissions given.")
        return nil
      end

      access = ""

      args.each { |arg|
        case arg.upcase
          when "VOICE"
            access += "VOC "
          when "HALFOP"
            access += "HOP "
          when "OP"
            access += "OPS "
          when "PROTECT"
            access += "PRT "
          when "OWNER"
            access += "OWN "
          when "BAN"
            access += "BAN "
          else
            Modulus.reply(origin, "Ignoring unknown permission #{arg}")  
        end
      }

      return access
    end

    class Channel < ActiveRecord::Base
    end

    class ChannelUsers < ActiveRecord::Base
    end

  end #class 

end #module Modulus
