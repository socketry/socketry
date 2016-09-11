# frozen_string_literal: true

module Socketry
  # Transmission Control Protocol
  module TCP
    # Transmission Control Protocol sockets: Provide stream-like semantics
    class Socket
      include Socketry::Timeout

      attr_reader :remote_addr, :remote_port, :local_addr, :local_port
      attr_reader :read_timeout, :write_timeout, :resolver, :socket_class

      def self.connect(remote_addr, remote_port, **args)
        new.connect(remote_addr, remote_port, **args)
      end

      def initialize(
        read_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:read],
        write_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:write],
        timer: Socketry::Timeout::DEFAULT_TIMER.new,
        resolver: Socketry::Resolver::DEFAULT_RESOLVER,
        socket_class: ::Socket
      )
        @read_timeout = read_timeout
        @write_timeout = write_timeout

        @socket_class = socket_class
        @resolver = resolver

        @family = nil
        @socket = nil

        @remote_addr = nil
        @remote_port = nil
        @local_addr  = nil
        @local_port  = nil

        start_timer(timer)
      end

      def connect(
        remote_addr,
        remote_port,
        local_addr: nil,
        local_port: nil,
        timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:connect]
      )
        ensure_disconnected

        @remote_addr = remote_addr
        @remote_port = remote_port
        @local_addr  = local_addr
        @local_port  = local_port

        begin
          set_timeout(timeout)

          remote_addr = @resolver.resolve(remote_addr, timeout: time_remaining(timeout))
          local_addr  = @resolver.resolve(local_addr,  timeout: time_remaining(timeout)) if local_addr
          raise ArgumentError, "expected IPAddr from resolver, got #{remote_addr.class}" unless remote_addr.is_a?(IPAddr)

          if remote_addr.ipv4?
            @family = ::Socket::AF_INET
          elsif remote_addr.ipv6?
            @family = ::Socket::AF_INET6
          else raise Socketry::AddressError, "unsupported IP address family: #{remote_addr}"
          end

          socket = @socket_class.new(@family, ::Socket::SOCK_STREAM, 0)
          socket.bind Addrinfo.tcp(local_addr.to_s, local_port) if local_addr
          remote_sockaddr = ::Socket.sockaddr_in(remote_port, remote_addr.to_s)

          # Note: `exception: false` for Socket#connect_nonblock is only supported in Ruby 2.3+
          begin
            socket.connect_nonblock(remote_sockaddr)
          rescue Errno::EINPROGRESS, Errno::EALREADY
            # JRuby does not seem to correctly support Socket#wait_writable in this case
            retry if IO.select(nil, [socket], nil, time_remaining(timeout))

            socket.close
            raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
          rescue Errno::EISCONN
            # Sometimes raised when we've connected successfully
          end

          @socket = socket
        ensure
          clear_timeout(timeout)
        end

        self
      end

      def reconnect(timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:connect])
        ensure_disconnected
        raise StateError, "can't reconnect: never completed initial connection" unless @remote_addr
        connect(@remote_addr, @remote_port, local_addr: @local_addr, local_port: @local_port, timeout: timeout)
      end

      def from_socket(socket)
        ensure_disconnected
        raise TypeError, "expected #{@socket_class}, got #{socket.class}" unless socket.is_a?(@socket_class)
        @socket = socket
        self
      end

      def read_nonblock(size)
        ensure_connected
        @socket.read_nonblock(size, exception: false)
      rescue IO::WaitReadable
        # Some buggy Rubies continue to raise this exception
        :wait_readable
      end

      def write_nonblock(data)
        ensure_connected
        @socket.write_nonblock(data, exception: false)
      rescue IO::WaitWriteable
        # Some buggy Rubies continue to raise this exception
        :wait_writable
      end

      def nodelay
        ensure_connected
        @socket.getsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY).int.nonzero?
      end

      def nodelay=(flag)
        ensure_connected
        @socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, flag ? 1 : 0)
      end

      def to_io
        ensure_connected
        @socket.to_io
      end

      def close
        return false unless connected?
        @socket.close
        true
      ensure
        @socket = nil
      end

      def connected?
        @socket != nil
      end

      private

      def ensure_connected
        return true if connected?
        raise StateError, "not connected"
      end

      def ensure_disconnected
        return true unless connected?
        raise StateError, "already connected"
      end
    end
  end
end
