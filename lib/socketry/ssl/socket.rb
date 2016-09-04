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

      def connect(remote_addr, remote_port, local_addr: nil, local_port: nil, verify_hostname: true)
        super(remote_addr, remote_port, local_addr: local_addr, local_port: local_port)
        from_socket(@socket, remote_addr)
        @ssl_socket.post_connection_check(remote_addr) if verify_hostname
        true
      rescue => ex
        @socket.close rescue nil
        @socket = nil
        @ssl_socket = nil
        raise ex
      end

      def from_socket(socket, hostname = nil)
        raise TypeError, "expected #{@socket_class}, got #{socket.class}" unless socket.is_a?(@socket_class)
        raise StateError, "already connected" if @socket && @socket != socket

        @socket = socket
        @ssl_socket = OpenSSL::SSL::SSLSocket.new(@socket, @ssl_context)
        @ssl_socket.sync_close = true
        @ssl_socket.hostname = hostname if hostname

        begin
          @ssl_socket.connect_nonblock
        rescue IO::WaitReadable
          retry if @socket.wait_readable(connect_timeout)
          raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
        rescue IO::WaitWritable
          retry if @socket.wait_writable(connect_timeout)
          raise Socketry::TimeoutError, "connection to #{remote_addr}:#{remote_port} timed out"
        end

        true
      end

      def read_nonblock(size)
        ensure_connected
        @ssl_socket.read_nonblock(size, exception: false)
      rescue IO::WaitReadable
        # Some buggy Rubies continue to raise this exception
        :wait_readable
      end

      def write_nonblock(data)
        ensure_connected
        @ssl_socket.write_nonblock(data, exception: false)
      rescue IO::WaitWriteable
        # Some buggy Rubies continue to raise this exception
        :wait_writable
      end

      def close
        @ssl_socket.close
        super
      end
    end
  end
end
