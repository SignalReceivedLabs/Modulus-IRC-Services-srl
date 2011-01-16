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

  class QuoteServ

    def initialize
      Modulus.addService("QuoteServ", self,
                         "Quotation Storage Service
                         
QuoteServ allows services users to store memorable
quotes in a database.")

      Modulus.events.register(:database_connected, self, "dbConnected")
      Modulus.events.register(:done_connecting, self, "done_connecting")

      Modulus.clients.addClient("QuoteServ", "Quotation Storage Service")


      Modulus.addCmd(self, "QuoteServ", "ADD", "cmd_qs_add",
                     "Add a quotation to the database.",
                     "Usage: ADD quotation
 
Add the quotation to the database. Each quotation is stored
by a unique, numerical identifier. You may use this identifier
to call up this exact quotation. The IRC nickname and location
of the user that added the quotation will be stored as well.
 
Take care when adding quotations to the database, as many users
do not want their chat to be recorded in a potentially public
database.
 
Many networks have terms of service or privacy policies which
may restrict your rights to add private chats or chats in
secret or private channels to the database. Ask network staff
if you are unsure.")

      Modulus.addCmd(self, "QuoteServ", "GET", "cmd_qs_get",
                     "Get a quotation from the database by quotation ID.",
                     "Usage: GET quotationID
 
A numerical identifier is assigned to each quotation added
to the database. Using this unique identifier, it is possible
to quickly fetch and display quotations.")

      Modulus.addCmd(self, "QuoteServ", "SEARCH", "cmd_qs_search",
                     "Search the database for quotations.",
                     "Usage: SEARCH query
 
The search query is case-insensitive. Wildcards are not supported.")

      Modulus.addCmd(self, "QuoteServ", "JOIN", "cmd_qs_join",
                     "Bring QuoteServ to a channel.",
                     "Usage: JOIN channel
 
You must be a channel operator in the given channel for this to
work. If you want QuoteServ in a channel in which you are not
an operator, ask the channel owner or other operators.
 
Once QuoteServ has joined a channel, it will persistently remain
there.")

      Modulus.addCmd(self, "QuoteServ", "PART", "cmd_qs_part",
                     "Cause QuoteServ to leave a channel.",
                     "Usage: PART channel
 
You must be a channel operator in the given channel for this to
work. QuoteServ will immediately leave the channel and will not
return unless brought back.")

      Modulus.addCmd(self, "QuoteServ", "UP", "cmd_qs_up",
                     "Vote for a quotation, causing its rank to increase.",
                     "Usage: UP quotationId
 
All quotations in QuoteServ's database are assigned a numerical
rank. When a quotation is created, this rank begins at 0. Each
time a user uses the UP command for that quotation ID, the
quotation will have 1 added to its rank.")

      Modulus.addCmd(self, "QuoteServ", "DOWN", "cmd_qs_down",
                     "Vote against a quotation, causing its rank to decrease.",
                     "Usage: DOWN quotationId
 
All quotations in QuoteServ's database are assigned a numerical
rank. When a quotation is created, this rank begins at 0. Each
time a user uses the DOWN command for that quotation ID, the
quotation will have 1 subtracted from rank.")

      Modulus.addCmd(self, "QuoteServ", "REMOVE", "cmd_qs_remove",
                     "Remove a quotation from the database by quotation ID.",
                     "Usage: REMOVE quotationID
 
This command will immediately and permanently delete a quotation
from the database. On some networks, this is restricted to
services administrators to prevent abuse.
 
As such, the best practice when adding quotation is to be sure
that all parties being quoted do not mind the information being
available to the entire network and likely the entire Internet.")

    end

    def cmd_qs_join(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: JOIN channel")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless user.is_services_admin?
        unless Modulus.channels.is_channel_op? origin.source, origin.argsArr[1]
          Modulus.reply(origin, "In order to bring QuoteServ to that channel, you must be a channel operator.")
          return
        end
      end

      chan = QuoteChannel.find_by_channel(origin.argsArr[0])

      unless chan == nil
        Modulus.reply(origin, "QuoteServ is already configured to join that channel.")
        return
      end

      QuoteChannel.create(
        :channel => origin.argsArr[0])

      self.join(origin.argsArr[0])

      Modulus.reply(origin, "QuoteServ has been sent to #{origin.argsArr[0]}.")
      $log.info 'QuoteServ', "#{origin.source} has joined #{origin.argsArr[0]}"
    end

    def cmd_qs_part(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: PART channel")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      chan = QuoteChannel.find_by_channel(origin.argsArr[0])

      if chan == nil
        Modulus.reply(origin, "QuoteServ is not configured to join that channel.")
        return
      end

      unless user.is_services_admin?
        unless Modulus.channels.is_channel_op? origin.source, origin.argsArr[0]
          Modulus.reply(origin, "In order to remove QuoteServ from that channel, you must be a channel operator.")
          return
        end
      end

      client = Modulus.clients.clients['QuoteServ']

      if client == nil
        Modulus.reply(origin, "QuoteServ does not appear to be online.")
        $log.error 'BotServ', "While attempting to join bot #{nickname} to a channel, I was unable to find it in my client list."
        return
      end

      chan.destroy
      client.removeChannel(origin.argsArr[0])

      Modulus.reply(origin, "QuoteServ has been removed from #{origin.argsArr[0]}.")
      $log.info 'QuoteServ', "#{origin.source} has removed QuoteServ from #{origin.argsArr[0]}"
    end

    def cmd_qs_add(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

      if origin.argsArr.length < 1
        Modulus.reply(origin, "Usage: ADD quotation")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless origin.args.length < 300
        Modulus.reply(origin, "Quotations cannot be longer than 300 characters.")
        return
      end

      unless Modulus.link.isChannel? origin.target
        source = "Private Message"
      else
        source = origin.target
      end

      Quote.create(
        :content => origin.args,
        :place_added => source,
        :date_added => DateTime.now(),
        :added_by_nick => origin.source,
        :account_name => user.svid
      )

      Modulus.reply(origin, "Quotation successfully added to the database.")
      $log.info 'QuoteServ', "#{origin.source} added a new quotation to the database from #{source}"
    end

    def cmd_qs_search(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

      if origin.argsArr.length < 1
        Modulus.reply(origin, "Usage: SEARCH content")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      found = Quote.find(:all, :conditions => ['content like ?', "%#{origin.args}%"])

      if found.count == 0
        Modulus.reply(origin, "No matches.")
      elsif found.count > 3
        Modulus.reply(origin, "Found #{found.count} matches.#{" Displaying first 3." if found.count > 3}")
        pos = 0

        found.each { |result|
          self.show_quotation(origin, result)
          pos += 1

          break if pos == 3
        }
      else
        found.each { |result|
          self.show_quotation(origin, result)
        }
      end
    end


    def cmd_qs_get(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: GET id")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless origin.args =~ /^[\d]+$/
        Modulus.reply(origin, "You must give a numerical quotation ID.")
        return
      end

      begin
        found = Quote.find(origin.args)
        self.show_quotation(origin, found)
      rescue
        Modulus.reply(origin, "There is no such quotation.")
      end
    end

    def cmd_qs_remove(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: GET id")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless origin.args =~ /^[\d]+$/
        Modulus.reply(origin, "You must give a numerical quotation ID.")
        return
      end

      begin
        found = Quote.find(origin.args)

        if found.account == user.svid or user.is_services_admin?
          found.destroy
          $log.info 'QuoteServ', "#{origin.source} deleted quotation #{origin.args}."
          Modulus.reply(origin, "Quotation deleted successfully.")
        else
          Modulus.reply(origin, "You may only delete quotations which you created.")
        end
      rescue
        Modulus.reply(origin, "There is no such quotation.")
      end
    end

    def cmd_qs_up(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: UP id")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless origin.args =~ /^[\d]+$/
        Modulus.reply(origin, "You must give a numerical quotation ID.")
        return
      end

      begin
        found = Quote.find(origin.args)

        rater = QuoteRater.find_by_id_and_account_name(found.id, user.svid)

        if rater != nil
          Modulus.reply(origin, "You have already rated this quotation.")
          return
        end

        QuoteRater.create(
          :quote_id => found.id,
          :account_name => user.svid
        )

        found.rank += 1
        found.save!
        Modulus.reply(origin, "#{found.id} is now ranked #{found.rank}")
      rescue
        Modulus.reply(origin, "There is no such quotation.")
      end
    end

    def cmd_qs_down(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: DOWN id")
        return
      end

      user = Modulus.users.find(origin.source)

      return if user == nil

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      unless origin.args =~ /^[\d]+$/
        Modulus.reply(origin, "You must give a numerical quotation ID.")
        return
      end

      begin
        found = Quote.find(origin.args)

        rater = QuoteRater.find_by_id_and_account_name(found.id, user.svid)

        if rater != nil
          Modulus.reply(origin, "You have already rated this quotation.")
          return
        end

        QuoteRater.create(
          :quote_id => found.id,
          :account_name => user.svid
        )

        found.rank -= 1
        found.save!
        Modulus.reply(origin, "#{found.id} is now ranked #{found.rank}")
      rescue
        Modulus.reply(origin, "There is no such quotation.")
      end
    end

    def done_connecting
      QuoteChannel.find(:all).each { |c|
        self.join c.channel
      }
    end
    
    def join(chan)
        Modulus.clients.clients["QuoteServ"].addChannel(chan)
    end

    def show_quotation(origin, quotation)
      Modulus.reply(origin, "##{quotation.id} [Rating: #{quotation.rank} Added by: #{quotation.added_by_nick}/#{quotation.place_added}]: #{quotation.content}")
      quotation.views += 1
      quotation.save!
    end

    def dbConnected
      $log.debug "QuoteServ", "Received database_connected callback. Beginning database check."

      unless QuoteChannel.table_exists?
        ActiveRecord::Schema.define do
          create_table :quote_channels do |t|
            t.column :channel, :string, :null => false
          end
        end
      end

      unless Quote.table_exists?
        ActiveRecord::Schema.define do
          create_table :quotes do |t|
            t.column :added_by_nick, :string, :null => false
            t.column :account_name, :string, :null => false
            t.column :date_added, :datetime, :null => false
            t.column :place_added, :string, :null => false
            t.column :content, :string, :null => false
            t.column :rank, :integer, :default => 0
            t.column :views, :integer, :default => 0
          end
        end
      end

      unless QuoteRater.table_exists?
        ActiveRecord::Schema.define do
          create_table :quote_raters do |t|
            t.column :quote_id, :integer, :null => false
            t.column :account_name, :string, :null => false
          end
        end
      end
    end

    class Quote < ActiveRecord::Base
      belongs_to :account
    end

    class QuoteChannel < ActiveRecord::Base
    end

    class QuoteRater < ActiveRecord::Base
      belongs_to :quote
    end

  end #class 

end #module Modulus
