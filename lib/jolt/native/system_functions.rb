# frozen_string_literal: true

module Jolt
  module Native
    module SystemFunctions
      module_function

      def attach(native)
        attach_system(native)
        attach_body_creation(native)
        attach_body_access(native)
      end

      def attach_system(native)
        native.attach_function :JPH_PhysicsSystem_Create, [:pointer], :pointer
        native.attach_function :JPH_PhysicsSystem_Destroy, [:pointer], :void
        native.attach_function :JPH_PhysicsSystem_GetBodyInterface, [:pointer], :pointer
        native.attach_function :JPH_PhysicsSystem_GetBodyPtr, %i[pointer uint32], :pointer
        native.attach_function :JPH_PhysicsSystem_GetNarrowPhaseQuery, [:pointer], :pointer
        native.attach_function :JPH_PhysicsSystem_SetGravity, %i[pointer pointer], :void
        native.attach_function :JPH_PhysicsSystem_GetGravity, %i[pointer pointer], :void
        native.attach_function :JPH_PhysicsSystem_OptimizeBroadPhase, [:pointer], :void
        native.attach_function :JPH_PhysicsSystem_Update, %i[pointer float int pointer], :int, blocking: true
        native.attach_function :JPH_PhysicsSystem_SetContactListener, %i[pointer pointer], :void
      end

      def attach_body_creation(native)
        native.attach_function :JPH_BodyCreationSettings_Create3,
                               %i[pointer pointer pointer int uint32], :pointer
        native.attach_function :JPH_BodyCreationSettings_Destroy, [:pointer], :void
        {
          Friction: :float,
          Restitution: :float,
          LinearDamping: :float,
          AngularDamping: :float,
          GravityFactor: :float
        }.each do |name, type|
          native.attach_function :"JPH_BodyCreationSettings_Set#{name}", [:pointer, type], :void
        end
        native.attach_function :JPH_BodyCreationSettings_SetIsSensor, %i[pointer bool], :void
        native.attach_function :JPH_BodyCreationSettings_SetMotionQuality, %i[pointer int], :void
        native.attach_function :JPH_BodyCreationSettings_GetMassPropertiesOverride,
                               %i[pointer pointer], :void
        native.attach_function :JPH_BodyCreationSettings_SetMassPropertiesOverride,
                               %i[pointer pointer], :void
        native.attach_function :JPH_BodyCreationSettings_SetOverrideMassProperties,
                               %i[pointer int], :void
        native.attach_function :JPH_MassProperties_ScaleToMass, %i[pointer float], :void

        native.attach_function :JPH_BodyInterface_CreateAndAddBody,
                               %i[pointer pointer int], :uint32
        native.attach_function :JPH_BodyInterface_RemoveAndDestroyBody,
                               %i[pointer uint32], :void
        native.attach_function :JPH_BodyInterface_IsAdded, %i[pointer uint32], :bool
      end

      def attach_body_access(native)
        attach_body_vectors(native)
        native.attach_function :JPH_BodyInterface_GetPosition, %i[pointer uint32 pointer], :void
        native.attach_function :JPH_BodyInterface_SetPosition, %i[pointer uint32 pointer int], :void
        native.attach_function :JPH_BodyInterface_GetRotation, %i[pointer uint32 pointer], :void
        native.attach_function :JPH_BodyInterface_SetRotation, %i[pointer uint32 pointer int], :void
        native.attach_function :JPH_BodyInterface_IsActive, %i[pointer uint32], :bool
        native.attach_function :JPH_BodyInterface_ActivateBody, %i[pointer uint32], :void
        native.attach_function :JPH_BodyInterface_DeactivateBody, %i[pointer uint32], :void
        native.attach_function :JPH_BodyInterface_MoveKinematic,
                               %i[pointer uint32 pointer pointer float], :void
        native.attach_function :JPH_BodyInterface_SetFriction, %i[pointer uint32 float], :void
        native.attach_function :JPH_BodyInterface_GetFriction, %i[pointer uint32], :float
        native.attach_function :JPH_BodyInterface_SetRestitution, %i[pointer uint32 float], :void
        native.attach_function :JPH_BodyInterface_GetRestitution, %i[pointer uint32], :float
        native.attach_function :JPH_BodyInterface_SetIsSensor, %i[pointer uint32 bool], :void
        native.attach_function :JPH_BodyInterface_IsSensor, %i[pointer uint32], :bool
        native.attach_function :JPH_Body_GetWorldSpaceSurfaceNormal,
                               %i[pointer uint32 pointer pointer], :void
      end

      def attach_body_vectors(native)
        %w[LinearVelocity AngularVelocity].each do |name|
          native.attach_function :"JPH_BodyInterface_Get#{name}", %i[pointer uint32 pointer], :void
          native.attach_function :"JPH_BodyInterface_Set#{name}", %i[pointer uint32 pointer], :void
        end
        native.attach_function :JPH_BodyInterface_AddImpulse, %i[pointer uint32 pointer], :void
        native.attach_function :JPH_BodyInterface_AddImpulse2, %i[pointer uint32 pointer pointer], :void
        native.attach_function :JPH_BodyInterface_AddAngularImpulse, %i[pointer uint32 pointer], :void
        native.attach_function :JPH_BodyInterface_AddForce, %i[pointer uint32 pointer], :void
        native.attach_function :JPH_BodyInterface_AddForce2, %i[pointer uint32 pointer pointer], :void
        native.attach_function :JPH_BodyInterface_AddTorque, %i[pointer uint32 pointer], :void
      end
    end
  end
end
