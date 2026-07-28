# frozen_string_literal: true

module Jolt
  class Error < StandardError; end
  class NativeLoadError < Error; end
  class InitializationError < Error; end
  class InvalidArgumentError < Error; end
  class UseAfterDestroyError < Error; end
  class ConcurrentAccessError < Error; end
  class ShapeError < Error; end
  class PhysicsUpdateError < Error; end
end
