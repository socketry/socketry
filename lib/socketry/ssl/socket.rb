# frozen_string_literal: true

module Socketry
  # Secure Sockets Layer (a.k.a. Transport Layer Security, or TLS)
  module SSL
    # SSL Sockets
    class Socket < Socketry::TCP::Socket
      # Create an unconnected Socketry::SSL::Socket
      #
      # @param read_timeout [Numeric] Seconds to wait before an uncompleted read errors
      # @param write_timeout [Numeric] Seconds to wait before an uncompleted write errors
      # @param timer [Object] A timekeeping object to use for measuring timeouts
      # @param resolver [Object] A resolver object to use for resolving DNS names
      # @param socket_class [Object] Underlying socket class which implements I/O ops
      # @param ssl_socket_class [Object] Class which provides the underlying SSL implementation
      # @param ssl_context [OpenSSL::SSL::SSLContext] SSL configuration object
      # @param ssL_params [Hash] Parameter hash to set on the given SSL context
      #
      # @return [Socketry::SSL::Socket]
      def initialize(
        ssl_socket_class: OpenSSL::SSL::SSLSocket,
        ssl_context: OpenSSL::SSL::SSLContext.new,
        ssl_params: nil,
        **args
      )
        raise TypeError, "invalid SSL context (#{ssl_context.class})" unless ssl_context.is_a?(OpenSSL::SSL::SSLContext)
        raise TypeError, "expected Hash, got #{ssl_params.class}" if ssl_params && !ssl_params.is_a?(Hash)

        @ssl_socket_class = ssl_socket_class

        @ssl_context = ssl_context
        @ssl_context.set_params(ssl_params) if ssl_params && !ssl_params.empty?

        @ssl_socket = nil

        super(**args)
      end

      # Make an SSL connection to a remote host
      #
      # @param remote_addr [String] DNS name or IP address of the host to connect to
      # @param remote_port [Fixnum] TCP port to connect to
      # @param local_addr [String] DNS name or IP address to bind to locally
      # @param local_port [Fixnum] Local TCP port to bind to
      # @param timeout [Numeric] Number of seconds to wait before aborting connect
      # @param enable_sni [true, false] (default: true) Enables Server Name Indication (SNI)
      # @param verify_hostname [true, false] (default: true) Ensure server's hostname matches cert
      #
      # @raise [Socketry::AddressError] an invalid address was given
      # @raise [Socketry::TimeoutError] connect operation timed out
      # @raise [Socketry::SSL::Error] an error occurred negotiating an SSL connection
      # @return [self]
      def connect(
        remote_addr,
        remote_port,
        local_addr: nil,
        local_port: nil,
        timeout: Socketry::Timeout::DEFAULT_TIMEOUTS[:connect],
        enable_sni: true,
        verify_hostname: true
      )
        super(remote_addr, remote_port, local_addr: local_addr, local_port: local_port, timeout: timeout)

        @ssl_socket = @ssl_socket_class.new(@socket, @ssl_context)
        @ssl_socket.hostname = remote_addr if enable_sni
        @ssl_socket.sync_close = true

        begin
          @ssl_socket.connect_nonblock
        rescue IO::WaitReadable
          retry if @socket.wait_readable(timeout)
          raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
        rescue IO::WaitWritable
          retry if @socket.wait_writable(timeout)
          raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
        rescue OpenSSL::SSL::SSLError => ex
          raise Socketry::SSL::CertificateVerifyError, ex.message if ex.message.include?("certificate verify failed")
          raise Socketry::SSL::Error, ex.message, ex.backtrace
        end

        begin
          @ssl_socket.post_connection_check(remote_addr) if verify_hostname
        rescue OpenSSL::SSL::SSLError => ex
          raise Socketry::SSL::HostnameError, ex.message, ex.backtrace
        end

        self
      rescue => ex
        @socket.close rescue nil
        @socket = nil
        @ssl_socket.close rescue nil
        @ssl_socket = nil
        raise ex
      end

      # Accept an SSL connection from a Socketry or Ruby socket
      #
      # @param tcp_socket [TCPSocket, Socketry::TCP::Socket] raw TCP socket to begin SSL handshake with
      # @param timeout [Numeric, NilClass] (default nil, unlimited) seconds to wait before aborting the accept
      #
      # @return [self]
      def accept(tcp_socket, timeout: nil)
        tcp_socket = IO.try_convert(tcp_socket) || raise(TypeError, "couldn't convert #{tcp_socket.class} to IO")
        ssl_socket = @ssl_socket_class.new(tcp_socket, @ssl_context)

        begin
          ssl_socket.accept_nonblock
        rescue IO::WaitReadable
          retry if IO.select([tcp_socket], nil, nil, timeout)
          raise Socketry::TimeoutError, "failed to complete handshake after #{timeout} seconds"
        rescue IO::WaitWritable
          retry if IO.select(nil, [tcp_socket], nil, timeout)
          raise Socketry::TimeoutError, "failed to complete handshake after #{timeout} seconds"
        end

        from_socket(ssl_socket)
      end

      # Wrap a Ruby OpenSSL::SSL::SSLSocket (or other low-level SSL socket)
      #
      # @param ssl_socket [OpenSSL::SSL::SSLSocket] SSL socket class associated with this socket
      #
      # @return [self]
      def from_socket(ssl_socket)
        raise TypeError, "expected #{@ssl_socket_class}, got #{ssl_socket.class}" unless ssl_socket.is_a?(@ssl_socket_class)
        raise StateError, "already connected" if @socket

        @socket = ssl_socket.to_io
        @ssl_socket = ssl_socket
        @ssl_socket.sync_close = true

        self
      end

      # Perform a non-blocking read operation
      #
      # @param size [Fixnum] number of bytes to attempt to read
      # @param outbuf [String, NilClass] an optional buffer into which data should be read
      #
      # @raise [Socketry::Error] an I/O operation failed
      # @return [String, :wait_readable] data read, or :wait_readable if operation would block
      def read_nonblock(size, outbuf: nil)
        case outbuf
        when String
          perform { @ssl_socket.read_nonblock(size, outbuf, exception: false) }
        when NilClass
          perform { @ssl_socket.read_nonblock(size, exception: false) }
        else raise TypeError, "unexpected outbuf class: #{outbuf.class}"
        end
      end

      # Perform a non-blocking write operation
      #
      # @param data [String] number of bytes to attempt to read
      #
      # @raise [Socketry::Error] an I/O operation failed
      # @return [Fixnum, :wait_writable] number of bytes written, or :wait_writable if op would block
      def write_nonblock(data)
        perform { @ssl_socket.write_nonblock(data, exception: false) }
      end

      # Close the socket
      #
      # @return [true, false] true if the socket was open, false if closed
      def close
        return false unless super
        @ssl_socket.close
        @ssl_socket = nil
        true
      end

      private

      # Perform a non-blocking I/O operation
      def perform
        ensure_connected
        yield
      # Some buggy Rubies continue to raise this exception
      rescue IO::WaitWritable
        :wait_writable
      # Due to SSL, we may need to write to complete a read (e.g. handshaking, renegotiation)
      rescue IO::WaitReadable
        :wait_readable
      rescue => ex
        # TODO: more specific exceptions
        raise Socketry::Error, ex.message, ex.backtrace
      end
    end
  end
end
