# frozen_string_literal: true

RSpec.describe Socketry::SSL::Socket do
  describe ".initialize" do
    it "raises if given bogus :ssl_params" do
      expect { described_class.new(ssl_params: "polly shouldn't be!") }.to raise_error(TypeError)
    end
  end

  it "needs way more tests!"
end
