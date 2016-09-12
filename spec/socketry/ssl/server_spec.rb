# frozen_string_literal: true

RSpec.describe Socketry::SSL::Server do
  let(:bind_addr) { "localhost" }
  let(:bind_port) { unoccupied_port(addr: bind_addr) }

  subject(:server) { described_class.new(bind_addr, bind_port) }

  before { server }
  after  { server.close rescue nil }

  describe "#accept" do
    it "accepts connections" do
      pending "certificate config"

      begin
        peer = Thread.new { server.accept }
        client = Socketry::SSL::Socket.new.connect(bind_addr, bind_port)
        expect(peer.join(5)).to be_a Socketry::SSL::Socket
      ensure
        client.close rescue nil
        peer.close rescue nil
      end
    end
  end
end
