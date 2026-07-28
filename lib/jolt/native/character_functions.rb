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
      end
    end
  end
end
