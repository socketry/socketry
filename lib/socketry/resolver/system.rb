# frozen_string_literal: true

require "timeout"

module Socketry
  module Resolver
    # System DNS resolver backed by the POSIX getaddrinfo(3) function
    module System
      module_function

      def resolve(hostname, timeout: nil)
        raise TypeError, "expected String, got #{hostname.class}" unless hostname.is_a?(String)

        begin
          case timeout
          when Integer, Float
            result = ::Timeout.timeout(timeout) { IPSocket.getaddress(hostname) }
          when NilClass
            result = IPSocket.getaddress(hostname)
          else raise TypeError, "expected Numeric, got #{timeout.class}"
          end
        rescue ::SocketError => ex
          raise Resolver::Error, ex.message, ex.backtrace
        rescue ::Timeout::Error => ex
          raise Socketry::TimeoutError, ex.message, ex.backtrace
        end

        Socketry::Resolver.addr(result)
      end
    end
  end
end
