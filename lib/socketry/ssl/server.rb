# frozen_string_literal: true

module Socketry
  # Secure Sockets Layer (a.k.a. Transport Layer Security, or TLS)
  module SSL
    # SSL Server
    class Server < Socketry::TCP::Server
      def initialize(
        hostname_or_port,
        port = nil,
        ssl_socket_class: OpenSSL::SSL::SSLSocket,
        ssl_params: nil,
        **args
      )
        raise TypeError, "expected Hash, got #{ssl_params.class}" if ssl_params && !ssl_params.is_a?(Hash)

        @ssl_socket_class = ssl_socket_class
        @ssl_context = OpenSSL::SSL::SSLContext.new
        @ssl_context.set_params(ssl_params) if ssl_params
        @ssl_context.freeze

        super(hostname_or_port, port, **args)
      end

      def accept(timeout: nil, **args)
        ruby_socket = super(timeout: timeout, **args).to_io
        ssl_socket  = @ssl_socket_class.new(ruby_socket, @ssl_context)

        begin
          ssl_socket.accept_nonblock
        rescue IO::WaitReadable
          retry if IO.select([ruby_socket], nil, nil, timeout)
          raise Socketry::TimeoutError, "failed to complete handshake after #{timeout} seconds"
        rescue IO::WaitWritable
          retry if IO.select(nil, [ruby_socket], nil, timeout)
          raise Socketry::TimeoutError, "failed to complete handshake after #{timeout} seconds"
        end

        Socketry::SSL::Socket.new(
          read_timeout:  @read_timeout,
          write_timeout: @write_timeout,
          resolver:      @resolver,
          socket_class:  @socket_class
        ).from_socket(ruby_socket)
      end
    end
  end
end
