# frozen_string_literal: true

module Jolt
  class BodyCollection
    include Enumerable

    MOTION_TYPES = {static: 0, kinematic: 1, dynamic: 2}.freeze
    INVALID_BODY_ID = 0xffff_ffff

    def initialize(system)
      @system = system
    end

    def create(shape:, position: [0, 0, 0], rotation: [0, 0, 0, 1],
               motion: :dynamic, layer: nil, activate: nil, friction: 0.2,
               restitution: 0.0, linear_damping: 0.05, angular_damping: 0.05,
               gravity_factor: 1.0, mass: nil, ccd: false, sensor: false,
               user_data: nil)
      @system.__check_alive!
      validate_shape!(shape)
      motion_type = MOTION_TYPES.fetch(motion.to_sym)
      layer ||= motion_type.zero? ? :non_moving : :moving
      layer_id = @system.layers.object_layer_id(layer)
      settings = create_settings(shape, position, rotation, motion_type, layer_id)
      configure_settings(
        settings,
        friction:, restitution:, linear_damping:, angular_damping:,
        gravity_factor:, mass:, ccd:, sensor:, motion_type:
      )
      id = Native.JPH_BodyInterface_CreateAndAddBody(
        @system.__body_interface, settings, activation(activate, motion_type)
      )
      raise InitializationError, "failed to create body" if id == INVALID_BODY_ID

      Body.new(@system, id).tap do |body|
        @system.__register_body(body, shape)
        body.user_data = user_data unless user_data.nil?
      end
    rescue KeyError
      raise InvalidArgumentError, "motion must be one of: #{MOTION_TYPES.keys.join(", ")}"
    ensure
      Native.JPH_BodyCreationSettings_Destroy(settings) if settings && !settings.null?
    end

    def each(&block)
      return enum_for(:each) unless block

      @system.__bodies_snapshot.each(&block)
    end

    def [](id)
      @system.__body(id)
    end

    def size
      @system.__bodies_snapshot.size
    end
    alias length size

    private

    def create_settings(shape, position, rotation, motion_type, layer_id)
      position = Conversions.native_vec3(position, name: "position")
      rotation = Conversions.native_quat(rotation)
      settings = Native.JPH_BodyCreationSettings_Create3(
        shape.native_pointer, position.pointer, rotation.pointer, motion_type, layer_id
      )
      raise InitializationError, "failed to allocate body creation settings" if settings.null?

      settings
    end

    def configure_settings(settings, friction:, restitution:, linear_damping:, angular_damping:,
                           gravity_factor:, mass:, ccd:, sensor:, motion_type:)
      {
        Friction: [friction, "friction"],
        Restitution: [restitution, "restitution"],
        LinearDamping: [linear_damping, "linear_damping"],
        AngularDamping: [angular_damping, "angular_damping"],
        GravityFactor: [gravity_factor, "gravity_factor"]
      }.each do |name, (value, label)|
        number = Conversions.non_negative_float(value, label)
        Native.public_send(:"JPH_BodyCreationSettings_Set#{name}", settings, number)
      end
      Native.JPH_BodyCreationSettings_SetIsSensor(settings, !!sensor)
      Native.JPH_BodyCreationSettings_SetMotionQuality(settings, ccd ? 1 : 0)
      configure_mass(settings, mass, motion_type) unless mass.nil?
    end

    def configure_mass(settings, mass, motion_type)
      raise InvalidArgumentError, "mass is only valid for dynamic bodies" unless motion_type == MOTION_TYPES[:dynamic]

      mass = Conversions.positive_float(mass, "mass")
      properties = Native::MassProperties.new
      Native.JPH_BodyCreationSettings_GetMassPropertiesOverride(settings, properties.pointer)
      properties[:mass] = mass
      Native.JPH_BodyCreationSettings_SetMassPropertiesOverride(settings, properties.pointer)
      Native.JPH_BodyCreationSettings_SetOverrideMassProperties(settings, 1)
    end

    def activation(value, motion_type)
      activate = value.nil? ? motion_type == MOTION_TYPES[:dynamic] : !!value
      activate ? 0 : 1
    end

    def validate_shape!(shape)
      raise InvalidArgumentError, "shape must be a Jolt::Shape" unless shape.is_a?(Shape)

      shape.native_pointer
    end
  end
end
