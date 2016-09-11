# frozen_string_literal: true

require "io/wait"
require "ipaddr"
require "socket"
require "openssl"

require "socketry/version"

require "socketry/exceptions"
require "socketry/resolver/resolv"
require "socketry/resolver/system"
require "socketry/timeout"

require "socketry/tcp/server"
require "socketry/tcp/socket"
require "socketry/ssl/server"
require "socketry/ssl/socket"
require "socketry/udp/socket"
