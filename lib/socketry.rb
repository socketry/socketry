# frozen_string_literal: true

# Ruby stdlib dependencies
require "io/wait"
require "ipaddr"
require "socket"
require "openssl"

# External gems
require "hitimes"

# Socketry codebase
require "socketry/version"

require "socketry/exceptions"
require "socketry/resolver/resolv"
require "socketry/resolver/system"
require "socketry/timeout"

require "socketry/tcp/server"
require "socketry/tcp/socket"
require "socketry/ssl/server"
require "socketry/ssl/socket"
require "socketry/udp/datagram"
require "socketry/udp/socket"
