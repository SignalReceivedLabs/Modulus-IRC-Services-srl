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

    attr_reader :clients, :link, :hostname, :name

    def initialize(config)
      @clients = Modulus::Clients.new
      @serviceModules = Modulus::ServiceModules.new(self)
      @hooks = Hash.new
      @messageHooks = Hash.new
      
      @hostname = config.getOption("Core", "services_hostname")
      @name = config.getOption("Core", "services_name")

      $log = Modulus::Log.new(self, config)

      $log.info "preload", "#{NAME} version #{VERSION} is starting."

      protocol = config.getOption('Network', 'link_protocol')

      $log.debug "preload", "Checking for protocol handler for #{protocol}."

      if File.exists? "protocols/#{protocol}.rb"
        $log.debug "preload", "Handler exists."
      else
        $log.fatal "preload", "No handler exists for #{protocol}."
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
        $log.debug "preload", "Attemping to load module #{servName}."

        Dir["#{servDir}/*.rb"].each { |file|
          load(file)
        }

        eval("#{servName}.new(self)")
      }

      #@clients.connectAll

      $log.debug "preload", "Connecting."
      startConnectionThread.join
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

    def addService(name, modClass)
      @serviceModules.addService(name, modClass)
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
      @link.connect(@clients.clients.values).join
    end

  end #class 

end #module Modulus
