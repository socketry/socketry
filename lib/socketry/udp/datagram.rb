# frozen_string_literal: true

module Socketry
  # User Datagram Protocol: "fire-and-forget" packet protocol
  module UDP
    # Represents a received UDP message
    class Datagram
      attr_reader :message, :sockaddr, :remote_host, :remote_addr, :remote_port

      def initialize(message, sockaddr)
        @message  = message
        @sockaddr = sockaddr
        @remote_port = sockaddr[1]
        @remote_host = sockaddr[2]
        @remote_addr = sockaddr[3]
      end

      def addrinfo
        addr_family = case @sockaddr[0]
                      when "AF_INET"  then ::Socket::AF_INET
                      when "AF_INET6" then ::Socket::AF_INET6
                      else raise Socketry::AddressError, "unsupported IP address family: #{@sockaddr[0]}"
                      end

        Addrinfo.new(@sockaddr, addr_family, ::Socket::SOCK_DGRAM)
      end
    end
  end
end
