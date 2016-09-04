# frozen_string_literal: true

module Socketry
  # Secure Sockets Layer (a.k.a. Transport Layer Security, or TLS)
  module SSL
    # SSL Sockets
    class Socket < Socketry::TCP::Socket
      def initialize(ssl_socket_class: OpenSSL::SSL::SSLSocket, ssl_params: nil, **args)
        super(**args)
        raise TypeError, "expected Hash, got #{ssl_params.class}" if ssl_params && !ssl_params.is_a?(Hash)

        @ssl_socket_class = ssl_socket_class
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @ssl_context.set_params(ssl_params) if ssl_params
        @ssl_socket = nil
      end

      def connect(
        remote_addr,
        remote_port,
        local_addr: nil,
        local_port: nil,
        timeout: Socketry::Timeout::DEFAULTS[:connect],
        verify_hostname: true
      )
        super(remote_addr, remote_port, local_addr: local_addr, local_port: local_port, timeout: timeout)
        from_socket(@socket, hostname: remote_addr, verify_hostname: verify_hostname)
        true
      rescue => ex
        @socket.close rescue nil
        @socket = nil
        @ssl_socket.close rescue nil
        @ssl_socket = nil
        raise ex
      end

      def from_socket(
        socket,
        hostname:,
        timeout: Socketry::Timeout::DEFAULTS[:connect],
        verify_hostname: true
      )
        raise TypeError, "expected #{@socket_class}, got #{socket.class}" unless socket.is_a?(@socket_class)
        raise StateError, "already connected" if @socket && @socket != socket

        @socket = socket
        @ssl_socket = OpenSSL::SSL::SSLSocket.new(@socket, @ssl_context)
        @ssl_socket.sync_close = true
        @ssl_socket.hostname = hostname if hostname

        begin
          @ssl_socket.connect_nonblock
        rescue IO::WaitReadable
          retry if @socket.wait_readable(timeout)
          raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
        rescue IO::WaitWritable
          retry if @socket.wait_writable(timeout)
          raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
        end

        if verify_hostname
          raise ArgumentError, "verify_hostname is true but no hostname given" unless hostname
          @ssl_socket.post_connection_check(hostname)
        end

        true
      end

      def read_nonblock(size)
        ensure_connected
        @ssl_socket.read_nonblock(size, exception: false)
      # Some buggy Rubies continue to raise exceptions in these cases
      rescue IO::WaitReadable
        :wait_readable
      # Due to SSL, we may need to write to complete a read (e.g. renegotiation)
      rescue IO::WaitWritable
        :wait_writable
      end

      def write_nonblock(data)
        ensure_connected
        @ssl_socket.write_nonblock(data, exception: false)
      # Some buggy Rubies continue to raise this exception
      rescue IO::WaitWriteable
        :wait_writable
      # Due to SSL, we may need to write to complete a read (e.g. renegotiation)
      rescue IO::WaitReadable
        :wait_readable
      end

      def close
        @ssl_socket.close
        super
      end
    end
  end
end
