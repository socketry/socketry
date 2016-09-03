# frozen_string_literal: true

require "coveralls"
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "socketry"

RSpec.configure(&:disable_monkey_patching!)

RSpec.shared_examples "Socketry DNS resolver" do
  let(:hosts_file_example) { "localhost" }
  let(:valid_dns_example)  { "travis-ci.org" }
  let(:invalid_example)    { "this is clearly not a valid DNS address, right?" }

  it "resolves DNS requests to Resolv addresses" do
    [hosts_file_example, valid_dns_example].each do |hostname|
      result = described_class.resolve(hostname, timeout: 5)
      expect([Resolv::IPv4, Resolv::IPv6]).to include(result.class)
    end
  end

  it "raises Socketry::Resolver::Error if given an invalid address" do
    expect { described_class.resolve(invalid_example) }.to raise_error(Socketry::Resolver::Error)
  end
end
