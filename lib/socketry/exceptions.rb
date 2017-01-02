# frozen_string_literal: true

module Socketry
  # Generic catch all for all Socketry errors
  Error = Class.new(StandardError)

  # Failed to connect to a host
  ConnectError = Class.new(Socketry::Error)

  # Remote host confused connection
  ConnectionRefusedError = Class.new(Socketry::ConnectError)

  # Requested host is down
  HostDownError = Class.new(Socketry::ConnectError)

  # Invalid address
  AddressError = Class.new(Socketry::Error)

  # Address is already in use
  AddressInUseError = Class.new(Socketry::Error)

  # Timeouts performing an I/O operation
  TimeoutError = Class.new(Socketry::Error)

  # Cannot perform operation in current state
  StateError = Class.new(Socketry::Error)

  # Internal consistency error within the library
  InternalError = Class.new(Socketry::Error)

  module Resolver
    # DNS resolution errors
    Error = Class.new(Socketry::AddressError)
  end

  module SSL
    # Errors related to SSL
    Error = Class.new(Socketry::Error)

    # Certificate could not be verified
    CertificateVerifyError = Class.new(Socketry::SSL::Error)

    # Hostname verification error
    HostnameError = Class.new(CertificateVerifyError)
  end
end
