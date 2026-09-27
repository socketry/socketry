# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "socketry"

describe Socketry do
	it "has a version number" do
		expect(Socketry::VERSION).to be =~ /\A\d+\.\d+\.\d+\z/
	end
end
