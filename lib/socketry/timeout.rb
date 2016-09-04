# frozen_string_literal: true
module Socketry
  module Timeout
    # Default timeouts (in seconds)
    DEFAULTS = {
      read:    0.25,
      write:   0.25,
      connect: 0.25
    }.freeze
  end
end
