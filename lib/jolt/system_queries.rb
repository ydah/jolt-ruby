# frozen_string_literal: true

module Jolt
  module SystemQueries
    def raycast(origin:, direction:, layer_mask: nil)
      __check_alive!
      origin_native = Conversions.native_vec3(origin, name: "origin")
      direction_native = Conversions.native_vec3(direction, name: "direction")
      direction_vector = Conversions.vec3(direction_native)
      if direction_vector.length <= Float::EPSILON
        raise InvalidArgumentError, "direction must not be zero"
      end

      filter, filter_context = object_layer_filter(layer_mask)
      result = Native::RayCastResult.new
      hit = Native.JPH_NarrowPhaseQuery_CastRay(
        @narrow_phase_query,
        origin_native.pointer,
        direction_native.pointer,
        result.pointer,
        nil,
        filter,
        nil
      )
      return nil unless hit

      build_hit(origin_native, direction_native, result)
    ensure
      Native.JPH_ObjectLayerFilter_Destroy(filter) if filter && !filter.null?
      filter_context = nil
    end

    def overlap_sphere(center, radius, layer_mask: nil, &block)
      center_native = Conversions.native_vec3(center, name: "center")
      radius = Conversions.positive_float(radius, "radius")
      collect_overlapping_bodies(
        :JPH_BroadPhaseQuery_CollideSphere,
        center_native.pointer,
        radius,
        layer_mask:,
        &block
      )
    end

    def overlap_point(point, layer_mask: nil, &block)
      point_native = Conversions.native_vec3(point, name: "point")
      collect_overlapping_bodies(
        :JPH_BroadPhaseQuery_CollidePoint,
        point_native.pointer,
        layer_mask:,
        &block
      )
    end

    private

    def collect_overlapping_bodies(function, *query_arguments, layer_mask:)
      __check_alive!
      filter, filter_context = object_layer_filter(layer_mask)
      callback, body_ids = Native::QueryFunctions.body_collector
      Native.public_send(
        function,
        @broad_phase_query,
        *query_arguments,
        callback,
        nil,
        nil,
        filter
      )
      bodies = body_ids.uniq.filter_map { |id| @body_registry[id] }
      bodies.each { |body| yield body } if block_given?
      bodies
    ensure
      Native.JPH_ObjectLayerFilter_Destroy(filter) if filter && !filter.null?
      filter_context = callback = nil
    end

    def object_layer_filter(layer_mask)
      return [nil, nil] if layer_mask.nil?

      layer_ids = Array(layer_mask).map { |name| @layers.object_layer_id(name) }.uniq
      Native::QueryFunctions.object_layer_filter(
        Native, layer_ids, @layers.object_layers.length
      )
    end

    def build_hit(origin, direction, result)
      fraction = result[:fraction]
      point = Native::Vec3.new
      %i[x y z].each do |component|
        point[component] = origin[component] + direction[component] * fraction
      end

      normal = Native::Vec3.new
      body_pointer = Native.JPH_PhysicsSystem_GetBodyPtr(@pointer, result[:body_id])
      unless body_pointer.null?
        Native.JPH_Body_GetWorldSpaceSurfaceNormal(
          body_pointer, result[:sub_shape_id], point.pointer, normal.pointer
        )
      end

      Hit.new(
        body: @body_registry[result[:body_id]],
        fraction:,
        point: Conversions.vec3(point),
        normal: Conversions.vec3(normal),
        sub_shape_id: result[:sub_shape_id]
      )
    end
  end
end
