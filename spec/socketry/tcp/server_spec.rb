# frozen_string_literal: true

RSpec.describe Socketry::TCP::Server do
  let(:bind_addr) { "localhost" }
  let(:bind_port) { 23_456 }

  subject(:server) { described_class.new(bind_addr, bind_port) }

  before { server }
  after  { server.close rescue nil }

  describe "#accept" do
    it "accepts connections" do
      begin
        client = TCPSocket.new(bind_addr, bind_port)
        peer = server.accept
        expect(peer).to be_a Socketry::TCP::Socket
      ensure
        client.close rescue nil
        peer.close rescue nil
      end
    end

    it "times out" do
      expect { server.accept(timeout: 0.00001) }.to raise_error Socketry::TimeoutError
    end
  end
end
