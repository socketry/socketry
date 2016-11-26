# frozen_string_literal: true

module Socketry
  # User Datagram Protocol: "fire-and-forget" packet protocol
  module UDP
    # User Datagram Protocol sockets
    class Socket
      include Socketry::Timeout

      attr_reader :addr_family, :read_timeout, :write_timeout, :resolver, :socket_class

      # Create a UDP socket matching the given socket's address family
      #
      # @param remote_addr [String] Address to connect/bind to
      # @param resolver    [Object] Resolver object to use for resolving DNS names
      #
      # @return [Socketry::UDP::Socket]
      def self.from_addr(remote_addr, resolver: Socketry::Resolver::DEFAULT_RESOLVER)
        addr = resolver.resolve(remote_addr)
        if addr.ipv4?    then new(addr_family: :ipv4)
        elsif addr.ipv6? then new(addr_family: :ipv6)
        else raise Socketry::AddressError, "unsupported IP address family: #{addr}"
        end
      end

      # Create a UDP server bound to the given address and port
      #
      # @param local_addr [String] Local DNS name or IP address to listen on
      # @param local_port [Fixnum] Local UDP port to listen on
      # @param resolver   [Object] Resolver object to use for resolving DNS names
      #
      # @return [Socketry::UDP::Socket]
      def self.bind(local_addr, local_port, resolver: Socketry::Resolver::DEFAULT_RESOLVER)
        from_addr(local_addr, resolver: resolver).bind(local_addr, local_port)
      end

      # Connect to the given address and port
      #
      # @param remote_addr [String] DNS name or IP address of the host to connect to
      # @param remote_port [Fixnum] UDP port to connect to
      # @param resolver    [Object] Resolver object to use for resolving DNS names
      #
      # @return [Socketry::UDP::Socket]
      def self.connect(remote_addr, remote_port, resolver: Socketry::Resolver::DEFAULT_RESOLVER)
        from_addr(remote_addr, resolver: resolver).connect(remote_addr, remote_port)
      end

      # Create a new UDP socket
      #
      # @param addr_family   [:ipv4, :ipv6] (default :ipv4) address family for this socket
      # @param read_timeout  [Numeric] Seconds to wait before an uncompleted read errors
      # @param write_timeout [Numeric] Seconds to wait before an uncompleted write errors
      # @param timer         [Object]  Time interval object to use for measuring timeouts
      # @param resolver      [Object]  Resolver object to use for resolving DNS names
      # @param socket_class  [Object]  Underlying socket class which implements I/O ops
      #
      # @raise [ArgumentError] an invalid argument was given
      #
      # @return [Socketry::UDP::Socket]
      def initialize(
        addr_family: :ipv4,
        read_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:read],
        write_timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:write],
        timer: Socketry::Timeout::DEFAULT_TIMER.new,
        resolver: Socketry::Resolver::DEFAULT_RESOLVER,
        socket_class: ::UDPSocket
      )
        @addr_family = case addr_family
                       when :ipv4 then ::Socket::AF_INET
                       when :ipv6 then ::Socket::AF_INET6
                       when ::Socket::AF_INET, ::Socket::AF_INET6 then addr_family
                       else raise ArgumentError, "invalid address family: #{addr_family.inspect}"
                       end

        @socket        = socket_class.new(@addr_family)
        @read_timeout  = read_timeout
        @write_timeout = write_timeout
        @resolver      = resolver

        start_timer(timer)
      end

      # Start a UDP server bound to a particular address and port
      #
      # @param local_addr [String] Local DNS name or IP address to listen on
      # @param local_port [Fixnum] Local UDP port to listen on
      #
      # @return [self]
      def bind(local_addr, local_port)
        @socket.bind(@resolver.resolve(local_addr).to_s, local_port)
        self
      rescue Errno::EADDRINUSE => ex
        raise AddressInUseError, ex.message, ex.backtrace
      rescue => ex
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Make a UDP client connection to the given address and port
      #
      # @param remote_addr [String] DNS name or IP address of the host to connect to
      # @param remote_port [Fixnum] UDP port to connect to
      #
      # @return [self]
      def connect(remote_addr, remote_port)
        @socket.connect(@resolver.resolve(remote_addr).to_s, remote_port)
        self
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Perform a non-blocking receive
      #
      # @param maxlen [Fixnum] Maximum packet length to receive
      #
      # @return [Socketry::UDP::Datagram, :wait_readable] Received datagram or indication to wait
      def recvfrom_nonblock(maxlen)
        Socketry::UDP::Datagram.new(*@socket.recvfrom_nonblock(maxlen))
      rescue ::IO::WaitReadable
        :wait_readable
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Perform a blocking receive
      #
      # @param maxlen  [Fixnum] Maximum packet length to receive
      # @param timeout [Numeric] Number of seconds to wait for recvfrom operation to complete
      #
      # @return [String] Received data
      def recvfrom(maxlen, timeout: @read_timeout)
        set_timeout(timeout)

        begin
          while (result = recvfrom_nonblock(maxlen)) == :wait_readable
            next if @socket.wait_readable(time_remaining(timeout))
            raise Socketry::TimeoutError, "recvfrom timed out after #{timeout} seconds"
          end
        ensure
          clear_timeout(timeout)
        end

        result
      end

      # Send a UDP packet to a remote host
      #
      # @param msg  [String] Data to write to the remote host/port
      # @param host [String] Remote host to send data to. May be omitted if `connect` was called previously
      # @param port [Fixnum] UDP port to send data to. May be omitted if `connect` was called previously
      #
      # @return [Fixum] Number of bytes sent
      def send(msg, host: nil, port: nil)
        host = @resolver.resolve(host).to_s if host
        if host || port
          @socket.send(msg, 0, host, port)
        else
          @socket.send(msg, 0)
        end
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end

      # Close the socket
      #
      # @return [true, false] true if the socket was open, false if closed
      def close
        return false if closed?
        @socket.close
        true
      ensure
        @socket = nil
      end

      # Is the socket closed?
      #
      # @return [true, false] do we locally think the socket is closed?
      def closed?
        @socket.nil?
      end
    end
  end
end
