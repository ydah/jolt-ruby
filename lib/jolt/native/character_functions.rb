# frozen_string_literal: true

module Jolt
  module Native
    module CharacterFunctions
      module_function

      def attach(native)
        native.attach_function :JR_CharacterVirtual_Create,
                               %i[pointer pointer pointer pointer float float], :pointer
        native.attach_function :JR_CharacterVirtual_ExtendedUpdate,
                               %i[pointer float uint32 pointer], :void, blocking: true
        native.attach_function :JPH_CharacterBase_Destroy, [:pointer], :void
        native.attach_function :JPH_CharacterBase_GetGroundState, [:pointer], :int
        native.attach_function :JPH_CharacterBase_IsSupported, [:pointer], :bool
        native.attach_function :JPH_CharacterVirtual_GetLinearVelocity,
                               %i[pointer pointer], :void
        native.attach_function :JPH_CharacterVirtual_SetLinearVelocity,
                               %i[pointer pointer], :void
        native.attach_function :JPH_CharacterVirtual_GetPosition, %i[pointer pointer], :void
        native.attach_function :JPH_CharacterVirtual_SetPosition, %i[pointer pointer], :void
        native.attach_function :JPH_CharacterVirtual_GetRotation, %i[pointer pointer], :void
        native.attach_function :JPH_CharacterVirtual_SetRotation, %i[pointer pointer], :void
        native.attach_function :JPH_CharacterVirtual_GetMass, [:pointer], :float
        native.attach_function :JPH_CharacterVirtual_SetMass, %i[pointer float], :void
      end
    end
  end
end
