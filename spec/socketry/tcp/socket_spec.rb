# frozen_string_literal: true

RSpec.describe Socketry::TCP::Socket do
  let(:remote_host) { "localhost" }
  let(:remote_port) { unoccupied_port(addr: remote_host) }

  let(:mock_server) { ::TCPServer.new(remote_host, remote_port) }
  let(:peer_socket) { mock_server.accept }

  let(:example_data) { "Hello, peer!" }

  before do
    mock_server
    tcp_socket.connect(remote_host, remote_port)
  end

  after do
    tcp_socket.close
    mock_server.close
  end

  subject(:tcp_socket) { described_class.new }

  describe "#connect" do
    it "connects to TCP servers" do
      expect(described_class.new.connect(remote_host, remote_port)).to be_a described_class
    end
  end

  describe "#reconnect" do
    it "reconnects after closing a connection" do
      tcp_socket.close
      expect(tcp_socket.reconnect).to be_a described_class
    end
  end

  describe "#from_socket" do
    it "creates from an existing Ruby TCPSocket" do
      socket = described_class.new(socket_class: TCPSocket)
      expect(socket.from_socket(TCPSocket.new(remote_host, remote_port))).to be_a described_class
    end
  end

  context "non-blocking I/O" do
    describe "#read_nonblock" do
      it "reads data if available" do
        peer_socket.write(example_data)
        peer_socket.close
        sleep 0.001 # :( sleeps like this are bad, but writing reliable I/O tests is hard

        expect(tcp_socket.read_nonblock(example_data.size)).to eq example_data
      end

      it "returns :wait_readable if we aren't ready to read" do
        expect(tcp_socket.read_nonblock(1)).to eq :wait_readable
      end
    end

    describe "#write_nonblock" do
      it "returns the number of bytes written on success" do
        expect(tcp_socket.write_nonblock(example_data)).to eq example_data.size
      end

      pending "returns :wait_writable if we aren't ready to write"
    end
  end

  describe "#readpartial" do
    it "reads partial data" do
      peer_socket.write(example_data)
      peer_socket.close

      expect(tcp_socket.readpartial(example_data.size)).to eq example_data
    end
  end

  describe "#writepartial" do
    pending "writes partial data"
  end

  describe "#to_io" do
    it "converts to a Ruby IO object" do
      expect(tcp_socket.to_io).to be_a(::IO)
    end
  end

  context "flags" do
    it "gets and sets the TCP_NODELAY flag (i.e. Nagle's algorithm)" do
      # Though the setter for nodelay works on JRuby, the getter does not
      skip if defined?(JRUBY_VERSION)

      expect(tcp_socket.nodelay).to be_falsey

      tcp_socket.nodelay = true
      expect(tcp_socket.nodelay).to be_truthy

      tcp_socket.nodelay = false
      expect(tcp_socket.nodelay).to be_falsey
    end
  end
end
