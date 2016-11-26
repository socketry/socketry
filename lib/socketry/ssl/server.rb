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
        ssl_params: nil,
        **args
      )
        raise TypeError, "expected Hash, got #{ssl_params.class}" if ssl_params && !ssl_params.is_a?(Hash)

        @ssl_socket_class = ssl_socket_class
        @ssl_params = ssl_params

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
      # @param timeout [Numeric, NilClass] (default nil, unlimited) seconds to wait before aborting the accept
      #
      # @return [Socketry::SSL::Socket]
      def accept(timeout: nil, **args)
        tcp_socket = super(timeout: timeout, **args)

        ssl_socket = Socketry::SSL::Socket.new(
          read_timeout:     @read_timeout,
          write_timeout:    @write_timeout,
          resolver:         @resolver,
          ssl_socket_class: @ssl_socket_class,
          ssl_params:       @ssl_params
        )

        ssl_socket.accept(tcp_socket, timeout: timeout)
      end
    end
  end
end
