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

  class Services

    attr_reader :clients, :link, :hostname, :name, :config, :events

    def initialize(config)
      @config = config

      @clients = Modulus::Clients.new(self)
      @serviceModules = Modulus::ServiceModules.new(self)
      @events = Modulus::Events.new

      @hooks = Hash.new
      @cmdHooks = Hash.new
      @messageHooks = Hash.new
      
      @hostname = config.getOption("Core", "services_hostname")
      @name = config.getOption("Core", "services_name")

      $log = Modulus::Log.new(self, config)

      $log.info "core", "#{NAME} version #{VERSION} is starting."

      protocol = config.getOption('Network', 'link_protocol')

      $log.debug "core", "Checking for protocol handler for #{protocol}."

      if File.exists? "protocols/#{protocol}.rb"
        $log.debug "core", "Handler exists."
      else
        $log.fatal "core", "No handler exists for #{protocol}."
        $stderr.puts "Fatal Error: Could not find the handler for link protocol #{protocol}."
        exit -1
      end

      load("protocols/#{protocol}.rb")

      @link = Modulus::ProtocolAbstraction.new(config, self)

      trap("INT"){ @link.closeConnection() }
      trap("TERM"){ @link.closeConnection() }
      trap("KILL"){ exit } # Kill (signal 9) is pretty hardcore. Just exit!

      trap("HUP", "IGNORE") # TODO: Rehash.

      #@link.createPreSyncClient('Global', "Global Noticer")
      #
      @clients.addClient(self, 'Global', "Global Noticer")

      #link.createClient(servName, config.getOption('Network', 'services_user'), config.getOption('Network', 'services_hostname'))

      Dir["./modules/*"].each { |servDir|
        servName = File.basename servDir
        $log.debug "core", "Attemping to load module #{servName}."

        Dir["#{servDir}/*.rb"].each { |file|
          load(file)
        }

        eval("#{servName}.new(self)")
      }

      #@clients.connectAll

      $log.debug "core", "Connecting."
      thread = startConnectionThread

      @clients.joinLogChan
      Modulus.startDB(self)


      $log.info "core", "IRC Services has started successfully."
      thread.join
    end

    def reply(origin, replyFrom,  message)
      @link.sendNotice(replyFrom, origin.source, message)
    end

    def runHooks(origin)
      if @hooks.has_key? origin.type

      $log.debug "core", "Running all hooks of type #{origin.type}"

        @hooks[origin.type].each { |hook|
          hook.run(origin)
        }
      end

      if @messageHooks.has_key? origin.target
        if @messageHooks[origin.target].has_key? origin.type

          $log.debug "core", "Running all message hooks of type #{origin.type}"

          @messageHooks[origin.target][origin.type].each { |hook|
            hook.run(origin)
          }
        end
      end
    end

    def runCmds(cmdOrigin)
      if @cmdHooks.has_key? cmdOrigin.target
        if @cmdHooks[cmdOrigin.target].has_key? cmdOrigin.cmd

          $log.debug "core", "Running all command hooks for #{cmdOrigin.cmd}"

          @cmdHooks[cmdOrigin.target][cmdOrigin.cmd].each { |hook|
            hook.run(cmdOrigin)
          }
        end
      end
    end

    def addService(name, modClass, description)
      @serviceModules.addService(name, modClass, description)
    end

    def addCmd(modClass, receiver, cmdStr, funcName, shortHelp, longHelp="")
      cmdStr.upcase!
      @cmdHooks[receiver] = Hash.new unless @cmdHooks.has_key? receiver
      @cmdHooks[receiver][cmdStr] = Array.new unless @cmdHooks[receiver].has_key? cmdStr

      $log.debug "core", "Adding command hook: #{cmdStr} for #{modClass.class}"

      hook = Command.new(self, modClass, funcName, cmdStr, shortHelp, longHelp)

      @cmdHooks[receiver][cmdStr] << hook
    end


    def addMessageHook(modClass, funcName, hookType, receiver)
      @messageHooks[receiver] = Hash.new unless @messageHooks.has_key? receiver
      @messageHooks[receiver][hookType] = Array.new unless @messageHooks[receiver].has_key? hookType

      $log.debug "core", "Adding message hook: type #{hookType} for #{modClass.class}"

      hook = Hook.new(self, modClass, funcName)

      @messageHooks[receiver][hookType] << hook
    end

    def addHook(modClass, funcName, hookType)
      @hooks[hookType] = Array.new unless @hooks.has_key? hookType
      $log.debug "core", "Adding hook: type #{hookType} for #{modClass.class}"

      hook = Hook.new(self, modClass, funcName)

      @hooks[hookType] << hook
    end

    def startConnectionThread
      @link.connect(@clients.clients.values)
    end

  end #class 

end #module Modulus
