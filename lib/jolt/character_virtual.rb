# frozen_string_literal: true

module Jolt
  class CharacterVirtual
    GROUND_STATES = {
      0 => :on_ground,
      1 => :sliding,
      2 => :in_air,
      3 => :in_air
    }.freeze

    attr_reader :system, :shape, :layer

    def initialize(system, shape:, position: [0, 0, 0], rotation: [0, 0, 0, 1],
                   max_slope: Math::PI / 4, mass: 70, layer: :moving)
      unless system.is_a?(System) && !system.destroyed?
        raise InvalidArgumentError, "system must be a live Jolt::System"
      end
      unless shape.is_a?(Shape) && !shape.released?
        raise InvalidArgumentError, "shape must be a live Jolt::Shape"
      end

      @system = system
      @shape = shape
      layer_id = @system.layers.object_layer_id(layer)
      @layer = layer.to_sym
      native_position = Conversions.native_vec3(position, name: "position")
      native_rotation = Conversions.native_quat(rotation)
      slope = Conversions.positive_float(max_slope, "max_slope")
      character_mass = Conversions.positive_float(mass, "mass")
      @pointer = Native.JR_CharacterVirtual_Create(
        @system.__native_pointer,
        @shape.native_pointer,
        native_position.pointer,
        native_rotation.pointer,
        slope,
        character_mass
      )
      raise InitializationError, "failed to create virtual character" if @pointer.null?

      @layer_id = layer_id
      @destroyed = false
      @system.__register_character(self, @shape)
    rescue StandardError
      Native.JPH_CharacterBase_Destroy(@pointer) if @pointer && !@pointer.null?
      raise
    end

    def position
      read_vec3(:JPH_CharacterVirtual_GetPosition)
    end

    def position=(value)
      write_vec3(:JPH_CharacterVirtual_SetPosition, value, "position")
    end

    def rotation
      check_alive!
      native = Native::Quat.new
      Native.JPH_CharacterVirtual_GetRotation(@pointer, native.pointer)
      Conversions.quat(native)
    end

    def rotation=(value)
      check_alive!
      native = Conversions.native_quat(value)
      Native.JPH_CharacterVirtual_SetRotation(@pointer, native.pointer)
      value
    end

    def velocity
      read_vec3(:JPH_CharacterVirtual_GetLinearVelocity)
    end
    alias linear_velocity velocity

    def velocity=(value)
      write_vec3(:JPH_CharacterVirtual_SetLinearVelocity, value, "velocity")
    end
    alias linear_velocity= velocity=

    def mass
      check_alive!
      Native.JPH_CharacterVirtual_GetMass(@pointer)
    end

    def mass=(value)
      check_alive!
      Native.JPH_CharacterVirtual_SetMass(
        @pointer,
        Conversions.positive_float(value, "mass")
      )
      value
    end

    def update(delta_time)
      check_alive!
      Native.JR_CharacterVirtual_ExtendedUpdate(
        @pointer,
        Conversions.positive_float(delta_time, "delta_time"),
        @layer_id,
        @system.__native_pointer
      )
      self
    end

    def ground_state
      check_alive!
      GROUND_STATES.fetch(Native.JPH_CharacterBase_GetGroundState(@pointer))
    end

    def supported?
      check_alive!
      Native.JPH_CharacterBase_IsSupported(@pointer)
    end

    def destroy
      @system.__destroy_character(self)
    end

    def destroyed?
      @destroyed
    end

    def __native_pointer
      check_alive!
      @pointer
    end

    def __destroy_native
      Native.JPH_CharacterBase_Destroy(@pointer) if @pointer && !@pointer.null?
      @pointer = nil
      @destroyed = true
    end

    private

    def read_vec3(function)
      check_alive!
      native = Native::Vec3.new
      Native.public_send(function, @pointer, native.pointer)
      Conversions.vec3(native)
    end

    def write_vec3(function, value, name)
      check_alive!
      native = Conversions.native_vec3(value, name:)
      Native.public_send(function, @pointer, native.pointer)
      value
    end

    def check_alive!
      raise UseAfterDestroyError, "virtual character has been destroyed" if @destroyed
      raise UseAfterDestroyError, "system has been destroyed" if @system.destroyed?
    end
  end
end
