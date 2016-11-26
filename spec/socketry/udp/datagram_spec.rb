# frozen_string_literal: true

RSpec.describe Socketry::UDP::Datagram do
  let(:example_port)     { 54_321 }
  let(:example_message)  { "Hello, peer!" }
  let(:example_addrinfo) { ["AF_INET6", example_port, "::1", "::1"] }

  subject(:datagram) { described_class.new(example_message, example_addrinfo) }

  describe "#addrinfo" do
    it "makes an Addrinfo object" do
      addrinfo = datagram.addrinfo

      expect(addrinfo).to be_a ::Addrinfo
      expect(addrinfo.afamily).to eq ::Socket::AF_INET6
      expect(addrinfo.socktype).to eq ::Socket::SOCK_DGRAM
      expect(addrinfo.ip_port).to eq example_port
    end
  end
end
