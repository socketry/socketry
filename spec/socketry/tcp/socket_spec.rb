# frozen_string_literal: true

RSpec.describe Socketry::TCP::Socket do
  let(:remote_host) { "localhost" }
  let(:remote_port) { 12_345 }

  let(:mock_server) { ::TCPServer.new(remote_host, remote_port) }
  let(:peer_socket) { mock_server.accept }

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
      expect(described_class.new.connect(remote_host, remote_port)).to eq true
    end
  end

  describe "#reconnect" do
    it "reconnects after closing a connection" do
      tcp_socket.close
      expect(tcp_socket.reconnect).to eq true
    end
  end

  describe "#from_socket" do
    it "creates from an existing Ruby TCPSocket" do
      socket = described_class.new(socket_class: TCPSocket)
      expect(socket.from_socket(TCPSocket.new(remote_host, remote_port))).to eq true
    end
  end

  context "non-blocking I/O" do
    let(:example_data) { "Hello, peer!" }

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

      it "returns :wait_writable if we aren't ready to write"
    end
  end

  describe "#to_io" do
    it "converts to a Ruby IO object" do
      expect(tcp_socket.to_io).to be_a(::IO)
    end
  end

  context "flags" do
    it "gets and sets the TCP_NODELAY flag (i.e. Nagle's algorithm)" do
      expect(tcp_socket.nodelay).to eq false

      tcp_socket.nodelay = true
      expect(tcp_socket.nodelay).to eq true

      tcp_socket.nodelay = false
      expect(tcp_socket.nodelay).to eq false
    end
  end
end
