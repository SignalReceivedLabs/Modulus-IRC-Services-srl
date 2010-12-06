#!/usr/bin/ruby
#
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

NAME="Modulus IRC Services"
VERSION="0.1-pre-alpha"

require 'optparse'

Dir.chdir(File.dirname(__FILE__))

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.separator ""
  opts.separator "Specific $options:"

  $options[:fork] = true
  opts.on("-f", "--foreground", "Do not fork into the background.") do |v|
    $options[:fork] = false
  end
  $options[:configFile] = 'services.conf'
  opts.on("-c", "--config-file FILE", "Use specified file instead of services.conf.") do |fi|
    $options[:configFile] = fi
  end

end.parse!

# Load all files in the given directory under the working directory.
# @param [String] dir The base directory from which files will be recursively required.
# @example
# enumerateIncludes("includes")
def enumerateIncludes(dir)
  begin
    Dir["./#{dir}/**/*.rb"].each { |f| require(f) }
  rescue => e
    $stderr.puts "Failed loading files in #{dir}: #{e}"
    exit -1
  end
end

# Let's get this out of the way first.
enumerateIncludes("includes")

# Now that we have the application loaded, let's go ahead and bring out configuration into memory.
# We'll be needing it before we can do any real work, anyway.
# I've gone ahead and made this global for now. Maybe that will change as this gets bigger.
config = Modulus::Config.new("#{$options[:configFile]}")

# Okay, we got that taken care of. We're going to want to log as much as we
# can. Now that we know where to store logs, go ahead and start the logger.
# We'll make this a global variable so we can log from anywhere.

#$log = Modulus::Log.new("#{config.getOption('Core', 'log_location')}", config.getOption('Core', 'log_rotation_period'))

Modulus::Services.new(config)
