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

  class NickServ

    def initialize(services)
      @services = services

      services.addService("NickServ", self,
                         "Nick Registration Services
                         
                         NickServ allows users to register and protect their
                         nicks.")

      services.events.register(:database_connected, self, "dbConnected")

      services.clients.addClient(@services, "NickServ", "Nick Registration Service")

      services.addCmd(self, "NickServ", "REGISTER", "cmd_ns_register",
                     "Register your current nick.")

      services.addCmd(self, "ChanServ", "DROP", "cmd_ns_drop",
                     "Drop the registration of your current nick.")
    end

    def cmd_ns_register(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"

      if origin.arr.length != 3
        @services.reply(origin, "NickServ", "Usage: REGISTER password e-mail")
      else
        password = origin.argsArr[0]
        email = origin.argsArr[1]
        
        if Nick.find_by_nick(origin.source)
          @services.reply(origin, "NickServ", "The nick #{origin.source} is already registered.")
        else
          acc = Account.find_by_email(email)
          if acc == nil
            $log.debug "NickServ", "There is no account for #{email} but a user is trying to register a nick with it. Creating account with given password."

            acc = Account.create(
              :email => email,
              :password => password,
              :dateRegistered => DateTime.now,
              :verified => true)


            @services.reply(origin, "NickServ", "I have created a new account for #{email}. If you register additional nicks in the future, use this e-mail address and the same password to keep nicks attached to this account.")
          elsif acc.password != password
            @services.reply(origin, "NickServ", "Incorrect password for the existing account with that e-mail address.")
            return
          end


          # Everyything looks good. Go ahead and make it.
          Nick.create(
            :account_id => acc.id,
            :nick => origin.source,
            :dateRegistered => DateTime.now)

          @services.reply(origin, "NickServ", "You have registered #{origin.source} to #{origin.argsArr[1]}.")
        end
      end
    end

    def dbConnected
      $log.debug "NickServ", "Received database_connected callback. Beginning database check."

      unless Nick.table_exists?
        ActiveRecord::Schema.define do
          create_table :nicks do |t|
            t.column :nick, :string, :null => false
            t.column :account_id, :integer, :null => false
            t.column :enforceType, :string
            t.column :dateRegistered, :datetime, :null => false
            t.column :dateLastActive, :datetime
          end
        end
      end

    end

    class Nick < ActiveRecord::Base
      belongs_to :account
    end

    class Account < ActiveRecord::Base
      has_many :nicks
    end

  end #class 

end #module Modulus
