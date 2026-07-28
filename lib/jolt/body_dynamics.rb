# frozen_string_literal: true

module Jolt
  module BodyDynamics
    def linear_velocity
      read_vec3(:JPH_BodyInterface_GetLinearVelocity)
    end

    def linear_velocity=(value)
      write_vec3(:JPH_BodyInterface_SetLinearVelocity, value)
    end

    def angular_velocity
      read_vec3(:JPH_BodyInterface_GetAngularVelocity)
    end

    def angular_velocity=(value)
      write_vec3(:JPH_BodyInterface_SetAngularVelocity, value)
    end

    def apply_impulse(impulse, point: nil)
      apply_vector_at_point(:JPH_BodyInterface_AddImpulse, :JPH_BodyInterface_AddImpulse2, impulse, point)
    end

    def apply_angular_impulse(impulse)
      write_vec3(:JPH_BodyInterface_AddAngularImpulse, impulse)
      self
    end

    def add_force(force, point: nil)
      apply_vector_at_point(:JPH_BodyInterface_AddForce, :JPH_BodyInterface_AddForce2, force, point)
    end

    def add_torque(torque)
      write_vec3(:JPH_BodyInterface_AddTorque, torque)
      self
    end

    def active?
      check_alive!
      Native.JPH_BodyInterface_IsActive(body_interface, @id)
    end

    def activate
      check_alive!
      Native.JPH_BodyInterface_ActivateBody(body_interface, @id)
      self
    end

    def deactivate
      check_alive!
      Native.JPH_BodyInterface_DeactivateBody(body_interface, @id)
      self
    end

    def kinematic_move_to(position, rotation, delta_time)
      check_alive!
      position = Conversions.native_vec3(position, name: "position")
      rotation = Conversions.native_quat(rotation)
      delta_time = Conversions.positive_float(delta_time, "delta_time")
      Native.JPH_BodyInterface_MoveKinematic(
        body_interface, @id, position.pointer, rotation.pointer, delta_time
      )
      self
    end

    def friction
      scalar_property(:JPH_BodyInterface_GetFriction)
    end

    def friction=(value)
      write_scalar(:JPH_BodyInterface_SetFriction, value, "friction")
    end

    def restitution
      scalar_property(:JPH_BodyInterface_GetRestitution)
    end

    def restitution=(value)
      write_scalar(:JPH_BodyInterface_SetRestitution, value, "restitution")
    end

    def sensor?
      check_alive!
      Native.JPH_BodyInterface_IsSensor(body_interface, @id)
    end

    def sensor=(value)
      check_alive!
      Native.JPH_BodyInterface_SetIsSensor(body_interface, @id, !!value)
    end
  end
end
