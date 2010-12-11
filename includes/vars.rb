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

  def self.events
    @@events
  end

  def self.users
    @@users
  end

  def self.channels
    @@channels
  end

  def self.serviceModules
    @@serviceModules
  end

  def self.cmdHooks
    @@cmdHooks
  end

  def self.messageHooks
    @@messageHooks
  end

  def self.hooks
    @@hooks
  end

  def self.scheduler
    @@scheduler
  end

  def self.hostname
    @@hostname
  end

  def self.name
    @@name
  end

  def self.config
    @@config
  end

  def self.link
    @@link
  end

end #module Modulus
