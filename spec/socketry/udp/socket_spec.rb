# frozen_string_literal: true

RSpec.describe Socketry::UDP::Socket do
  let(:bind_addr) { "localhost" }
  let(:bind_port) { 10_000 }

  describe "#initialize" do
    it "creates new sockets" do
      expect(described_class.new).to be_a described_class
    end

    it "needs way more tests than this!"
  end
end
