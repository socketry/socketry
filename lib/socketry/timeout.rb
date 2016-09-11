# frozen_string_literal: true

module Socketry
  # Timeout subsystem
  module Timeout
    DEFAULT_TIMER = Hitimes::Interval

    # Default timeouts (in seconds)
    DEFAULT_TIMEOUTS = {
      read:    5,
      write:   5,
      connect: 5
    }.freeze

    def start_timer(timer_class: DEFAULT_TIMER_CLASS)
      @interval = timer_class.new
      @interval.start
    end

    def lifetime
      @interval.to_f
    end
  end
end
