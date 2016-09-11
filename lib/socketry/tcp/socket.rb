# frozen_string_literal: true

module Socketry
  # Transmission Control Protocol
  module TCP
    # Transmission Control Protocol sockets: Provide stream-like semantics
    class Socket
      include Socketry::Timeout

      attr_reader :remote_addr, :remote_port, :local_addr, :local_port
      attr_reader :read_timeout, :write_timeout, :resolver, :socket_class

      # Create a Socketry::TCP::Socket with the default options, then connect
      # to the given host.
      #
      # @param remote_addr [String] DNS name or IP address of the host to connect to
      # @param remote_port [Fixnum] TCP port to connect to
      # @return [Socketry::TCP::Socket]
      def self.connect(remote_addr, remote_port, **args)
        new.connect(remote_addr, remote_port, **args)
      end

      # Create an unconnected Socketry::TCP::Socket
      #
      # @param read_timeout  [Numeric] Seconds to wait before an uncompleted read errors
      # @param write_timeout [Numeric] Seconds to wait before an uncompleted write errors
      # @param timer         [Object]  A timekeeping object to use for measuring timeouts
      # @param resolver      [Object]  A resolver object to use for resolving DNS names
      # @param socket_class  [Object]  Underlying socket class which implements I/O ops
      # @return [Socketry::TCP::Socket]
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

      # Connect to a remote host
      #
      # @param remote_addr  [String]  DNS name or IP address of the host to connect to
      # @param remote_port  [Fixnum]  TCP port to connect to
      # @param local_addr   [String]  DNS name or IP address to bind to locally
      # @param local_port   [Fixnum]  Local TCP port to bind to
      # @param timeout      [Numeric] Number of seconds to wait before aborting connect
      # @param socket_class [Class]   Custom low-level socket class
      # @raise [Socketry::AddressError] an invalid address was given
      # @raise [Socketry::TimeoutError] connect operation timed out
      # @return [self]
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
            # Earlier JRuby 9.x versions do not seem to correctly support Socket#wait_writable in this case
            # Newer versions seem to behave correctly
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

      # Re-establish a lost TCP connection
      #
      # @param timeout [Numeric] Number of seconds to wait before aborting re-connect
      # @raise [Socketry::StateError] not in a disconnected state
      def reconnect(timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:connect])
        ensure_disconnected
        raise StateError, "can't reconnect: never completed initial connection" unless @remote_addr
        connect(@remote_addr, @remote_port, local_addr: @local_addr, local_port: @local_port, timeout: timeout)
      end

      # Create a Socketry::TCP::Socket from a low-level socket
      #
      # @param socket [::Socket] (or specified socket_class) low-level socket to wrap
      def from_socket(socket)
        ensure_disconnected
        raise TypeError, "expected #{@socket_class}, got #{socket.class}" unless socket.is_a?(@socket_class)
        @socket = socket
        self
      end

      # Perform a non-blocking read operation
      #
      # @param size [Fixnum] number of bytes to attempt to read
      # @param outbuf [String, NilClass] an optional buffer into which data should be read
      # @raise [Socketry::Error] an I/O operation failed
      # @return [String, :wait_readable] data read, or :wait_readable if operation would block
      def read_nonblock(size, outbuf = nil)
        ensure_connected
        case outbuf
        when String
          @socket.read_nonblock(size, outbuf, exception: false)
        when NilClass
          @socket.read_nonblock(size, exception: false)
        else raise TypeError, "unexpected outbuf class: #{outbuf.class}"
        end
      rescue IO::WaitReadable
        # Some buggy Rubies continue to raise this exception
        :wait_readable
      rescue IOError => ex
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Perform a non-blocking write operation
      #
      # @param data [String] number of bytes to attempt to read
      # @raise [Socketry::Error] an I/O operation failed
      # @return [String, :wait_readable] data read, or :wait_readable if operation would block
      def write_nonblock(data)
        ensure_connected
        @socket.write_nonblock(data, exception: false)
      rescue IO::WaitWriteable
        # Some buggy Rubies continue to raise this exception
        :wait_writable
      rescue IOError => ex
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Check whether Nagle's algorithm has been disabled
      #
      # @return [true]  Nagle's algorithm has been explicitly disabled
      # @return [false] Nagle's algorithm is enabled (default)
      def nodelay
        ensure_connected
        @socket.getsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY).int.nonzero?
      end

      # Disable or enable Nagle's algorithm
      #
      # @param flag [true, false] disable or enable coalescing multiple writesusing Nagle's algorithm
      def nodelay=(flag)
        ensure_connected
        @socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, flag ? 1 : 0)
      end

      # Return a raw Ruby I/O object
      #
      # @return [IO] Ruby I/O object
      def to_io
        ensure_connected
        ::IO.try_convert(@socket)
      end

      # Close the socket
      #
      # @return [true, false] true if the socket was open, false if closed
      def close
        return false unless connected?
        @socket.close
        true
      ensure
        @socket = nil
      end

      # Is the socket currently connected?
      #
      # This method returns the local connection state. However, it's possible
      # the remote side has closed the connection, so it's not actually
      # possible to actually know if the socket is actually still open without
      # reading from or writing to it. It's sort of like the Heisenberg
      # uncertainty principle of sockets.
      #
      # @return [true, false] do we locally think the socket is open?
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
