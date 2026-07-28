# frozen_string_literal: true

module Jolt
  class Body
    include BodyDynamics

    attr_reader :id, :system

    def initialize(system, id)
      @system = system
      @id = id
      @destroyed = false
      transform = current_transform
      @previous_transform = transform
      @current_transform = transform
    end

    def position
      read_vec3(:JPH_BodyInterface_GetPosition)
    end

    def position=(value)
      write_vec3(:JPH_BodyInterface_SetPosition, value, activation)
    end

    def rotation
      check_alive!
      native = Native::Quat.new
      Native.JPH_BodyInterface_GetRotation(body_interface, @id, native.pointer)
      Conversions.quat(native)
    end

    def rotation=(value)
      check_alive!
      native = Conversions.native_quat(value)
      Native.JPH_BodyInterface_SetRotation(body_interface, @id, native.pointer, activation)
    end

    def user_data
      check_alive!
      @system.__user_data(@id)
    end

    def user_data=(value)
      check_alive!
      @system.__set_user_data(@id, value)
    end

    def interpolated(alpha)
      check_alive!
      alpha = Conversions.finite_float(alpha, "alpha")
      raise InvalidArgumentError, "alpha must be between 0 and 1" unless alpha.between?(0.0, 1.0)

      Transform.new(
        position: @previous_transform.position.lerp(@current_transform.position, alpha),
        rotation: @previous_transform.rotation.slerp(@current_transform.rotation, alpha)
      )
    end

    def destroy
      @system.__destroy_body(self)
    end

    def destroyed?
      @destroyed
    end

    def hash
      [@system.object_id, @id].hash
    end

    def eql?(other)
      other.is_a?(Body) && other.system.equal?(@system) && other.id == @id
    end
    alias == eql?

    def __capture_before_step
      check_alive!
      @previous_transform = @current_transform
    end

    def __capture_after_step
      check_alive!
      @current_transform = current_transform
    end

    def __mark_destroyed
      @destroyed = true
    end

    private

    def current_transform
      Transform.new(position: position, rotation: rotation)
    end

    def read_vec3(function)
      check_alive!
      native = Native::Vec3.new
      Native.public_send(function, body_interface, @id, native.pointer)
      Conversions.vec3(native)
    end

    def write_vec3(function, value, *extra)
      check_alive!
      native = Conversions.native_vec3(value)
      Native.public_send(function, body_interface, @id, native.pointer, *extra)
      value
    end

    def apply_vector_at_point(center_function, point_function, value, point)
      check_alive!
      native_value = Conversions.native_vec3(value)
      if point
        native_point = Conversions.native_vec3(point, name: "point")
        Native.public_send(point_function, body_interface, @id, native_value.pointer, native_point.pointer)
      else
        Native.public_send(center_function, body_interface, @id, native_value.pointer)
      end
      self
    end

    def scalar_property(function)
      check_alive!
      Native.public_send(function, body_interface, @id)
    end

    def write_scalar(function, value, name)
      check_alive!
      number = Conversions.non_negative_float(value, name)
      Native.public_send(function, body_interface, @id, number)
    end

    def activation
      0
    end

    def body_interface
      @system.__body_interface
    end

    def check_alive!
      raise UseAfterDestroyError, "body #{@id} has been destroyed" if @destroyed
      @system.__check_alive!
    end
  end
end
