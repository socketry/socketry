# frozen_string_literal: true

RSpec.describe Socketry::TCP::Socket do
  it_behaves_like "Socketry stream socket"

  let(:remote_host) { "localhost" }
  let(:remote_port) { unoccupied_port(addr: remote_host) }

  let(:mock_server) { ::TCPServer.new(remote_host, remote_port) }
  let(:peer_socket) { mock_server.accept }

  let(:example_data) { "Hello, peer!" }

  before do
    mock_server
    stream_socket.connect(remote_host, remote_port)
  end

  after do
    stream_socket.close
    mock_server.close
  end

  subject(:stream_socket) { described_class.new }

  describe "#connect" do
    it "connects to TCP servers" do
      expect(described_class.new.connect(remote_host, remote_port)).to be_a described_class
    end

    it "raises Socketry::ConnectionRefusedError if a connection was refused" do
      expect do
        described_class.new.connect(remote_host, unoccupied_port(addr: remote_host))
      end.to raise_error(Socketry::ConnectionRefusedError)
    end
  end

  describe "#reconnect" do
    it "reconnects after closing a connection" do
      stream_socket.close
      expect(stream_socket.reconnect).to be_a described_class
    end
  end

  describe "#from_socket" do
    it "creates from an existing Ruby TCPSocket" do
      socket = described_class.new(socket_class: TCPSocket)
      expect(socket.from_socket(TCPSocket.new(remote_host, remote_port))).to be_a described_class
    end
  end

  context "flags" do
    it "gets and sets the TCP_NODELAY flag (i.e. Nagle's algorithm)" do
      # Though the setter for nodelay works on JRuby, the getter does not
      skip if defined?(JRUBY_VERSION)

      expect(stream_socket.nodelay).to be_falsey

      stream_socket.nodelay = true
      expect(stream_socket.nodelay).to be_truthy

      stream_socket.nodelay = false
      expect(stream_socket.nodelay).to be_falsey
    end
  end
end
