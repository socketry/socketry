# frozen_string_literal: true

RSpec.describe Socketry::Timeout do
  let(:mock_timer) { double("mock timer") }

  let(:example_class) do
    Class.new do
      include Socketry::Timeout
      attr_reader :timer, :deadline
    end
  end

  let(:example_lifetime) { 42.0 }
  let(:example_timeout)  { 5 }
  let(:example_deadline) { example_lifetime + example_timeout }

  subject(:example_object) { example_class.new }

  before do
    expect(mock_timer).to receive(:start)
    example_object.start_timer(mock_timer)
  end

  describe "#lifetime" do
    it "returns a floating point of the number of second since the timer was started" do
      expect(mock_timer).to receive(:to_f).and_return(example_lifetime)
      expect(example_object.lifetime).to eq example_lifetime
    end

    it "raises Socketry::InternalError if the timer hasn't been started" do
      expect { example_class.new.lifetime }.to raise_error(Socketry::InternalError)
    end
  end

  describe "#set_timeout" do
    it "computes the deadline when it will timeout" do
      expect(mock_timer).to receive(:to_f).and_return(example_lifetime)
      example_object.set_timeout(example_timeout)
      expect(example_object.deadline).to eq example_deadline
    end

    it "raises Socketry::InternalError if called twice without being cleared" do
      expect(mock_timer).to receive(:to_f).and_return(example_lifetime)
      example_object.set_timeout(example_timeout)

      expect { example_object.set_timeout(example_timeout) }.to raise_error(Socketry::InternalError)
    end
  end

  describe "#clear_timeout" do
    it "clears the timeout deadline if set" do
      expect(mock_timer).to receive(:to_f).and_return(example_lifetime)
      example_object.set_timeout(example_timeout)
      expect(example_object.deadline).to be_a Float

      example_object.clear_timeout(example_timeout)
      expect(example_object.deadline).to be_nil
    end

    it "raises Socketry::InternalError if called when the timeout isn't set" do
      expect { example_object.clear_timeout(example_timeout) }.to raise_error(Socketry::InternalError)
    end
  end

  describe "#time_remaining" do
    let(:lifetime_before_timeout) { example_lifetime + (example_timeout / 2.0) }
    let(:lifetime_after_timeout)  { example_lifetime + example_timeout + 1 }

    before do
      expect(mock_timer).to receive(:to_f).and_return(example_lifetime)
      example_object.set_timeout(example_timeout)
    end

    it "calculates timeouts if we haven't already hit the deadline" do
      expect(mock_timer).to receive(:to_f).and_return(lifetime_before_timeout)
      expect(example_object.time_remaining(example_timeout)).to eq example_deadline - lifetime_before_timeout
    end

    it "raises Socketry::TimeoutError if we've hit the deadline" do
      expect(mock_timer).to receive(:to_f).and_return(lifetime_after_timeout)
      expect { example_object.time_remaining(example_timeout) }.to raise_error(Socketry::TimeoutError)
    end

    it "raises Socketry::InternalError if no timeout is set" do
      expect { example_class.new.time_remaining(example_timeout) }.to raise_error(Socketry::InternalError)
    end
  end
end
