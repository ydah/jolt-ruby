# frozen_string_literal: true

module Jolt
  module Native
    module ConstraintFunctions
      module_function

      def attach(native)
        attach_constructors(native)
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

    end
  end
end
