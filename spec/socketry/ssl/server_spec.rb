# frozen_string_literal: true

RSpec.describe Socketry::SSL::Server do
  let(:bind_addr) { "localhost" }
  let(:bind_port) { unoccupied_port(addr: bind_addr) }

  let(:server_cert_file) { ssl_cert_path("trusted-cert") }
  let(:server_key_file)  { ssl_key_path("trusted-cert") }

  let(:ssl_client_params) do
    { ca_file: ssl_cert_path("trusted-ca").to_s }
  end

  let(:ssl_server_params) do
    {
      cert: OpenSSL::X509::Certificate.new(server_cert_file.read),
      key: OpenSSL::PKey::RSA.new(server_key_file.read)
    }
  end

  subject(:ssl_server) { described_class.new(bind_addr, bind_port, ssl_params: ssl_server_params) }

  before { ssl_server }
  after  { ssl_server.close rescue nil }

  describe "#accept" do
    let(:timeout) { 1 }

    it "accepts connections" do
      begin
        server_thread = Thread.new { ssl_server.accept }
        ssl_client = Socketry::SSL::Socket.new(ssl_params: ssl_client_params)
        ssl_client.connect(bind_addr, bind_port)
        peer_socket = server_thread.join(timeout).value
        expect(peer_socket).to be_a Socketry::SSL::Socket
      ensure
        client.close rescue nil
        peer.close rescue nil
      end
    end
  end
end
