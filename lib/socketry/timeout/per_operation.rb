require "timeout"

require "socketry/timeout/null"

module Socketry
  module Timeout
    # Timeouts that apply to individual I/O operations
    class PerOperation < Null
      READ_TIMEOUT = 0.25
      WRITE_TIMEOUT = 0.25
      CONNECT_TIMEOUT = 0.25

      def initialize(read_timeout: READ_TIMEOUT, write_timeout: WRITE_TIMEOUT, connect_timeout: CONNECT_TIMEOUT)
        @read_timeout = read_timeout
        @write_timeout = write_timeout
        @connect_timeout = connect_timeout
      end

      def connect(socket_class, host, port, nodelay = false)
        ::Timeout.timeout(connect_timeout, TimeoutError) do
          @socket = socket_class.open(host, port)
          @socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1) if nodelay
        end
      end

      # Read data from the socket
      def readpartial(size)
        loop do
          result = @socket.read_nonblock(size, exception: false)

          return :eof   if result.nil?
          return result if result != :wait_readable

          unless IO.select([@socket], nil, nil, read_timeout)
            raise TimeoutError, "Read timed out after #{read_timeout} seconds"
          end
        end
      end

      # Write data to the socket
      def write(data)
        loop do
          result = @socket.write_nonblock(data, exception: false)
          return result unless result == :wait_writable

          unless IO.select(nil, [@socket], nil, write_timeout)
            raise TimeoutError, "Write timed out after #{write_timeout} seconds"
          end
        end
      end
    end
  end
end
