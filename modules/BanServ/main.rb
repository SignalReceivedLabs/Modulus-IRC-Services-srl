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

  class BanServ

    require 'resolv'

    def initialize
      Modulus.addService("BanServ", self,
                         "Ban Management Service
                         
BanServ allows services administrators to create and
remove network bans, as well as monitor the network
for blacklisted connections.")

      Modulus.events.register(:database_connected, self, "dbConnected")
      Modulus.events.register(:connected, self, "on_connect")

      Modulus.clients.addClient("BanServ", "Ban Management Service")


      Modulus.addCmd(self, "BanServ", "AUTOKILL", "cmd_bs_autokill",
                     "Manage the automatic kill list.",
                     "Usage: AUTOKILL command parameters
 
This command is for services administrators only.
                      
Commands:
  LIST - List all AUTOKILLs
  ADD user@ip/host reason - Add a user@ip or user@host to the
                            AUTOKILL list with specified ban reason.
  REMOVE user@ip/host - Remove a user@ip or user@host from the
                        AUTOKILL list
 
When a new client connects to the network, it will be checked against
the AUTOKILL list. Matches will be banned from the network as appropriate
with your network's protocol. The set ban reason will be used as the
protocol's ban reason.")


      Modulus.addCmd(self, "BanServ", "REGEXKILL", "cmd_bs_regexkill",
                     "Manage the regular expression kill list.",
                     "Usage: REGEXKILL command parameters
 
This command is for services administrators only.
 
Commands:
  LIST - List all REGEXKILLs
  ADD regex reason - Add a regular expression to the REGEXKILL list with
                     specified ban reason.
  REMOVE regex - Remove a regular expression from the REGEXKILL list.
 
When a new client connects to the network, it will be checked against
the REGEXKILL list. nick!user@host will be checked against the
regular expression. Matches will be banned from the network as appropriate
with your network's protocol. The set ban reason will be used as the
protocol's ban reason.")


      Modulus.addCmd(self, "BanServ", "CHECK", "cmd_bs_check",
                     "Check IP addresses against DNSBLs.",
                     "Usage: CHECK host
 
This command is for services administrators only.
 
The given address must be a valid IP address. Host name lookups could
take a while and may time out, so in order to ensure services performance,
host names are not allowed.
 
Matching IP addresses will not be automatically banned.")

    end

    def cmd_bs_autokill(origin)
      $log.debug "BanServ", "Got: #{origin.raw}"

    end

    def cmd_bs_regexkill(origin)
      $log.debug "BanServ", "Got: #{origin.raw}"

    end

    def cmd_bs_check(origin)
      $log.debug "BanServ", "Got: #{origin.raw}"

      blacklists = Modulus.config.getOption("BanServ", "use_dnsbl")

      if blacklists == nil
        Modulus.reply(origin, "DNSBL lookups are not enabled")
        return
      end

      if blacklists == "disabled"
        Modulus.reply(origin, "DNSBL lookups are not enabled")
        return
      end

      if origin.argsArr.length != 1
        Modulus.reply(origin, "Usage: CHECK ip")
        return
      end

      if !origin.argsArr[0].match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
        Modulus.reply(origin, "You must provide a valid IP address.")
        return
      end

      check = origin.argsArr[0].split('.').reverse.join('.')

      blacklists.split(" ").each { |dnsbl|
        begin
          result = Resolv::getaddress("#{check}.#{dnsbl}")
          result = result.split(".")[3]

          Modulus.reply(origin, "Found in #{dnsbl} as #{result}")
        rescue
          Modulus.reply(origin, "Not found in #{dnsbl}.")
        end
      }
      
    end

    def done_connecting
    end
    
    def join(chan)
        Modulus.clients.clients["BanServ"].addChannel(chan)
    end

    def dbConnected
      $log.debug "BanServ", "Received database_connected callback. Beginning database check."

      #unless Quote.table_exists?
        #ActiveRecord::Schema.define do
          #create_table :quotes do |t|
            #t.column :added_by_nick, :string, :null => false
            #t.column :date_added, :datetime, :null => false
            #t.column :place_added, :string, :null => false
            #t.column :content, :string, :null => false
            #t.column :rank, :integer, :default => 0
            #t.column :views, :integer, :default => 0
          #end
        #end
      #end

    end

    class Regexkill < ActiveRecord::Base
    end

    class Autokill < ActiveRecord::Base
    end

  end #class 

end #module Modulus
