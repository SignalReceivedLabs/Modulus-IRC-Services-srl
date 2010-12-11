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

  class HostServ

    def initialize(services)
      @services = services

      services.addService("HostServ", self,
                         "Vanity Host Name Assignment Service
 
HostServ allows users and staff to create vanity host
names to hide or replace their normal host name.")

      services.events.register(:database_connected, self, "dbConnected")
      services.events.register(:connect, self, "on_connect")
      services.events.register(:logged_in, self, "on_log_in")


      services.clients.addClient(@services, "HostServ", "Vanity Host Name Assignment Service")



      services.addCmd(self, "HostServ", "SET", "cmd_hs_set",
                     "Set or request a vanity host name.",
                     "Usage: SET hostname
 
You must be logged in to your services account to use this command.
 
Your account will be assigned the given host name. On most networks,
the host name will not become active without staff approval. If so,
staff will be notified as soon as your request is made. When the
host name is approved, it will be automatically activated and you
will be notified of the approval.
 
Host names are often restricted so that they may not contain certain
things, such as common TLDs (.com, .net, etc.) in order to reduce
abuse. Staff may be able to override this limitation on request.")

      services.addCmd(self, "HostServ", "REMOVE", "cmd_hs_remove",
                     "Remove your vanity host name.",
                     "Usage: REMOVE
 
Your host name will instantly be deactivated and deleted. This
action is permanent. If you would like your vanity host name
undeleted, you must attempt to set it as a new one.")

      services.addCmd(self, "HostServ", "ON", "cmd_hs_on",
                     "Activate your vanity host name.",
                     "Usage: ON
 
If your services account has a host name which has been approved, it
will be activated and applied to your current connection.")

      services.addCmd(self, "HostServ", "OFF", "cmd_hs_off",
                     "Deactivate your vanity host name.",
                     "Usage: OFF
 
Regardless of whether or not your services account has an active host
name or whether you are even logged in to a services account, this
command will clear all virtual or vanity hosts from your current
connection, returning your shown host name to that set by the IRC
server.")

      services.addCmd(self, "HostServ", "APPROVE", "cmd_hs_approve",
                     "Approve a pending host name request.",
                     "Usage: APPROVE username
 
This is a services administrator command.
                      
The host name for the given services account user name will be set
to approved and instantly activated for the user. The user will be
able to activate or deactivate the host name using HostServ commands.")

      services.addCmd(self, "HostServ", "REJECT", "cmd_hs_reject",
                     "Reject a pending host name request.",
                     "Usage: REJECT username
 
This is a services administrator command.
 
The host name for the given services account user will be denied and
deleted. The user will be notified of the failure if they are on-line.")
    end

    def on_connect(origin)
  
    end

    def on_log_in(user)
      user = user[0]
      default = @services.config.getOption("HostServ", "default_vhost")

      return if default == nil
      return if default.length == 0

      # TODO: Make this less dumb.
      default.gsub!("%u", user.svid)

      self.activate(user.nick, default)
    end

    def activate(nick, host)
      user = @services.users.find(nick)
      return if user == nil

      if user.vhost != host and user.hostname != host
        @services.link.changeHostname(nick, "HostServ", host)
      end
    end

    def deactivate(nick)
      user = @services.users.find(nick)

      return if user == nil

      @services.link.removeHostname(nick, "HostServ")
    end

    def cmd_hs_set(origin)
      $log.debug "HostServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        @services.reply(origin, "Usage: SET hostname")
        return
      end

      user = @services.users.find(origin.source)
      return if user == nil

      account = Account.find_by_username(user.svid)

      if account == nil
        @services.reply(origin, "You must be logged in to a valid services account to use this command.")
        return
      end

      hostname = origin.argsArr[0]
      restricted = @services.config.getOption("HostServ", "restricted_hostnames").split(" ")

      restricted.each { |restr|
        restr.gsub!("*", ".*")

        if hostname.match(restr)
          @services.reply(origin, "The host name you provided is not permitted on this network.")
          return
        end
      }

      approval = @services.config.getBool("HostServ", "oper_approval")

      oldHost = Host.find_by_account_id(account.id)

      if oldHost == nil
        Host.create(
          :account_id => account.id,
          :date_added => DateTime.now,
          :hostname => hostname,
          :approved => !approval)
      else
        oldHost.hostname = hostname
        oldHost.date_added = DateTime.now
        oldHost.save!
        oldHost.approved = !approval
      end

      if approval
        @services.reply(origin, "The host name you provided is not permitted on this network.")
        $log.info 'HostServ', "Action required: #{origin.source} has requested host name: #{hostname}"
      else
        self.activate(origin.source, hostname)

        @services.reply(origin, "The host name you provided has been saved and activated.")
        $log.info 'HostServ', "#{origin.source} has requested and activated host name: #{hostname}"
      end
    end

    def cmd_hs_approve(origin)
      $log.debug "HostServ", "Got: #{origin.raw}"

      if origin.argsArr.length != 1
        @services.reply(origin, "Usage: APPROVE username")
        return
      end 
    end

    def cmd_hs_deny(origin)
      $log.debug "HostServ", "Got: #{origin.raw}"

    end

    def cmd_hs_remove(origin)
      $log.debug "HostServ", "Got: #{origin.raw}"

    end

    def cmd_hs_on(origin)
      $log.debug "HostServ", "Got: #{origin.raw}"

      
    end

    def cmd_hs_off(origin)
      $log.debug "HostServ", "Got: #{origin.raw}"

      self.deactivate(origin.source)
      @services.reply(origin, "Your host mask has been deactivated.")
    end

    def dbConnected
      $log.debug "HostServ", "Received database_connected callback. Beginning database check."

      unless Host.table_exists?
        ActiveRecord::Schema.define do
          create_table :hosts do |t|
            t.column :account_id, :integer, :null => false
            t.column :date_added, :datetime, :null => false
            t.column :hostname, :string, :null => false
            t.column :approved, :boolean, :default => false
            t.column :active, :boolean, :default => true
          end
        end
      end

    end

    class Host < ActiveRecord::Base
      belongs_to :account
    end

  end #class 

end #module Modulus
