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

  class BotServ

    def initialize
      Modulus.addService("BotServ", self,
                         "Services Bot Management Service
                         
BotServ allows users to create and manage services pseudoclients
which act as interactive bots in assigned channels.")

      Modulus.clients.addClient("BotServ", "Operator Control Service")

      Modulus.events.register(:database_connected, self, "on_db_connected")
      Modulus.events.register(:done_connecting, self, "on_done_connecting")

      Modulus.addCmd(self, "BotServ", "CREATE", "cmd_bs_create",
                     "Create a BotServ bot.",
                     "Usage: CREATE nickname
 
Using this command will instantly create a new BotServ bot.
The bot will immediately join the network, and a lock will
be placed on the IRC nickname.
                      
If registration of IRC nicknames through services is allowed
on this network, BotServ will check the services database
for any holds on the nickname. Any registrations or holds
will prevent a BotServ bot with the given nickname from
being created.
 
Some networks disallow the creation of BotServ bots. If this
is the case, you must contact your network's staff for more
information.
 
Most networks will have a hard limit placed on the maximum
number of bots that a services account holder can create.
If your account is at that limit, your request for a new
BotServ bot will be denied.")

      Modulus.addCmd(self, "BotServ", "DELETE", "cmd_bs_delete",
                     "Delete a BotServ bot.",
                     "Usage: DELETE nickname
 
If the nickname given is that of a BotServ bot owned by
your services account, the bot will be instantly and
permanently deleted. This action cannot be undone. If you
would like to recover a deleted BotServ bot, you must
register it again.")

      Modulus.addCmd(self, "BotServ", "JOIN", "cmd_bs_join",
                     "Add a BotServ bot to a channel.",
                     "Usage: JOIN nickname channel
 
If the nickname given is that of a BotServ bot owned by
your services account or you currently hold channel
operator status in the given channel, the bot will be
joined to the channel.
 
The bot will give itself channel operator or administrator
status in the channel, depending on network configuration.
 
To use most BotServ commands once the bot is in a channel,
the user giving the command must either be logged in to the
account which owns the bot, or a channel operator.
 
For information on removing a BotServ bot from a channel,
see HELP PART.")

      Modulus.addCmd(self, "BotServ", "PART", "cmd_bs_part",
                     "Remove a BotServ bot from a channel.",
                     "Usage: PART nickname channel
 
If the nickname given is that of a BotServ bot owned by
your services account or you currently hold channel
operator status in the given channel, the bot will leave
the channel.")

      Modulus.addCmd(self, "BotServ", "SAY", "cmd_bs_say",
                     "Cause a BotServ bot to send a message to a channel.",
                     "Usage: SAY nickname channel message
 
If the nickname given is that of a BotServ bot that is in
the given channel and you hold channel operator status in
that channel, the bot will send the given message to the
channel as a regular chat message (PRIVMSG).")

      Modulus.addCmd(self, "BotServ", "ACT", "cmd_bs_act",
                     "Cause a BotServ bot to perform an action in a channel.",
                     "Usage: ACT nickname channel action
 
If the nickname given is that of a BotServ bot that is in
the given channel and you hold channel operator status in
that channel, the bot will send the given message to the
channel as an action (CTCP ACTION).")

      Modulus.addCmd(self, "BotServ", "LIST", "cmd_bs_list",
                     "List the BotServ bots you have created.",
                     "Usage: LIST
 
This will show a list of all BotServ bots you have created,
if they still exist.")

    end


    def cmd_bs_create(origin)

      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: CREATE nickname")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless origin.argsArr[0].match(/\A[a-zA-Z0-9\-_\[\]]+\Z/)
        Modulus.reply(origin, "#{origin.argsArr[0]} is invalid. The bot nickname may only contain a-z, A-Z, 0-9, -, _, [, or ].")
        return
      end

      if BotServBot.find_by_nick(origin.argsArr[0])
        Modulus.reply(origin, "A BotServ bot with that nickname already exists.")
        return
      end

      if ReservedNick.find_by_nick(origin.argsArr[0])
        Modulus.reply(origin, "That nick is reserved by services.")
        return
      end

      account = Account.find_by_username(user.svid)

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bots = BotServBot.find_all_by_account_id(account.id)

      unless user.is_services_admin?

        max = Modulus.config.getOption("BotServ", "max_per_account")

        if max != nil
          begin
            max = Integer(max)
            if bots.length >= max
              Modulus.reply(origin, "You may not create any more BotServ bots.")
              return
            end
          rescue
            Modulus.reply(origin, "You may not create any more BotServ bots.")
            return
          end
        end

      end

      BotServBot.create(
        :nick => origin.argsArr[0],
        :account_id => account.id)

      self.bring_bot_online(origin.argsArr[0])

      Modulus.reply(origin, "The BotServ bot #{origin.argsArr[0]} is now online.")
      $log.info 'BotServ', "#{origin.source} has created bot #{origin.argsArr[0]}"
    end

    def cmd_bs_delete(origin)
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: DELETE nickname")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bot = BotServBot.find_by_nick(origin.argsArr[0])

      if bot == nil
        Modulus.reply(origin, "There is not a BotServ bot with that nickname.")
        return
      end

      account = Account.find_by_username(user.svid)

      if account == nil
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless user.is_services_admin?
        if account.id != bot.account_id
          Modulus.reply(origin, "Only the account which created that bot may delete it.")
          return
        end
      end

      client = Modulus.clients.clients[bot.nick]

      if client == nil
        $log.error 'BotServ', "While #{origin.source} was attempting to delete bot #{bot.nick}, I was unable to find the bot in the services client list."
        Modulus.reply(origin, "That bot does not appear to be online.")
        return
      end

      client.disconnect("#{origin.source} is deleting me. Bye!")
      bot.destroy

      Modulus.reply(origin, "The BotServ bot #{origin.argsArr[0]} has been deleted.")
      $log.info 'BotServ', "#{origin.source} has deleted bot #{origin.argsArr[0]}"
    end

    def cmd_bs_join(origin)
      if origin.argsArr.length != 2
        Modulus.reply(origin, "Usage: JOIN nickname channel")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bot = BotServBot.find_by_nick(origin.argsArr[0])

      if bot == nil
        Modulus.reply(origin, "There is not a BotServ bot with that nickname.")
        return
      end

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless user.is_services_admin?
        unless Modulus.channels.is_channel_op? origin.source, origin.argsArr[1]
          Modulus.reply(origin, "In order to bring bots to that channel, you must be a channel operator.")
          return
        end
      end

      BotServChannel.create(
        :channel => origin.argsArr[1],
        :bot_serv_bot_id => bot.id)

      self.join_to_channel(bot.nick, origin.argsArr[1])

      Modulus.reply(origin, "The BotServ bot #{origin.argsArr[0]} has been sent to #{origin.argsArr[1]}.")
      $log.info 'BotServ', "#{origin.source} has joined bot #{origin.argsArr[0]} to #{origin.argsArr[1]}"
    end

    def cmd_bs_part(origin)
      if origin.argsArr.length != 2
        Modulus.reply(origin, "Usage: PART nickname channel")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bot = BotServBot.find_by_nick(origin.argsArr[0])

      if bot == nil
        Modulus.reply(origin, "There is not a BotServ bot with that nickname.")
        return
      end

      unless user.is_services_admin?
        unless Modulus.channels.is_channel_op? origin.source, origin.argsArr[1]
          Modulus.reply(origin, "In order to send bots from that channel, you must be a channel operator.")
          return
        end
      end

      chan = BotServChannel.find_by_bot_serv_bot_id_and_channel(bot.id, origin.argsArr[1])

      if chan == nil
        Modulus.reply(origin, "That bot is not currently configured to join that channel.")
        return
      end

      client = Modulus.clients.clients[bot.nick]

      if client == nil
        Modulus.reply(origin, "That bot does not appear to be online.")
        $log.error 'BotServ', "While attempting to join bot #{nickname} to a channel, I was unable to find it in my client list."
        return
      end

      chan.destroy
      client.removeChannel(origin.argsArr[1])

      Modulus.reply(origin, "The BotServ bot #{origin.argsArr[0]} has been taken from #{origin.argsArr[1]}.")
      $log.info 'BotServ', "#{origin.source} has parted bot #{origin.argsArr[0]} from #{origin.argsArr[1]}"
    end

    def cmd_bs_list(origin)
      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      account = Account.find_by_username(user.svid)

      if account == nil
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bots = BotServBot.find_all_by_account_id(account.id)

      if bots.length == 0
        Modulus.reply(origin, "You do not own any BotServ bots.")
        return
      end
      
      Modulus.reply(origin, "BotServ bots owned by #{user.svid}:")

      bots.each { |bot|
        Modulus.reply(origin, "  #{bot.nick}")
      }

      Modulus.reply(origin, "Total bot owned: #{bots.length}.")
    end
    
    def cmd_bs_act(origin)
      if origin.argsArr.length < 3
        Modulus.reply(origin, "Usage: SAY nickname channel message")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bot = BotServBot.find_by_nick(origin.argsArr[0])

      if bot == nil
        Modulus.reply(origin, "There is not a BotServ bot with that nickname.")
        return
      end

      unless user.is_services_admin?
        unless Modulus.channels.is_channel_op? origin.source, origin.argsArr[1]
          Modulus.reply(origin, "In order to send bots from that channel, you must be a channel operator.")
          return
        end
      end

      chan = BotServChannel.find_by_bot_serv_bot_id_and_channel(bot.id, origin.argsArr[1])

      if chan == nil
        Modulus.reply(origin, "That bot is not currently configured to join that channel.")
        return
      end

      self.act_to_chan(bot.nick, origin.argsArr[1], origin.argsArr[2..origin.argsArr.length-1].join(" "))

      $log.info 'BotServ', "#{origin.source} ACT #{origin.args}"
    end
    
    def cmd_bs_say(origin)
      if origin.argsArr.length < 3
        Modulus.reply(origin, "Usage: SAY nickname channel message")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      bot = BotServBot.find_by_nick(origin.argsArr[0])

      if bot == nil
        Modulus.reply(origin, "There is not a BotServ bot with that nickname.")
        return
      end

      unless user.is_services_admin?
        unless Modulus.channels.is_channel_op? origin.source, origin.argsArr[1]
          Modulus.reply(origin, "In order to send bots from that channel, you must be a channel operator.")
          return
        end
      end

      chan = BotServChannel.find_by_bot_serv_bot_id_and_channel(bot.id, origin.argsArr[1])

      if chan == nil
        Modulus.reply(origin, "That bot is not currently configured to join that channel.")
        return
      end

      self.say_to_chan(bot.nick, origin.argsArr[1], origin.argsArr[2..origin.argsArr.length-1].join(" "))

      $log.info 'BotServ', "#{origin.source} SAY #{origin.args}"
    end

    def say_to_chan(source, target, message)
      Modulus.link.sendPrivmsg(source, target, message)
    end 

    def act_to_chan(source, target, message)
      Modulus.link.sendPrivmsg(source, target, "\1ACTION #{message}\1")
    end

    def bring_bot_online(nickname)
      newClient = Modulus.clients.addClient(nickname, "BotServ Bot")
      newClient.connect
      newClient.joinLogChan
    end

    def join_to_channel(nickname, channel)
      client = Modulus.clients.clients[nickname]

      if client == nil
        $log.error 'BotServ', "While attempting to join bot #{nickname} to a channel, I was unable to find it in my client list."
        return
      end

      client.addChannel(channel)
    end

    def on_done_connecting
      bots = BotServBot.find(:all, :include => [ :bot_serv_channels ])
      bots.each { |bot|
        bring_bot_online(bot.nick)
        bot.bot_serv_channels.each { |chan|
          Modulus.link.joinChannel(bot.nick, chan.channel)
        }
      }
    end

    def on_db_connected
      unless BotServBot.table_exists?
        ActiveRecord::Schema.define do
          create_table :bot_serv_bots do |t|
            t.column :nick, :string, :null => false
            t.column :account_id, :integer, :null => false
          end
        end
      end

      unless BotServChannel.table_exists?
        ActiveRecord::Schema.define do
          create_table :bot_serv_channels do |t|
            t.column :bot_serv_bot_id, :integer, :null => false
            t.column :channel, :string, :null => false
          end
        end
      end

    end

    class BotServBot < ActiveRecord::Base
      has_many :bot_serv_channels
    end

    class BotServChannel < ActiveRecord::Base
      belongs_to :bot_serv_bot
    end

  end #class BotServ

end #module Modulus
