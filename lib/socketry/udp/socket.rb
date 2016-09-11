# frozen_string_literal: true

module Socketry
  # User Datagram Protocol: "fire-and-forget" packet protocol
  module UDP
    # User Datagram Protocol sockets
    class Socket
      include Socketry::Timeout

      attr_reader :read_timeout, :write_timeout, :resolver, :socket_class

      def self.from_addr(remote_addr, resolver: Socketry::Resolver::DEFAULT_RESOLVER)
        addr = resolver.resolve(remote_addr)
        if addr.ipv4?
          new(family: :ipv4)
        elsif addr.ipv6?
          new(family: :ipv6)
        else raise Socketry::AddressError, "unsupported IP address family: #{addr}"
        end
      end

      def self.bind(remote_addr, remote_port, resolver: Socketry::Resolver::DEFAULT_RESOLVER)
        from_addr(remote_addr, resolver: resolver).bind(remote_addr, remote_port)
      end

      def self.connect(remote_addr, remote_port, resolver: Socketry::Resolver::DEFAULT_RESOLVER)
        from_addr(remote_addr, resolver: resolver).connect(remote_addr, remote_port)
      end

      def initialize(
        family: :ipv4,
        read_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:read],
        write_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:write],
        timer: Socketry::Timeout::DEFAULT_TIMER.new,
        resolver: Socketry::Resolver::DEFAULT_RESOLVER,
        socket_class: ::UDPSocket
      )
        case family
        when :ipv4
          @address_family = ::Socket::AF_INET
        when :ipv6
          @address_family = ::Socket::AF_INET6
        when ::Socket::AF_INET, ::Socket::AF_INET6
          @address_family = address_family
        else raise ArgumentError, "invalid address family: #{address_family.inspect}"
        end

        @socket        = socket_class.new(@address_family)
        @read_timeout  = read_timeout
        @write_timeout = write_timeout
        @resolver      = resolver

        start_timer(timer)
      end

      def bind(remote_addr, remote_port)
        @socket.bind(@resolver.resolve(remote_addr), remote_port)
        self
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end

      def connect(remote_addr, remote_port)
        @socket.connect(@resolver.resolve(remote_addr), remote_port)
        self
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end

      def recvfrom_nonblock(maxlen)
        @socket.recvfrom_nonblock(maxlen)
      rescue ::IO::WaitReadable
        :wait_readable
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end

      def recvfrom(maxlen)
        set_timeout(@read_timeout)

        begin
          while (result = recvfrom_nonblock(maxlen)) == :wait_readable
            next if @socket.wait_readable(time_remaining(@read_timeout))
            raise Socketry::TimeoutError, "recvfrom timed out after #{@read_timeout} seconds"
          end
        ensure
          clear_timeout(@read_timeout)
        end

        result
      end

      def send(msg, host:, port:)
        @socket.send(msg, 0, @resolver.resolve(host), port)
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end
    end
  end
end
