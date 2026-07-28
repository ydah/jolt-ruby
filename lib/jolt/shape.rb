# frozen_string_literal: true

module Jolt
  class Shape
    extend ShapeBuilders

    DEFAULT_CONVEX_RADIUS = 0.05

    class << self
      def box(half_extents, convex_radius: DEFAULT_CONVEX_RADIUS)
        Jolt.init
        extents = Conversions.native_vec3(half_extents, name: "half_extents")
        %i[x y z].each do |component|
          raise InvalidArgumentError, "half_extents must be positive" unless extents[component].positive?
        end
        radius = Conversions.non_negative_float(convex_radius, "convex_radius")
        build(Native.JPH_BoxShape_Create(extents.pointer, radius), :box)
      end

      def sphere(radius)
        Jolt.init
        build(Native.JPH_SphereShape_Create(Conversions.positive_float(radius, "radius")), :sphere)
      end

      def capsule(half_height:, radius:)
        Jolt.init
        height = Conversions.non_negative_float(half_height, "half_height")
        radius = Conversions.positive_float(radius, "radius")
        build(Native.JPH_CapsuleShape_Create(height, radius), :capsule)
      end

      def cylinder(half_height:, radius:)
        Jolt.init
        height = Conversions.positive_float(half_height, "half_height")
        radius = Conversions.positive_float(radius, "radius")
        build(Native.JPH_CylinderShape_Create(height, radius), :cylinder)
      end

      private

      def build(pointer, kind)
        raise ShapeError, "failed to create #{kind} shape" if pointer.null?

        new(pointer, kind)
      end
    end

    attr_reader :kind

    def initialize(pointer, kind)
      @pointer = pointer
      @kind = kind
      @released = false
    end

    def release
      return if @released

      Native.JPH_Shape_Destroy(@pointer)
      @released = true
      @pointer = nil
      nil
    end

    def released?
      @released
    end

    def volume
      check_alive!
      Native.JPH_Shape_GetVolume(@pointer)
    end

    def must_be_static?
      check_alive!
      Native.JPH_Shape_MustBeStatic(@pointer)
    end

    def native_pointer
      check_alive!
      @pointer
    end

    private

    def check_alive!
      raise UseAfterDestroyError, "shape has been released" if @released
    end
  end
end
