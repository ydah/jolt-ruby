# frozen_string_literal: true

module Jolt
  module SystemConstraints
    def __register_constraint(constraint)
      @constraint_registry << constraint
    end

    def __destroy_constraint(constraint)
      return if constraint.destroyed?

      __check_alive!
      removed = @constraint_registry.delete(constraint)
      raise InvalidArgumentError, "constraint does not belong to this system" unless removed

      pointer = constraint.__native_pointer
      Native.JPH_PhysicsSystem_RemoveConstraint(@pointer, pointer)
      Native.JPH_Constraint_Destroy(pointer)
      constraint.__mark_destroyed
      nil
    end

    def __constraints_snapshot
      @constraint_registry.dup
    end

    def __destroy_constraints_for(body)
      @constraint_registry.select { |constraint| constraint.__involves?(body) }.each(&:destroy)
    end

    def __destroy_all_constraints
      @constraint_registry.dup.each(&:destroy)
    end
  end
end
