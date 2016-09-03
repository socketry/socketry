# frozen_string_literal: true

module Socketry
  # Generic catch all for all Socketry errors
  Error = Class.new(IOError)

  # Invalid address
  AddressError = Class.new(Error)

  # Timeouts performing an I/O operation
  TimeoutError = Class.new(Error)

  # Cannot perform operation in current state
  StateError = Class.new(Error)

  module Resolver
    # DNS resolution errors
    Error = Class.new(AddressError)
  end
end
