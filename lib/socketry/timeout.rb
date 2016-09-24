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

    # Start a timer in the included object
    #
    # @param timer [#start, #to_f] a timer object (ideally monotonic)
    # @return [true] timer started successfully
    # @raise [Socketry::InternalError] if timer is already started
    def start_timer(timer = DEFAULT_TIMER_CLASS.new)
      raise Socketry::InternalError, "timer already started" if defined?(@timer)
      raise Socketry::InternalError, "deadline already set"  if defined?(@deadline)

      @deadline = nil
      @timer = timer
      @timer.start
      true
    end

    # Return how long since the timer has been started
    #
    # @return [Float] number of seconds since the timer has been started
    # @raise [Socketry::InternalError] if timer has not been started
    def lifetime
      raise Socketry::InternalError, "timer not started" unless @timer
      @timer.to_f
    end

    # Set a timeout. Only one timeout may be active at a given time for a given object.
    #
    # @param timeout [Numeric] number of seconds until the timeout is reached
    # @return [Float] deadline (relative to #lifetime) at which the timeout is reached
    # @raise [Socketry::InternalError] if timeout is already set
    def set_timeout(timeout)
      raise Socketry::InternalError, "deadline already set" if @deadline
      return unless timeout
      raise Socketry::TimeoutError, "time expired" if timeout < 0

      @deadline = lifetime + timeout
    end

    # Clear an already-set timeout
    #
    # @param timeout [Numeric] to gauge whether the timeout actually needs to be cleared
    # @raise [Socketry::InternalError] if timeout has not been set
    def clear_timeout(timeout)
      return unless timeout
      raise Socketry::InternalError, "no deadline set" unless @deadline
      @deadline = nil
    end

    # Calculate number of seconds remaining until we hit the timeout
    #
    # @param timeout [Numeric] to gauge whether a timeout needs to be calculated
    # @return [Float] number of seconds remaining until we hit the timeout
    # @raise [Socketry::TimeoutError] if we've already hit the timeout
    # @raise [Socketry::InternalError] if timeout has not been set
    def time_remaining(timeout)
      return unless timeout
      raise Socketry::InternalError, "no deadline set" unless @deadline
      remaining = @deadline - lifetime
      raise Socketry::TimeoutError, "time expired" if remaining <= 0
      remaining
    end
  end
end
