# frozen_string_literal: true

module Jolt
  class ConstraintCollection
    include Enumerable

    class << self
      def interval(value, name)
        values = value.is_a?(Range) ? [value.begin, value.end] : value.to_a
        raise InvalidArgumentError, "#{name} must contain two values" unless values.length == 2

        minimum = Conversions.finite_float(values[0], "#{name} minimum")
        maximum = Conversions.finite_float(values[1], "#{name} maximum")
        raise InvalidArgumentError, "#{name} minimum must not exceed maximum" if minimum > maximum

        [minimum, maximum]
      rescue NoMethodError
        raise InvalidArgumentError, "#{name} must be a Range or two-element array"
      end
    end

    def initialize(system)
      @system = system
    end

    def fixed(body_a:, body_b:, anchor: nil)
      create(:fixed, :JR_Constraint_CreateFixed, body_a, body_b, optional_vec(anchor, "anchor"))
    end

    def point(body_a:, body_b:, anchor:)
      create(:point, :JR_Constraint_CreatePoint, body_a, body_b, vec(anchor, "anchor"))
    end

    def distance(body_a:, body_b:, point_a: nil, point_b: nil, limits: nil)
      validate_body_pair(body_a, body_b)
      point_a ||= body_a.position
      point_b ||= body_b.position
      minimum, maximum = limits ? self.class.interval(limits, "limits") : [-1.0, -1.0]
      create(
        :distance, :JR_Constraint_CreateDistance, body_a, body_b,
        vec(point_a, "point_a"), vec(point_b, "point_b"), minimum, maximum
      )
    end

    def hinge(body_a:, body_b:, anchor:, axis: [0, 1, 0], normal: nil, limits: nil)
      axis = unit_vec(axis, "axis")
      normal = normal ? unit_vec(normal, "normal") : perpendicular(axis)
      has_limits, minimum, maximum = optional_interval(limits)
      create(
        :hinge, :JR_Constraint_CreateHinge, body_a, body_b,
        vec(anchor, "anchor"), axis, normal, has_limits, minimum, maximum
      )
    end

    def slider(body_a:, body_b:, anchor:, axis:, limits: nil)
      has_limits, minimum, maximum = optional_interval(limits)
      create(
        :slider, :JR_Constraint_CreateSlider, body_a, body_b,
        vec(anchor, "anchor"), unit_vec(axis, "axis"), has_limits, minimum, maximum
      )
    end

    def each(&block)
      return enum_for(:each) unless block

      @system.__constraints_snapshot.each(&block)
    end

    def size
      @system.__constraints_snapshot.size
    end
    alias length size

    private

    def create(kind, function, body_a, body_b, *arguments)
      validate_body_pair(body_a, body_b)
      native_arguments = arguments.map { |argument| argument.is_a?(Native::Vec3) ? argument.pointer : argument }
      pointer = Native.public_send(
        function, @system.__native_pointer, body_a.id, body_b.id, *native_arguments
      )
      raise InitializationError, "failed to create #{kind} constraint" if pointer.null?

      Constraint.new(@system, pointer, kind, body_a, body_b).tap do |constraint|
        @system.__register_constraint(constraint)
      end
    end

    def validate_body_pair(body_a, body_b)
      [body_a, body_b].each do |body|
        unless body.is_a?(Body) && body.system.equal?(@system) && !body.destroyed?
          raise InvalidArgumentError, "constraint bodies must be live bodies from this system"
        end
      end
      raise InvalidArgumentError, "constraint bodies must be different" if body_a.equal?(body_b)
    end

    def vec(value, name)
      Conversions.native_vec3(value, name:)
    end

    def unit_vec(value, name)
      Conversions.native_unit_vec3(value, name:)
    end

    def optional_vec(value, name)
      value.nil? ? nil : vec(value, name)
    end

    def optional_interval(value)
      return [false, 0.0, 0.0] if value.nil?

      [true, *self.class.interval(value, "limits")]
    end

    def perpendicular(axis)
      x, y, z = %i[x y z].map { |component| axis[component] }
      reference = y.abs < 0.9 ? [0.0, 1.0, 0.0] : [1.0, 0.0, 0.0]
      rx, ry, rz = reference
      unit_vec([y * rz - z * ry, z * rx - x * rz, x * ry - y * rx], "normal")
    end
  end
end
