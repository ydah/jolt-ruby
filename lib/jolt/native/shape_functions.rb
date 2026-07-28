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
        native.attach_function :JPH_Shape_MustBeStatic, [:pointer], :bool
        native.attach_function :JPH_ShapeSettings_Destroy, [:pointer], :void

        native.attach_function :JPH_BoxShape_Create, %i[pointer float], :pointer
        native.attach_function :JPH_SphereShape_Create, [:float], :pointer
        native.attach_function :JPH_CapsuleShape_Create, %i[float float], :pointer
        native.attach_function :JPH_CylinderShape_Create, %i[float float], :pointer

        native.attach_function :JPH_ConvexHullShapeSettings_Create,
                               %i[pointer uint32 float], :pointer
        native.attach_function :JPH_ConvexHullShapeSettings_CreateShape, [:pointer], :pointer
        native.attach_function :JPH_MeshShapeSettings_Create2,
                               %i[pointer uint32 pointer uint32], :pointer
        native.attach_function :JPH_MeshShapeSettings_CreateShape, [:pointer], :pointer
        native.attach_function :JPH_HeightFieldShapeSettings_Create,
                               %i[pointer pointer pointer uint32 pointer], :pointer
        native.attach_function :JPH_HeightFieldShapeSettings_CreateShape, [:pointer], :pointer

        native.attach_function :JPH_StaticCompoundShapeSettings_Create, [], :pointer
        native.attach_function :JPH_CompoundShapeSettings_AddShape2,
                               %i[pointer pointer pointer pointer uint32], :void
        native.attach_function :JPH_StaticCompoundShape_Create, [:pointer], :pointer
        native.attach_function :JPH_ScaledShape_Create, %i[pointer pointer], :pointer
        native.attach_function :JPH_RotatedTranslatedShape_Create,
                               %i[pointer pointer pointer], :pointer
      end
    end
  end
end
