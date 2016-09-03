# frozen_string_literal: true

RSpec.describe Socketry::Resolver do
  let(:example_ipv4)    { "127.0.0.1" }
  let(:example_ipv6)    { "::1" }
  let(:example_invalid) { "0.2080381111" }

  describe ".addr" do
    it "parses IPv4 addresses" do
      expect(described_class.addr(example_ipv4)).to eq Resolv::IPv4.create(example_ipv4)
    end

    it "parses IPv6 addresses" do
      expect(described_class.addr(example_ipv6)).to eq Resolv::IPv6.create(example_ipv6)
    end

    it "raises Socketry::AddressError if given an invalid address" do
      expect { described_class.addr(example_invalid) }.to raise_error(Socketry::AddressError)
    end
  end

  describe ".resolve" do
    let(:example_resolver) { Socketry::Resolver::System }

    it "resolves IPv4 addresses to Resolv::IPv4" do
      expect(described_class.resolve(example_ipv4, example_resolver)).to eq Resolv::IPv4.create(example_ipv4)
    end

    it "resolves IPv6 addresses to Resolv::IPv6" do
      expect(described_class.resolve(example_ipv6, example_resolver)).to eq Resolv::IPv6.create(example_ipv6)
    end

    it "resolves DNS requests to Resolv addresses" do
      %w(localhost travis-ci.org).each do |hostname|
        result = described_class.resolve(hostname, example_resolver, timeout: 5)
        expect([Resolv::IPv4, Resolv::IPv6]).to include(result.class)
      end
    end

    it "raises Socketry::Resolver::Error if given an invalid address" do
      expect { described_class.resolve(example_invalid, example_resolver) }.to raise_error(Socketry::AddressError)
    end
  end
end
