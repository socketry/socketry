# frozen_string_literal: true

RSpec.describe Socketry::SSL::Socket do
  let(:remote_host) { "localhost" }
  let(:remote_port) { unoccupied_port(addr: remote_host) }

  let(:ssl_server) do
    tcp_server = ::TCPServer.new(remote_host, remote_port)
    ssl_context = OpenSSL::SSL::SSLContext.new

    ssl_context.cert = OpenSSL::X509::Certificate.new(server_cert_file.read)
    ssl_context.key  = OpenSSL::PKey::RSA.new(server_key_file.read)

    OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)
  end

  let(:ssl_client_params) do
    { ca_file: ssl_cert_path("trusted-ca").to_s }
  end

  let(:ssl_server_thread) do
    # Create the ssl_server
    ssl_server

    thread = Thread.new { ssl_server.accept rescue nil }
    Thread.pass while thread.status && thread.status != "sleep"

    thread
  end

  let(:ssl_peer_socket) { ssl_server_thread.value }

  describe ".initialize" do
    it "raises if given bogus :ssl_params" do
      expect { described_class.new(ssl_params: "polly shouldn't be!") }.to raise_error(TypeError)
    end
  end

  describe "#connect" do
    subject(:ssl_socket) { described_class.new(ssl_params: ssl_client_params) }

    before { ssl_server_thread }

    after do
      ssl_server_thread.kill if ssl_server_thread.alive?

      ssl_socket.close rescue nil
      ssl_server.close rescue nil
      ssl_peer_socket.close rescue nil
    end

    context "with a valid CA" do
      let(:server_cert_file) { ssl_cert_path("trusted-cert") }
      let(:server_key_file)  { ssl_key_path("trusted-cert") }

      it "connects to SSL servers" do
        expect(ssl_socket.connect(remote_host, remote_port)).to be_a described_class
        expect(ssl_peer_socket).to be_a OpenSSL::SSL::SSLSocket
      end
    end

    context "with an invalid CA" do
      let(:server_cert_file) { ssl_cert_path("untrusted-cert") }
      let(:server_key_file)  { ssl_key_path("untrusted-cert") }

      it "raises an exception" do
        expect do
          ssl_socket.connect(remote_host, remote_port)
        end.to raise_error(Socketry::SSL::Error)
      end
    end

    pending "raises Socketry::ConnectionRefusedError if a connection was refused"
  end

  describe "#reconnect" do
    it "needs tests!"
  end

  describe "#from_socket" do
    let(:server_cert_file) { ssl_cert_path("trusted-cert") }
    let(:server_key_file)  { ssl_key_path("trusted-cert") }

    before { ssl_server_thread }

    after do
      ssl_server_thread.kill if ssl_server_thread.alive?
      ssl_server.close rescue nil
    end

    it "creates SSL sockets from TCP sockets" do
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.set_params(ssl_client_params)
      tcp_socket = ::TCPSocket.new(remote_host, remote_port)
      ssl_socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
      ssl_socket.connect

      expect(described_class.new.from_socket(ssl_socket)).to be_a described_class
      ssl_socket.close
    end
  end

  context "stream socket specs" do
    let(:server_cert_file) { ssl_cert_path("trusted-cert") }
    let(:server_key_file)  { ssl_key_path("trusted-cert") }

    subject(:stream_socket) { described_class.new(ssl_params: ssl_client_params) }
    subject(:peer_socket) { ssl_peer_socket }

    before do
      ssl_server_thread
      stream_socket.connect(remote_host, remote_port)
    end

    after do
      ssl_server_thread.kill if ssl_server_thread.alive?

      peer_socket.close rescue nil
      ssl_server.close rescue nil
    end

    it_behaves_like "Socketry stream socket"
  end
end
