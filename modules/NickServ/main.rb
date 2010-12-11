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

    def initialize
      Modulus.addService("NickServ", self,
                         "Nick Registration Services
                         
NickServ allows users to register and protect their
nicks.")

      Modulus.events.register(:database_connected, self, "dbConnected")

      Modulus.clients.addClient("NickServ", "Nick Registration Service")

      Modulus.addCmd(self, "NickServ", "IDENTIFY", "cmd_ns_identify",
                     "Log in to your account and verify your ownership of your current nick.",
                     "Usage: IDENTIFY password
 
Using this command, you will be identified to your services account.
You must have a registered nickname to use this command.")

      Modulus.addCmd(self, "NickServ", "UNIDENTIFY", "cmd_ns_unidentify",
                     "Logs you out of your services account. If you are not logged in, modes are cleared anyway.",
                     "Usage: UNIDENTIFY
 
Using this command will remove all flags from you which indicate you are
logged in to a services account. Services will not check if you are logged
in and will remove all flags no matter what. This is to help
resolve any problems that may arise from network sync problems
or other bugs.")

      Modulus.addCmd(self, "NickServ", "LIST", "cmd_ns_list",
                     "List all nicks currently registered to your account.",
                     "Usage: LIST
 
You may use this command to see all nicks that have been registered while
you have been logged in to your services account, if any.")

      Modulus.addCmd(self, "NickServ", "REGISTER", "cmd_ns_register",
                     "Register your current nick.",
                     "Usage: REGISTER password e-mail [username]
 
When you attempt to register a nickname, services will check if an account
with the specified e-mail address exists. If it does, you must also provide
your services account user name. Otherwise, a new account will be created
with that e-mail address.
 
If no username is specified, your current IRC nickname will be used.
 
Please be sure to remember your username as you will need it to register
additional IRC nicknames, and you may need it to use some network services.
If you don't remember your services account user name but you are logged in
to services, you may be able to view the user name by performing a WHOIS
on yourself.")

      Modulus.addCmd(self, "NickServ", "DROP", "cmd_ns_drop",
                     "Drop the registration of your current nick.",
                     "Usage: DROP password
 
You must give your services account password in order to use this command.
 
Using this command will completely erase NickServ's record of your current
IRC nickname. It will not erase your services account, even if it this
is the last nickname registered thereto. This action cannot be undone.
If you wish to un-drop a nick, you must re-register it as a new nick, even
if the nick was just dropped. To delete your services account entirely,
contact your network's staff.")
    end

    def cmd_ns_list(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"

      user = Modulus.users.find(origin.source)

      unless user.logged_in?
        Modulus.reply(origin, "You must be logged in to a services account in order to use this command.")
        return
      end

      nicks = Nick.find_all_by_account_id(Account.find_by_username(user.svid))

      if nicks.length != 0
        Modulus.reply(origin, "Nicks registered to #{user.svid}:")

        Modulus.reply(origin, sprintf("%30.30s  %-25.25s", "Nick", "Date Registered"))

        nicks.each { |nick|
          Modulus.reply(origin, sprintf("%30.30s  %-25.25s", nick.nick, nick.dateRegistered))
        }

        Modulus.reply(origin, "Total nicks registered: #{nicks.length}")
      else
        Modulus.reply(origin, "There are currently no nicks registered to #{user.svid}.")
      end            
    end
      
    def cmd_ns_unidentify(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"

      Modulus.users.logOut(origin.source)
     Modulus.svsmode(origin.source, "-r+d *")
      Modulus.reply(origin, "You have been logged out.")
    end

    def cmd_ns_identify(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"
      
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: IDENTIFY password")
        return
      end

      password = origin.argsArr[0]

      nickRecord = Nick.find_by_nick(origin.source)

      if nickRecord == nil
        Modulus.reply(origin, "Your nick is not registered.")
        return
      end

      account = Account.find(nickRecord.account_id)

      if account == nil
        # This should never happen.

        $log.error 'NickServ', "While performing an IDENTIFY, the services account for #{origin.source} could not be found, but the nick is in the database as registered."
        Modulus.reply(origin, "There was a problem with your request. The services account associated with this nick no longer exists. Please contact your network's staff for assistance.")
        return
      end

      if account.password == password
        self.logIn(account.username, origin.source)

        Modulus.reply(origin, "You have been identified as the owner of #{origin.source}")
        $log.info "NickServ", "#{origin.source} has been identified as account #{account.username}."
      else
        Modulus.reply(origin, "Incorrect password.")
        $log.info "NickServ", "Login failed for #{origin.source}."

        #TODO: Record this. Ban for too many failures.
        #TODO: Make the above TODO configurable.
      end

    end

    def cmd_ns_drop(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"
      
      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: DROP password")
      else
        nickRecord = Nick.find_by_nick(origin.source)


          if nickRecord == nil
            Modulus.reply(origin, "Your nick is not currently registered.")
          else
            account = Account.find(nickRecord.account_id)
            if account.password == origin.argsArr[0]
              nickRecord.destroy

              Modulus.reply(origin, "Nick registration dropped.")
              $log.info "NickServ", "#{origin.source} has dropped their nick registration."

              nickRecords = Nick.find_all_by_account_id(account.id)

              if nickRecords.length == 0
                Modulus.reply(origin, "You no longer have any nicks registered. Your services account #{account.username} will remain intact for use with other modules until it expires (if expiration is enabled here).")
              end
            else
              Modulus.reply(origin, "Incorrect password.")
            end
          end
      end
    end

    def cmd_ns_register(origin)
      $log.debug "NickServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 2 and origin.argsArr.length != 3
        Modulus.reply(origin, "Usage: REGISTER password e-mail [username]")
      else
        password = origin.argsArr[0]
        email = origin.argsArr[1]
        
        if origin.argsArr.length == 3
          username = origin.argsArr[2]
        else
          username = origin.source
        end

        if Nick.find_by_nick(origin.source)
          Modulus.reply(origin, "The nick #{origin.source} is already registered.")
        else
          emailAcc = Account.find_by_email(email)

          if emailAcc != nil
            if username != emailAcc.username
              Modulus.reply(origin, "The e-mail address #{email} has already been used by a registered user. If this is you, try including your username as well.")
              return 
            end
          end

          acc = Account.find_by_username(username)

          if acc == nil
            $log.debug "NickServ", "There is no account for #{username} but a user is trying to register a nick with it. Creating account with given password."

            acc = Account.create(
              :username => username,
              :email => email,
              :password => password,
              :dateRegistered => DateTime.now,
              :verified => true)

            Modulus.reply(origin, "I have created a new account for #{username} (#{email}). If you register additional nicks in the future, use this e-mail address and username and the same password to keep nicks attached to this account. Otherwise, managing your services use will becoming confusing for both you and the network staff.")
          elsif acc.password != password
            Modulus.reply(origin, "Incorrect password for the existing account with that e-mail address.")
            $log.info "NickServ", "Login failed: #{origin.source} tried to register a new nick for account #{acc.username} but used the wrong password."
            return
          end

          # Everyything looks good. Go ahead and make it.
          Nick.create(
            :account_id => acc.id,
            :nick => origin.source,
            :dateRegistered => DateTime.now)

          self.logIn(username, origin.source)
          Modulus.reply(origin, "You have registered #{origin.source} to #{username} (#{email}).")
          $log.info "NickServ", "Nick #{origin.source} registered to #{username}."
        end
      end
    end

    def logIn(username, nick)
      user = Modulus.users.find(nick)

      return if user == nil
      
      user.logIn username

      Modulus.link.svsmode(nick, "+rd #{username}")
      Modulus.users.logIn(nick, username)
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
