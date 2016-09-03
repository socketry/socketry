# frozen_string_literal: true

require "forwardable"
require "io/wait"

module Socketry
  module Timeout
    # Timeout-free operation
    class Null
      extend Forwardable

      def_delegators :@socket, :close, :closed?

      # Connects to a socket
      def connect(socket_class, host, port, nodelay = false)
        @socket = socket_class.open(host, port)
        @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if nodelay
      end

      # Read from the socket
      def readpartial(size)
        @socket.readpartial(size)
      rescue EOFError
        :eof
      end

      # Write to the socket
      def write(data)
        @socket.write(data)
      end
      alias << write
    end
  end
end
