# frozen_string_literal: true

module Socketry
  # DNS resolution subsystem
  module Resolver
    module_function

    def addr(address)
      return ::Resolv::IPv4.create(address)
    rescue ArgumentError
      begin
        return ::Resolv::IPv6.create(address)
      rescue ArgumentError
        raise Socketry::AddressError, "invalid address: #{address}"
      end
    end

    def resolve(address, resolver, **args)
      return addr(address)
    rescue Socketry::AddressError
      resolver.resolve(address, **args)
    end
  end
end
