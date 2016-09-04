# frozen_string_literal: true

require "forwardable"
require "io/wait"
require "ipaddr"
require "socket"

require "socketry/version"

require "socketry/exceptions"
require "socketry/resolver/resolv"
require "socketry/resolver/system"
require "socketry/tcp/socket"
require "socketry/timeout"
require "socketry/timeout/null"
require "socketry/timeout/per_operation"
require "socketry/timeout/global"
