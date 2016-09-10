# frozen_string_literal: true

require "forwardable"
require "io/wait"
require "ipaddr"
require "socket"
require "openssl"

require "socketry/version"

require "socketry/exceptions"
require "socketry/resolver/resolv"
require "socketry/resolver/system"
require "socketry/timeout"
require "socketry/timeout/null"
require "socketry/timeout/per_operation"
require "socketry/timeout/global"

require "socketry/tcp/socket"
require "socketry/tcp/server"
require "socketry/ssl/socket"
