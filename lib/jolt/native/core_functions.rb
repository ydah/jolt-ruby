# frozen_string_literal: true

module Jolt
  module Native
    module CoreFunctions
      module_function

      def attach(native)
        native.attach_function :JR_ContactQueue_Create, [:uint32], :pointer
        native.attach_function :JR_ContactQueue_Destroy, [:pointer], :void
        native.attach_function :JR_ContactQueue_GetListener, [:pointer], :pointer
        native.attach_function :JR_ContactQueue_Pop, %i[pointer pointer], :bool
        native.attach_function :JR_ContactQueue_GetDroppedCount, [:pointer], :uint64
      end
    end
  end
end
