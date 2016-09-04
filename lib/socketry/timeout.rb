# frozen_string_literal: true
module Socketry
  module Timeout
    # Default timeouts (in seconds)
    DEFAULTS = {
      read:    5,
      write:   5,
      connect: 5
    }.freeze
  end
end
