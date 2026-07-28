# frozen_string_literal: true

require "larb"

module Jolt
  module Conversions
    module_function

    def native_vec3(value, name: "vector")
      values = components(value, 3, name)
      Native::Vec3.new.tap do |native|
        native[:x], native[:y], native[:z] = values
      end
    end

    def native_quat(value, name: "rotation")
      values = components(value, 4, name)
      length = Math.sqrt(values.sum { |component| component * component })
      raise InvalidArgumentError, "#{name} must not be a zero quaternion" if length <= Float::EPSILON

      values.map! { |component| component / length }
      Native::Quat.new.tap do |native|
        native[:x], native[:y], native[:z], native[:w] = values
      end
    end

    def native_unit_vec3(value, name:)
      native = native_vec3(value, name:)
      length = Math.sqrt(%i[x y z].sum { |component| native[component]**2 })
      raise InvalidArgumentError, "#{name} must not be zero" if length <= Float::EPSILON

      %i[x y z].each { |component| native[component] /= length }
      native
    end

    def vec3(native)
      Larb::Vec3.new(native[:x], native[:y], native[:z])
    end

    def quat(native)
      Larb::Quat.new(native[:x], native[:y], native[:z], native[:w])
    end

    def positive_float(value, name)
      number = finite_float(value, name)
      raise InvalidArgumentError, "#{name} must be greater than zero" unless number.positive?

      number
    end

    def non_negative_float(value, name)
      number = finite_float(value, name)
      raise InvalidArgumentError, "#{name} must be non-negative" if number.negative?

      number
    end

    def finite_float(value, name)
      number = Float(value)
      raise InvalidArgumentError, "#{name} must be finite" unless number.finite?

      number
    rescue TypeError, ArgumentError
      raise InvalidArgumentError, "#{name} must be a number"
    end

    def components(value, count, name)
      values = value.respond_to?(:to_a) ? value.to_a : nil
      unless values&.length == count
        raise InvalidArgumentError, "#{name} must contain exactly #{count} components"
      end

      values.map.with_index { |component, index| finite_float(component, "#{name}[#{index}]") }
    end
  end
end
