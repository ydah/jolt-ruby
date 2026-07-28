# frozen_string_literal: true

module Jolt
  module Native
    module LayerFunctions
      module_function

      def attach(native)
        native.attach_function :JPH_BroadPhaseLayerInterfaceTable_Create, %i[uint32 uint32], :pointer
        native.attach_function :JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer,
                               %i[pointer uint32 uint8], :void
        native.attach_function :JPH_BroadPhaseLayerInterface_Destroy, [:pointer], :void

        native.attach_function :JPH_ObjectLayerPairFilterTable_Create, [:uint32], :pointer
        native.attach_function :JPH_ObjectLayerPairFilterTable_EnableCollision,
                               %i[pointer uint32 uint32], :void
        native.attach_function :JPH_ObjectLayerPairFilter_Destroy, [:pointer], :void

        native.attach_function :JPH_ObjectVsBroadPhaseLayerFilterTable_Create,
                               %i[pointer uint32 pointer uint32], :pointer
        native.attach_function :JPH_ObjectVsBroadPhaseLayerFilter_Destroy, [:pointer], :void
      end
    end
  end
end
