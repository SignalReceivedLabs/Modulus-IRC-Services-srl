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

      services.addCmd(self, "NickServ", "IDENTIFY", "cmd_ns_identify",
                     "Log in to your account and verify your ownership of your current nick.")

      services.addCmd(self, "NickServ", "LIST", "cmd_ns_list",
                     "List all nicks currently registered to your account.")

      services.addCmd(self, "NickServ", "REGISTER", "cmd_ns_register",
                     "Register your current nick.")

      services.addCmd(self, "NickServ", "DROP", "cmd_ns_drop",
                     "Drop the registration of your current nick.")
    end

    def cmd_ns_list(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 2
        @services.reply(origin, "NickServ", "Usage: LIST email password")
      else
        email = origin.argsArr[0]
        password = origin.argsArr[1]

        account = Account.find_by_email(email)

        if account == nil
          @services.reply(origin, "NickServ", "#{email} is not registered.")

        elsif account.password == password
          nicks = Nick.find_all_by_account_id(account.id)

          if nicks.length != 0
            @services.reply(origin, "NickServ", "Nicks registered to #{email}:")

            @services.reply(origin, "NickServ", sprintf("%30.30s  %-25.25s", "Nick", "Date Registered"))

            nicks.each { |nick|
              @services.reply(origin, "NickServ", sprintf("%30.30s  %-25.25s", nick.nick, nick.dateRegistered))
            }

            @services.reply(origin, "NickServ", "Total registered nicks: #{nicks.length}")
          else
            @services.reply(origin, "NickServ", "There are currently no nicks registered to #{email}.")
          end            
        else
          @services.reply(origin, "NickServ", "Incorrect password.")
        end

      end
    end
      
    def cmd_ns_identify(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"
      
      if origin.argsArr.length != 1
        @services.reply(origin, "NickServ", "Usage: IDENTIFY password")
      else
        password = origin.argsArr[0]

        nickRecord = Nick.find_by_nick(origin.source)

        if nickRecord == nil
          @services.reply(origin, "NickServ", "Your nick is not registered.")
        else

          account = Account.find(nickRecord.account_id)

          if account == nil
            # This should never happen.

            $log.error 'NickServ', "While performing an IDENTIFY, the services account for #{origin.source} could not be found, but the nick is in the database as registered."
            @services.reply(origin, "NickServ", "There was a problem with your request. The services account associated with this nick no longer exists. Please contact your network's staff for assistance.")

          else
            if account.password == password

              @services.reply(origin, "NickServ", "You have been identified as the owner of #{origin.source}")
              $log.info "NickServ", "#{origin.source} has been identified as account #{account.email}."
            else
              @services.reply(origin, "NickServ", "Incorrect password.")
              $log.info "NickServ", "Login failed for #{origin.source}."

              #TODO: Record this. Ban for too many failures.
              #TODO: Make the above TODO configurable.
            end

          end

        end

      end
    end

    def cmd_ns_drop(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"
      
      if origin.argsArr.length != 1
        @services.reply(origin, "NickServ", "Usage: DROP password")
      else
        nickRecord = Nick.find_by_nick(origin.source)


          if nickRecord == nil
            @services.reply(origin, "NickServ", "Your nick is not currently registered.")
          else
            account = Account.find(nickRecord.account_id)
            if account.password == origin.argsArr[0]
              nickRecord.destroy

              @services.reply(origin, "NickServ", "Nick registration dropped.")
              $log.info "NickServ", "#{origin.source} has dropped their nick registration."

              nickRecords = Nick.find_all_by_account_id(account.id)

              if nickRecords.length == 0
                @services.reply(origin, "NickServ", "You no longer have any nicks registered. Your services account #{account.email} will remain intact for use with other modules until it expires (if expiration is enabled here).")
              end
            else
              @services.reply(origin, "NickServ", "Incorrect password.")
            end
          end
      end
    end

    def cmd_ns_register(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 2
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
            $log.info "NickServ", "Login failed: #{origin.source} tried to register a new nick for account #{acc.email} but used the wrong password."
            return
          end

          # Everyything looks good. Go ahead and make it.
          Nick.create(
            :account_id => acc.id,
            :nick => origin.source,
            :dateRegistered => DateTime.now)

          @services.reply(origin, "NickServ", "You have registered #{origin.source} to #{origin.argsArr[1]}.")
          $log.info "NickServ", "Nick #{origin.source} registered to #{email}."
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
