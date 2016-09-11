# frozen_string_literal: true

RSpec.describe Socketry::Resolver::System, online: true do
  include_examples "Socketry DNS resolver"

  let(:invalid_ip_address) { "I am not a valid IP address" }

  # Unfortunately Resolv::DNS doesn't seem to raise Resolv::TimeoutError
  # reliably, so we can't yet include this in our shared examples.
  it "raises Socketry::TimeoutError if a request times out" do
    expect { described_class.resolve(valid_dns_example, timeout: 0.000001) }.to raise_error(Socketry::TimeoutError)
  end

  it "raises Socketry::AddressError if DNS resolves to an address we don't understand" do
    allow(IPSocket).to receive(:getaddress).and_return(invalid_ip_address)
    expect { described_class.resolve(valid_dns_example) }.to raise_error(Socketry::AddressError)
  end
end
