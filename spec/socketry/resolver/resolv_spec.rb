# frozen_string_literal: true

RSpec.describe Socketry::Resolver::Resolv, online: true do
  context "class methods" do
    it_behaves_like "Socketry DNS resolver"
  end

  context "instance methods" do
    subject(:resolver) { described_class.new }

    it "resolves DNS requests to Resolv addresses" do
      %w(localhost travis-ci.org).each do |hostname|
        result = resolver.resolve(hostname)
        expect([Resolv::IPv4, Resolv::IPv6]).to include(result.class)
      end
    end
  end
end
