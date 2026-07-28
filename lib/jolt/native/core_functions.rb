# frozen_string_literal: true

module Jolt
  module Native
    module CoreFunctions
      module_function

      def attach(native)
        native.attach_function :JPH_Init, [], :bool
        native.attach_function :JPH_Shutdown, [], :void
        native.attach_function :JPH_JobSystemThreadPool_Create, [:pointer], :pointer
        native.attach_function :JPH_JobSystem_Destroy, [:pointer], :void
      end
    end
  end
end
