# frozen_string_literal: true

require_relative "jolt/version"
require_relative "jolt/errors"
require_relative "jolt/native"
require_relative "jolt/conversions"
require_relative "jolt/layers"
require_relative "jolt/shape"
require_relative "jolt/fixed_stepper"
require_relative "jolt/transform"
require_relative "jolt/body_dynamics"
require_relative "jolt/body"
require_relative "jolt/body_collection"
require_relative "jolt/system"

module Jolt
  @lifecycle_mutex = Mutex.new
  @initialized = false
  @systems = []
  @at_exit_registered = false

  class << self
    def init
      @lifecycle_mutex.synchronize do
        return self if @initialized

        Native.load!
        raise InitializationError, "Jolt Physics initialization failed" unless Native.JPH_Init

        @initialized = true
        unless @at_exit_registered
          at_exit { shutdown }
          @at_exit_registered = true
        end
      end

      self
    end

    def initialized?
      @lifecycle_mutex.synchronize { @initialized }
    end

    def shutdown
      systems = @lifecycle_mutex.synchronize do
        return unless @initialized

        @systems.dup
      end
      systems.each(&:destroy)

      @lifecycle_mutex.synchronize do
        return unless @initialized

        @systems.clear
        Native.JPH_Shutdown
        @initialized = false
      end
    end

    def __register_system(system)
      @lifecycle_mutex.synchronize do
        raise InitializationError, "Jolt Physics is not initialized" unless @initialized

        @systems << system
      end
    end

    def __unregister_system(system)
      @lifecycle_mutex.synchronize { @systems.delete(system) }
    end
  end
end
