# frozen_string_literal: true

module Socketry
  # Secure Sockets Layer (a.k.a. Transport Layer Security, or TLS)
  module SSL
    # SSL Server
    class Server < Socketry::TCP::Server
      # Create a new SSL server
      #
      # @return [Socketry::SSL::Server]
      def initialize(
        hostname_or_port,
        port = nil,
        ssl_socket_class: OpenSSL::SSL::SSLSocket,
        ssl_context: OpenSSL::SSL::SSLContext.new,
        ssl_params: nil,
        **args
      )
        raise TypeError, "invalid SSL context (#{ssl_context.class})" unless ssl_context.is_a?(OpenSSL::SSL::SSLContext)
        raise TypeError, "expected Hash, got #{ssl_params.class}" if ssl_params && !ssl_params.is_a?(Hash)

        @ssl_socket_class = ssl_socket_class
        @ssl_context = ssl_context
        @ssl_context.set_params(ssl_params) if ssl_params
        @ssl_context.freeze

        super(hostname_or_port, port, **args)
      end

      # Accept a connection to the server
      #
      # Note that this method also performs an SSL handshake and will therefore
      # block other sockets which are ready to be accepted.
      #
      # Multithreaded servers should invoke this method after spawning a thread
      # to ensure a slow/malicious connection can't cause a denial-of-service
      # attack against the server.
      #
      # @param timeout [Numeric, NilClass] seconds to wait before aborting the accept
      # @return [Socketry::SSL::Socket]
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
