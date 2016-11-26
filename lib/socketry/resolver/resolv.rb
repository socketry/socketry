# frozen_string_literal: true

require "resolv"

module Socketry
  module Resolver
    # Pure Ruby DNS resolver provided by the standard library
    class Resolv
      # Resolve a hostname by creating and discaring a Socketry::Resolver::Resolv
      # instance. For better performance, create and reuse an instance.
      def self.resolve(hostname, **options)
        resolver = new
        begin
          resolver.resolve(hostname, **options)
        ensure
          resolver.close
        end
      end

      # Create a new instance of Socketry::Resolver::Resolv.
      #
      # Arguments are passed directly to Resolv::DNS. See the Ruby documentation
      # for more information:
      #
      # https://ruby-doc.org/stdlib-2.3.1/libdoc/resolv/rdoc/Resolv/DNS.html
      #
      def initialize(*args)
        @hosts = ::Resolv::Hosts.new
        @resolver = ::Resolv::DNS.new(*args)
      end

      # Resolve a domain name using IPSocket.getaddress. This uses getaddrinfo(3)
      # on POSIX operating systems.
      #
      # @param hostname [String] name of the host whose IP address we'd like to obtain
      # @return [IPAddr] resolved IP address
      # @raise [Socketry::Resolver::Error] an error occurred resolving the domain name
      # @raise [Socketry::TimeoutError] a timeout occured before the name could be resolved
      # @raise [Socketry::AddressError] the name was resolved to an unsupported address
      def resolve(hostname, timeout: nil)
        raise TypeError, "expected String, got #{hostname.class}" unless hostname.is_a?(String)
        return IPAddr.new(@hosts.getaddress(hostname).sub(/%.*$/, ""))
      rescue ::Resolv::ResolvError
        case timeout
        when Integer, Float
          @resolver.timeouts = timeout
        when NilClass
          nil # no timeout
        else raise TypeError, "expected Numeric, got #{timeout.class}"
        end

        begin
          IPAddr.new(@resolver.getaddress(hostname).to_s)
        rescue ::Resolv::ResolvError => ex
          raise Socketry::Resolver::Error, ex.message, ex.backtrace
        rescue ::Resolv::ResolvTimeout => ex
          raise Socketry::TimeoutError, ex.message, ex.backtrace
        end
      end

      # Close the resolver
      def close
        @resolver.close
      end
    end
  end
end
