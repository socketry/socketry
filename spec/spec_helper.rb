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
  let(:invalid_timeout)    { "I'm not really a timeout" }

  it "resolves DNS requests to Resolv addresses" do
    [hosts_file_example, valid_dns_example].each do |hostname|
      expect(described_class.resolve(hostname, timeout: 5)).to be_a IPAddr
    end
  end

  it "raises Socketry::Resolver::Error if given an invalid address" do
    expect { described_class.resolve(invalid_example) }.to raise_error(Socketry::Resolver::Error)
  end

  it "raises TypeError if given a bogus timeout object" do
    expect { described_class.resolve(valid_dns_example, timeout: invalid_timeout) }.to raise_error(TypeError)
  end
end

def unoccupied_port(addr: "localhost", port: 10_000, max_port: 15_000)
  loop do
    begin
      socket = TCPSocket.new(addr, port)
    rescue Errno::ECONNREFUSED
      return port
    ensure
      socket.close rescue nil
    end

    port += 1
    raise "exhausted too many ports" if port > max_port
  end
end
