# frozen_string_literal: true

module Socketry
  # Transmission Control Protocol
  module TCP
    # Transmission Control Protocol sockets: Provide stream-like semantics
    class Socket
      include Socketry::Timeout

      attr_reader :state
      attr_reader :addr_fmaily, :remote_addr, :remote_port, :local_addr, :local_port
      attr_reader :read_timeout, :write_timeout, :resolver, :socket_class

      # Create a Socketry::TCP::Socket with the default options, then connect
      # to the given host.
      #
      # @param remote_addr [String] DNS name or IP address of the host to connect to
      # @param remote_port [Fixnum] TCP port to connect to
      #
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
      #
      # @return [Socketry::TCP::Socket]
      def initialize(
        read_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:read],
        write_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:write],
        timer: Socketry::Timeout::DEFAULT_TIMER.new,
        resolver: Socketry::Resolver::DEFAULT_RESOLVER,
        socket_class: ::Socket
      )
        @state = :disconnected

        @read_timeout = read_timeout
        @write_timeout = write_timeout

        @socket_class = socket_class
        @resolver = resolver
        @addr_family = nil
        @socket = nil

        @remote_host = nil
        @remote_addr = nil
        @remote_port = nil
        @local_addr  = nil
        @local_port  = nil

        start_timer timer
      end

      # Connect to a remote host
      #
      # @param remote_host [String]  DNS name or IP address of the host to connect to
      # @param remote_port [Fixnum]  TCP port to connect to
      # @param local_addr  [String]  DNS name or IP address to bind to locally
      # @param local_port  [Fixnum]  Local TCP port to bind to
      # @param timeout     [Numeric] Number of seconds to wait before aborting connect
      #
      # @raise [Socketry::AddressError] an invalid address was given
      # @raise [Socketry::TimeoutError] connect operation timed out
      #
      # @return [self]
      def connect(
        remote_host,
        remote_port,
        local_addr: nil,
        local_port: nil,
        timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:connect]
      )
        ensure_state :disconnected

        begin
          set_timeout timeout

          remote_addr = @resolver.resolve(remote_host, timeout: time_remaining(timeout))
          raise ArgumentError, "expected IPAddr from resolver, got #{remote_addr.class}" unless remote_addr.is_a?(IPAddr)

          local_addr = @resolver.resolve(local_addr, timeout: time_remaining(timeout)).to_s if local_addr

          connect_nonblock(remote_addr.to_s, remote_port, local_addr: local_addr, local_port: local_port)
          @remote_host = remote_host

          return self if connected?

          # Earlier JRuby 9.x versions do not seem to correctly support Socket#wait_writable in this case
          # Newer versions seem to behave correctly
          _, writable = IO.select(nil, [@socket], nil, time_remaining(timeout))
          unless writable && writable.include?(@socket)
            close
            raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
          end

          complete_connect_nonblock
        ensure
          clear_timeout timeout
        end

        self
      end

      # Initiate a non-blocking connect operation to a remote IP address
      # DNS resolution is not performed (requires a blocking operation)
      #
      # @param remote_ip   [String, IPAddr] IP address of the host to connect to
      # @param remote_port [Fixnum] TCP port to connect to
      # @param local_addr  [String, IPAddr] IP address to bind to locally
      # @param local_port  [Fixnum] Local TCP port to bind to
      #
      # @raise [Socketry::AddressError] an invalid address was given
      #
      # @return [self, :wait_writable] self if connected, or :wait_writable if still in progress
      def connect_nonblock(
        remote_addr,
        remote_port,
        local_addr: nil,
        local_port: nil
      )
        ensure_state :disconnected

        # Verify addresses are well-formed
        begin
          remote_ipaddr = IPAddr.new(remote_addr)
          if remote_ipaddr.ipv4?
            @addr_family = ::Socket::AF_INET
          elsif remote_ipaddr.ipv6?
            @addr_family = ::Socket::AF_INET6
          else raise Socketry::AddressError, "unsupported IP address family: #{remote_ipaddr}"
          end

          IPAddr.new(local_addr) if local_addr
        rescue IPAddr::InvalidAddressError
          raise Socketry::AddressError, "not a valid IP address"
        end

        @remote_addr = remote_addr
        @remote_port = remote_port
        @local_addr  = local_addr
        @local_port  = local_port

        @socket = @socket_class.new(@addr_family, ::Socket::SOCK_STREAM, 0)
        @socket.bind Addrinfo.tcp(@local_addr, @local_port) if local_addr

        change_state :connecting
        complete_connect_nonblock
      end

      # Complete a non-blocking connection which is in progress
      #
      # @return [self] self if connected, or :wait_writable if still in progress
      def complete_connect_nonblock
        ensure_state :connecting

        begin
          remote_sockaddr = ::Socket.sockaddr_in(@remote_port, @remote_addr)

          # Note: `exception: false` for Socket#connect_nonblock is only supported in Ruby 2.3+
          # TODO: use `exception: false` when we drop support for Ruby 2.2
          @socket.connect_nonblock(remote_sockaddr)
        rescue Errno::ECONNREFUSED
          close
          raise Socketry::ConnectionRefusedError, "connection to #{@remote_addr}:#{@remote_port} refused"
        rescue Errno::EHOSTDOWN
          close
          raise Socketry::HostDownError, "cannot connect to #{@remote_addr}: host is down"
        rescue Errno::EINPROGRESS, Errno::EALREADY
          return :wait_writable
        rescue Errno::EISCONN
          # Sometimes raised when we've connected successfully
        end

        change_state :connected
        self
      end

      # Re-establish a lost TCP connection
      #
      # @param timeout [Numeric] Number of seconds to wait before aborting re-connect
      # @raise [Socketry::StateError] not in a disconnected state
      def reconnect(timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:connect])
        ensure_state :disconnected
        raise StateError, "can't reconnect: never completed initial connection" unless @remote_addr

        connect(
          @remote_host || @remote_addr,
          @remote_port,
          local_addr: @local_addr,
          local_port: @local_port,
          timeout: timeout
        )
      end

      # Wrap a connected Ruby/low-level socket in an Socketry::TCP::Socket
      #
      # @param socket [::Socket] (or specified socket_class) low-level socket to wrap
      def from_socket(socket)
        ensure_state :disconnected
        raise TypeError, "expected #{@socket_class}, got #{socket.class}" unless socket.is_a?(@socket_class)
        @socket = socket
        @state  = :connected

        self
      end

      # Perform a non-blocking read operation
      #
      # @param size [Fixnum] number of bytes to attempt to read
      # @param outbuf [String, NilClass] an optional buffer into which data should be read
      #
      # @raise [Socketry::Error] an I/O operation failed
      #
      # @return [String, :wait_readable] data read, or :wait_readable if operation would block
      def read_nonblock(size, outbuf: nil)
        ensure_state :connected

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

      # Read a partial amount of data, blocking until it becomes available
      #
      # @param size [Fixnum] number of bytes to attempt to read
      # @param outbuf [String] an output buffer to read data into
      # @param timeout [Numeric] Number of seconds to wait for read operation to complete
      # @raise [Socketry::Error] an I/O operation failed
      # @return [String, :eof] bytes read, or :eof if socket closed while reading
      def readpartial(size, outbuf: nil, timeout: @read_timeout)
        set_timeout timeout

        begin
          while (result = read_nonblock(size, outbuf: outbuf)) == :wait_readable
            next if @socket.wait_readable(time_remaining(timeout))
            raise TimeoutError, "read timed out after #{timeout} seconds"
          end
        ensure
          clear_timeout timeout
        end

        result || :eof
      end

      # Read all of the data in a given string to a socket unless timeout or EOF
      #
      # @param size [Fixnum] number of bytes to attempt to read
      # @param outbuf [String] an output buffer to read data into
      # @param timeout [Numeric] Number of seconds to wait for read operation to complete
      #
      # @raise [Socketry::Error] an I/O operation failed
      #
      # @return [String, :eof] bytes read, or :eof if socket closed while reading
      def read(size, outbuf: "".b, timeout: @write_timeout)
        outbuf.clear
        deadline = lifetime + timeout if timeout

        begin
          until outbuf.size == size
            time_remaining = deadline - lifetime if deadline
            raise Socketry::TimeoutError, "read timed out after #{timeout} seconds" if timeout && time_remaining <= 0

            chunk = readpartial(size - outbuf.size, timeout: time_remaining)
            return :eof if chunk == :eof

            outbuf << chunk
          end
        end

        outbuf
      end

      # Perform a non-blocking write operation
      #
      # @param data [String] data to write to the socket
      #
      # @raise [Socketry::Error] an I/O operation failed
      #
      # @return [Fixnum, :wait_writable] number of bytes written, or :wait_writable if op would block
      def write_nonblock(data)
        ensure_state :connected
        @socket.write_nonblock(data, exception: false)
      rescue IO::WaitWritable
        # Some buggy Rubies continue to raise this exception
        :wait_writable
      rescue IOError => ex
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Write a partial amount of data, blocking until it's completed
      #
      # @param data [String] data to write to the socket
      # @param timeout [Numeric] Number of seconds to wait for write operation to complete
      # @raise [Socketry::Error] an I/O operation failed
      # @return [Fixnum, :eof] number of bytes written, or :eof if socket closed during writing
      def writepartial(data, timeout: @write_timeout)
        set_timeout timeout

        begin
          while (result = write_nonblock(data)) == :wait_writable
            next if @socket.wait_writable(time_remaining(timeout))
            raise TimeoutError, "write timed out after #{timeout} seconds"
          end
        ensure
          clear_timeout timeout
        end

        result || :eof
      end

      # Write all of the data in a given string to a socket unless timeout or EOF
      #
      # @param data [String] data to write to the socket
      # @param timeout [Numeric] Number of seconds to wait for write operation to complete
      #
      # @raise [Socketry::Error] an I/O operation failed
      #
      # @return [Fixnum] number of bytes written, or :eof if socket closed during writing
      def write(data, timeout: @write_timeout)
        total_written = data.size
        deadline = lifetime + timeout if timeout

        begin
          until data.empty?
            time_remaining = deadline - lifetime if deadline
            raise Socketry::TimeoutError, "write timed out after #{timeout} seconds" if timeout && time_remaining <= 0

            bytes_written = writepartial(data, timeout: time_remaining)
            return :eof if bytes_written == :eof

            break if bytes_written == data.bytesize
            data = data.byteslice(bytes_written..-1)
          end
        end

        total_written
      end

      # Check whether Nagle's algorithm has been disabled
      #
      # @return [true]  Nagle's algorithm has been explicitly disabled
      # @return [false] Nagle's algorithm is enabled (default)
      def nodelay
        ensure_state :connected
        @socket.getsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY).int.nonzero?
      end

      # Disable or enable Nagle's algorithm
      #
      # @param flag [true, false] disable or enable coalescing multiple writes using Nagle's algorithm
      def nodelay=(flag)
        ensure_state :connected
        @socket.setsockopt(::Socket::IPPROTO_TCP, ::Socket::TCP_NODELAY, flag ? 1 : 0)
      end

      # Return a raw Ruby I/O object
      #
      # @return [IO] Ruby I/O object
      def to_io
        ensure_state :connected
        ::IO.try_convert(@socket)
      end

      # Close the socket
      #
      # @return [true, false] true if the socket was open, false if closed
      def close
        return false if closed?

        begin
          @socket.close
        rescue Errno::EBADF
        end

        true
      ensure
        @socket = nil
        change_state :disconnected
      end

      # Is the socket connected?
      #
      # This method returns the local connection state. However, it's possible
      # the remote side has closed the connection, so it's not actually
      # possible to actually know if the socket is actually still open without
      # reading from or writing to it. It's sort of like the Heisenberg
      # uncertainty principle of sockets.
      #
      # @return [true, false] do we locally think the socket is connected?
      def connected?
        @state == :connected
      end

      # Is the socket closed?
      #
      # This method returns the local connection state. However, it's possible
      # the remote side has closed the connection, so it's not actually
      # possible to actually know if the socket is actually still open without
      # reading from or writing to it. It's sort of like the Heisenberg
      # uncertainty principle of sockets.
      #
      # @return [true, false] do we locally think the socket is closed?
      def closed?
        @state == :disconnected
      end

      private

      # Change the current state of the socket to a new state
      #
      # @param new_state [:connecting, :connected, :disconnected] new connection state
      #
      # @raise  [StateError] illegal state transition requested
      # @return [self]
      def change_state(new_state)
        case new_state
        when :connecting
          raise "@socket is unset in #{@state} state" unless @socket
          raise(StateError, "not in the disconnected state (actual: #{@state})") unless @state == :disconnected
          @state = :connecting
        when :connected
          raise "@socket is unset in #{@state} state" unless @socket
          raise(StateError, "not in the connecting state (actual: #{@state})") unless @state == :connecting
          @state = :connected
        when :disconnected
          raise "@socket is still set while disconnecting (in #{@state} state)" if @socket
          raise(StateError, "already in the disconnected state") if @state == :disconnected
          @state = :disconnected
        else raise ArgumentError, "bad state argument: #{state.inspect}"
        end
      end

      # Ensure the socket is in a particular state
      #
      # @param state [:connecting, :connected, :disconnected] state to assert we're in
      #
      # @raise  [StateError] in an unexpected state
      # @return [true] in expected state
      def ensure_state(state)
        return true if state == @state

        case state
        when :connecting   then raise StateError, "connection not in progress (#{@state})"
        when :connected    then raise StateError, "not connected"
        when :disconnected then raise StateError, "already connected"
        else raise ArgumentError, "bad state argument: #{state.inspect}"
        end
      end
    end
  end
end
