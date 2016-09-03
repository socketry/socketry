# frozen_string_literal: true

module Socketry
  module Resolver
    # Pure Ruby DNS resolver provided by the standard library
    class Resolv
      def self.resolve(hostname, **options)
        resolver = new
        begin
          resolver.resolve(hostname, **options)
        ensure
          resolver.close
        end
      end

      def initialize(*args)
        @hosts = ::Resolv::Hosts.new
        @resolver = ::Resolv::DNS.new(*args)
      end

      def resolve(hostname, timeout: nil)
        raise TypeError, "expected String, got #{hostname.class}" unless hostname.is_a?(String)
        return Socketry::Resolver.addr(@hosts.getaddress(hostname).sub(/%.*$/, ""))
      rescue ::Resolv::ResolvError
        case timeout
        when Integer, Float
          @resolver.timeouts = timeout
        when NilClass
          # no timeout
        else raise TypeError, "expected Numeric, got #{timeout.class}"
        end

        begin
          @resolver.getaddress(hostname)
        rescue ::Resolv::ResolvError => ex
          raise Resolver::Error, ex.message, ex.backtrace
        rescue ::Resolv::ResolvTimeout => ex
          raise Socketry::TimeoutError, ex.message, ex.backtrace
        end
      end

      def close
        @resolver.close
      end
    end
  end
end
