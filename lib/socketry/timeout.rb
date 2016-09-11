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
      raise InternalError, "timer already started" if @interval

      @interval = timer_class.new
      @interval.start

      @deadline = nil
    end

    def lifetime
      @interval.to_f
    end

    def set_timeout(timeout)
      raise InternalError, "deadline already set" if @deadline
      return unless timeout
      @deadline = @interval.to_f + timeout
    end

    def clear_timeout(timeout)
      return unless timeout
      raise InternalError, "no deadline set" unless @deadline
      @deadline = nil
    end

    def time_remaining(timeout)
      return unless timeout
      raise InternalError, "no deadline set" unless @deadline
      remaining = @deadline - @interval.to_f
      raise Socketry::TimeoutError, "time expired" if remaining <= 0
      remaining
    end
  end
end
