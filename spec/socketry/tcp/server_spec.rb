# frozen_string_literal: true

RSpec.describe Socketry::TCP::Server do
  let(:bind_addr) { "localhost" }
  let(:bind_port) { unoccupied_port }

  subject(:tcp_server) { described_class.new(bind_addr, bind_port) }

  before { tcp_server }
  after  { tcp_server.close rescue nil }

  describe ".new" do
    it "raises Socketry::AddressInUseError if an address is in use" do
      # Attempt to bind to the same host/port again
      expect { described_class.new(bind_addr, bind_port) }.to raise_error(Socketry::AddressInUseError)
    end
  end

  describe "#accept" do
    it "accepts connections" do
      begin
        client = TCPSocket.new(bind_addr, bind_port)
        peer = tcp_server.accept
        expect(peer).to be_a Socketry::TCP::Socket
      ensure
        client.close rescue nil
        peer.close rescue nil
      end
    end

    it "times out" do
      expect { tcp_server.accept(timeout: 0.00001) }.to raise_error Socketry::TimeoutError
    end
  end
end
