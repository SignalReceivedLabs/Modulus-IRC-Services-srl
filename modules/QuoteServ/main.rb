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

    def initialize(services)
      @services = services

      services.addService("QuoteServ", self,
                         "Quotation Storage Service
                         
QuoteServ allows services users to store memorable
quotes in a database.")

      services.events.register(:database_connected, self, "dbConnected")
      services.events.register(:done_connecting, self, "done_connecting")

      services.clients.addClient(@services, "QuoteServ", "Quotation Storage Service")


      services.addCmd(self, "QuoteServ", "ADD", "cmd_qs_add",
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

      services.addCmd(self, "QuoteServ", "GET", "cmd_qs_get",
                     "Get a quotation from the database by quotation ID.",
                     "Usage: GET quotationID
 
A numerical identifier is assigned to each quotation added
to the database. Using this unique identifier, it is possible
to quickly fetch and display quotations.")

      services.addCmd(self, "QuoteServ", "SEARCH", "cmd_qs_search",
                     "Search the database for quotations.",
                     "Usage: SEARCH query
 
The search query is case-insensitive. Wildcards are not supported.")

      services.addCmd(self, "QuoteServ", "JOIN", "cmd_qs_join",
                     "Bring QuoteServ to a channel.",
                     "Usage: JOIN channel
 
You must be a channel operator in the given channel for this to
work. If you want QuoteServ in a channel in which you are not
an operator, ask the channel owner or other operators.
 
Once QuoteServ has joined a channel, it will persistently remain
there.")

      services.addCmd(self, "QuoteServ", "PART", "cmd_qs_part",
                     "Cause QuoteServ to leave a channel.",
                     "Usage: PART channel
 
You must be a channel operator in the given channel for this to
work. QuoteServ will immediately leave the channel and will not
return unless brought back.")

      services.addCmd(self, "QuoteServ", "UP", "cmd_qs_up",
                     "Vote for a quotation, causing its rank to increase.",
                     "Usage: UP quotationId
 
All quotations in QuoteServ's database are assigned a numerical
rank. When a quotation is created, this rank begins at 0. Each
time a user uses the UP command for that quotation ID, the
quotation will have 1 added to its rank.")

      services.addCmd(self, "QuoteServ", "DOWN", "cmd_qs_down",
                     "Vote against a quotation, causing its rank to decrease.",
                     "Usage: DOWN quotationId
 
All quotations in QuoteServ's database are assigned a numerical
rank. When a quotation is created, this rank begins at 0. Each
time a user uses the DOWN command for that quotation ID, the
quotation will have 1 subtracted from rank.")

      services.addCmd(self, "QuoteServ", "REMOVE", "cmd_qs_remove",
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

    end

    def cmd_qs_part(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

    end

    def cmd_qs_add(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

    end

    def cmd_qs_search(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

    end

    def cmd_qs_remove(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

    end

    def cmd_qs_up(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

    end

    def cmd_qs_down(origin)
      $log.debug "QuoteServ", "Got: #{origin.raw}"

    end

    def done_connecting
      QuoteChannel.find(:all).each { |c|
        self.join c.channel
      }
    end
    
    def join(chan)
        @services.clients.clients["QuoteServ"].addChannel(chan)
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
            t.column :date_added, :datetime, :null => false
            t.column :place_added, :string, :null => false
            t.column :content, :string, :null => false
            t.column :rank, :integer, :default => 0
            t.column :views, :integer, :default => 0
          end
        end
      end

    end

    class Quote < ActiveRecord::Base
      belongs_to :account
    end

    class QuoteChannel < ActiveRecord::Base
    end

  end #class 

end #module Modulus
