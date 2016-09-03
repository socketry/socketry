# frozen_string_literal: true

require "socket"

require "socketry/version"

require "socketry/exceptions"
require "socketry/resolver"
require "socketry/resolver/resolv"
require "socketry/resolver/system"
require "socketry/timeout/null"
require "socketry/timeout/per_operation"
require "socketry/timeout/global"
