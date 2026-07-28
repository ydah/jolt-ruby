# frozen_string_literal: true

require_relative "jolt/version"
require_relative "jolt/errors"
require_relative "jolt/native"

module Jolt
  @lifecycle_mutex = Mutex.new
  @initialized = false

  class << self
    def init
      @lifecycle_mutex.synchronize do
        return self if @initialized

        Native.load!
        raise InitializationError, "Jolt Physics initialization failed" unless Native.JPH_Init

        @initialized = true
        at_exit { shutdown }
      end

      self
    end

    def initialized?
      @lifecycle_mutex.synchronize { @initialized }
    end

    def shutdown
      @lifecycle_mutex.synchronize do
        return unless @initialized

        Native.JPH_Shutdown
        @initialized = false
      end
    end
  end
end
