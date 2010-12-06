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
  require 'rubygems'
  require 'active_record'

  def Modulus.startDB(services)
    $log.info 'database', 'Starting database connection for the first time this session.'

    type = services.config.getOption('Database', 'database_type')
    type.downcase! unless type == nil

    validAdapters = ["sqlite3","mysql","postgresql"]

    unless validAdapters.include? type
      # If we ever get here, something really bad must have happened.
      $stderr.puts "Fatal error: Invalid database type selected in database_type. Must be one of: #{validAdapters.join(", ")}."
      exit -1
    end

    ActiveRecord::Base.logger = $log.logger
    ActiveRecord::Base.colorize_logging = false

    $log.debug 'database', "Connecting to #{type} database."

    case type
      when "sqlite3"
        # This is the filename. It's all we need. Sweet!
        name = services.config.getOption('Database', 'database_name')

        ActiveRecord::Base.establish_connection(
          :adapter => "sqlite3",
          :database => name)

      when "mysql"
        host = services.config.getOption('Database', 'database_address')
        user = services.config.getOption('Database', 'database_user_name')
        password = services.config.getOption('Database', 'database_password')
        name = services.config.getOption('Database', 'database_name')

        ActiveRecord::Base.establish_connection(
          :adapter => "mysql",
          :host => host,
          :username => username,
          :password => password,
          :database => name)


      when "postgresql"
        host = services.config.getOption('Database', 'database_address')
        user = services.config.getOption('Database', 'database_user_name')
        password = services.config.getOption('Database', 'database_password')
        name = services.config.getOption('Database', 'database_name')

        ActiveRecord::Base.establish_connection(
          :adapter => "mysql",
          :host => host,
          :username => username,
          :password => password,
          :database => name)

    end

    $log.debug 'database', "Connection to database successful."
    services.events.event(:database_connected)

  end
end #module Modulus
