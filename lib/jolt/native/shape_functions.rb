# frozen_string_literal: true

module Jolt
  module Native
    module ShapeFunctions
      module_function

      def attach(native)
        native.attach_function :JPH_Shape_Destroy, [:pointer], :void
        native.attach_function :JPH_Shape_GetType, [:pointer], :int
        native.attach_function :JPH_Shape_GetSubType, [:pointer], :int
        native.attach_function :JPH_Shape_GetVolume, [:pointer], :float

        native.attach_function :JPH_BoxShape_Create, %i[pointer float], :pointer
        native.attach_function :JPH_SphereShape_Create, [:float], :pointer
        native.attach_function :JPH_CapsuleShape_Create, %i[float float], :pointer
        native.attach_function :JPH_CylinderShape_Create, %i[float float], :pointer
      end
    end
  end
end
