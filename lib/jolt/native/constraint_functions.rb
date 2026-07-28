# frozen_string_literal: true

module Jolt
  module Native
    module ConstraintFunctions
      module_function

      def attach(native)
        attach_constructors(native)
        attach_lifecycle(native)
        attach_distance(native)
        attach_hinge(native)
        attach_slider(native)
      end

      def attach_constructors(native)
        native.attach_function :JR_Constraint_CreateFixed,
                               %i[pointer uint32 uint32 pointer], :pointer
        native.attach_function :JR_Constraint_CreatePoint,
                               %i[pointer uint32 uint32 pointer], :pointer
        native.attach_function :JR_Constraint_CreateDistance,
                               %i[pointer uint32 uint32 pointer pointer float float], :pointer
        native.attach_function :JR_Constraint_CreateHinge,
                               %i[pointer uint32 uint32 pointer pointer pointer bool float float], :pointer
        native.attach_function :JR_Constraint_CreateSlider,
                               %i[pointer uint32 uint32 pointer pointer bool float float], :pointer
      end

      def attach_lifecycle(native)
        native.attach_function :JPH_PhysicsSystem_RemoveConstraint, %i[pointer pointer], :void
        native.attach_function :JPH_Constraint_Destroy, [:pointer], :void
        native.attach_function :JPH_Constraint_GetEnabled, [:pointer], :bool
        native.attach_function :JPH_Constraint_SetEnabled, %i[pointer bool], :void
      end

      def attach_distance(native)
        native.attach_function :JPH_DistanceConstraint_SetDistance,
                               %i[pointer float float], :void
        native.attach_function :JPH_DistanceConstraint_GetMinDistance, [:pointer], :float
        native.attach_function :JPH_DistanceConstraint_GetMaxDistance, [:pointer], :float
      end

      def attach_hinge(native)
        native.attach_function :JPH_HingeConstraint_GetCurrentAngle, [:pointer], :float
        native.attach_function :JPH_HingeConstraint_SetMotorState, %i[pointer int], :void
        native.attach_function :JPH_HingeConstraint_SetTargetAngularVelocity,
                               %i[pointer float], :void
        native.attach_function :JPH_HingeConstraint_GetTargetAngularVelocity, [:pointer], :float
        native.attach_function :JPH_HingeConstraint_SetLimits, %i[pointer float float], :void
        native.attach_function :JPH_HingeConstraint_GetLimitsMin, [:pointer], :float
        native.attach_function :JPH_HingeConstraint_GetLimitsMax, [:pointer], :float
      end

      def attach_slider(native)
        native.attach_function :JPH_SliderConstraint_GetCurrentPosition, [:pointer], :float
        native.attach_function :JPH_SliderConstraint_SetMotorState, %i[pointer int], :void
        native.attach_function :JPH_SliderConstraint_SetTargetVelocity, %i[pointer float], :void
        native.attach_function :JPH_SliderConstraint_GetTargetVelocity, [:pointer], :float
        native.attach_function :JPH_SliderConstraint_SetLimits, %i[pointer float float], :void
        native.attach_function :JPH_SliderConstraint_GetLimitsMin, [:pointer], :float
        native.attach_function :JPH_SliderConstraint_GetLimitsMax, [:pointer], :float
      end
    end
  end
end
