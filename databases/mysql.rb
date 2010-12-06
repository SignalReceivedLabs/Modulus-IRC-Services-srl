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

  class Database

    require 'mysql'

    def initialize(services)
      @services = services
      type = services.config.getOption('database', 'database_type')

      if type != 'mysql'
        # If we ever get here, something really bad must have happened.
        $stderr.puts "Fatal error: MySQL was not selected as the database type, but the module was loaded anyway."
        exit -1
      end

      @host = services.config.getOption('database', 'database_address')
      @user = services.config.getOption('database', 'database_user_name')
      @password = services.config.getOption('database', 'database_password')
      @name = services.config.getOption('database', 'database_name')
      @prefix = services.config.getOption('database', 'database_table_prefix')
    end

    def connect
      $log.debug 'mysql', "Connecting to MySQL database at #{@host} with as #{@user}."
      begin
        @db = Mysql.new(@host, @user, @password, @name)
        $log.debug 'mysql', "Connecting to MySQL database at #{@host} with as #{@user}."
      rescue => e
        $log.fatal 'mysql', "Could not connect to the MySQL database at #{@host} with as #{@user}: #{e}"
        $stderr.puts "Could not connect to the MySQL database at #{@host} with as #{@user}: #{e}"
        exit -1
      end
    end

    def initDB

    end

  end #class Database

end #module Modulus
