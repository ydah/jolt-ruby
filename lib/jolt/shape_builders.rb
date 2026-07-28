# frozen_string_literal: true

module Jolt
  module ShapeBuilders
    def convex_hull(points, max_convex_radius: Shape::DEFAULT_CONVEX_RADIUS)
      Jolt.init
      coordinates = packed_floats(points, 3, "points")
      raise InvalidArgumentError, "convex hull requires at least 4 points" if coordinates.length < 12

      point_memory = float_memory(coordinates)
      settings = Native.JPH_ConvexHullShapeSettings_Create(
        point_memory, coordinates.length / 3,
        Conversions.non_negative_float(max_convex_radius, "max_convex_radius")
      )
      create_from_settings(settings, :convex_hull, :JPH_ConvexHullShapeSettings_CreateShape)
    end

    def mesh(vertices:, indices:)
      Jolt.init
      coordinates = packed_floats(vertices, 3, "vertices")
      triangles = packed_indices(indices)
      vertex_count = coordinates.length / 3
      raise InvalidArgumentError, "mesh requires at least 3 vertices" if vertex_count < 3
      raise InvalidArgumentError, "mesh requires at least 1 triangle" if triangles.empty?
      raise InvalidArgumentError, "mesh index is out of bounds" if triangles.any? { |index| index >= vertex_count }

      vertex_memory = float_memory(coordinates)
      triangle_memory = indexed_triangle_memory(triangles)
      settings = Native.JPH_MeshShapeSettings_Create2(
        vertex_memory, vertex_count, triangle_memory, triangles.length / 3
      )
      create_from_settings(settings, :mesh, :JPH_MeshShapeSettings_CreateShape)
    end

    def heightfield(samples:, size:, offset: [0, 0, 0], scale: [1, 1, 1])
      Jolt.init
      unless size.is_a?(Integer) && size >= 4
        raise InvalidArgumentError, "size must be an integer greater than or equal to 4"
      end
      values = packed_floats(samples, 1, "samples")
      unless values.length == size * size
        raise InvalidArgumentError, "samples must contain size * size values"
      end

      sample_memory = float_memory(values)
      offset = Conversions.native_vec3(offset, name: "offset")
      scale = Conversions.native_vec3(scale, name: "scale")
      settings = Native.JPH_HeightFieldShapeSettings_Create(
        sample_memory, offset.pointer, scale.pointer, size, nil
      )
      create_from_settings(settings, :heightfield, :JPH_HeightFieldShapeSettings_CreateShape)
    end

    def compound(children)
      Jolt.init
      children = children.to_a
      raise InvalidArgumentError, "compound requires at least one child" if children.empty?

      settings = Native.JPH_StaticCompoundShapeSettings_Create
      raise ShapeError, "failed to create compound settings" if settings.null?

      children.each_with_index do |child, index|
        shape, position, rotation = child
        raise InvalidArgumentError, "child #{index} shape must be a Jolt::Shape" unless shape.is_a?(Shape)

        position = Conversions.native_vec3(position || [0, 0, 0], name: "child position")
        rotation = Conversions.native_quat(rotation || [0, 0, 0, 1], name: "child rotation")
        Native.JPH_CompoundShapeSettings_AddShape2(
          settings, position.pointer, rotation.pointer, shape.native_pointer, index
        )
      end
      build(Native.JPH_StaticCompoundShape_Create(settings), :compound)
    ensure
      Native.JPH_ShapeSettings_Destroy(settings) if settings && !settings.null?
    end

    def scaled(shape, scale)
      validate_shape(shape)
      scale = Conversions.native_vec3(scale, name: "scale")
      build(Native.JPH_ScaledShape_Create(shape.native_pointer, scale.pointer), :scaled)
    end

    def offset(shape, position: [0, 0, 0], rotation: [0, 0, 0, 1])
      validate_shape(shape)
      position = Conversions.native_vec3(position, name: "position")
      rotation = Conversions.native_quat(rotation)
      pointer = Native.JPH_RotatedTranslatedShape_Create(
        position.pointer, rotation.pointer, shape.native_pointer
      )
      build(pointer, :offset)
    end

    private

    def create_from_settings(settings, kind, function)
      raise ShapeError, "failed to create #{kind} settings" if settings.null?

      build(Native.public_send(function, settings), kind)
    ensure
      Native.JPH_ShapeSettings_Destroy(settings) if settings && !settings.null?
    end

    def packed_floats(value, tuple_size, name)
      if value.is_a?(String) && !(value.bytesize % FFI.type_size(:float)).zero?
        raise InvalidArgumentError, "#{name} packed f32 buffer has trailing bytes"
      end
      values = value.is_a?(String) ? value.unpack("e*") : value.to_a.flatten
      unless (values.length % tuple_size).zero?
        raise InvalidArgumentError, "#{name} has an incomplete tuple"
      end

      values.map.with_index { |item, index| Conversions.finite_float(item, "#{name}[#{index}]") }
    rescue NoMethodError
      raise InvalidArgumentError, "#{name} must be an array or packed f32 String"
    end

    def packed_indices(value)
      if value.is_a?(String) && !(value.bytesize % FFI.type_size(:uint32)).zero?
        raise InvalidArgumentError, "indices packed u32 buffer has trailing bytes"
      end
      values = value.is_a?(String) ? value.unpack("V*") : value.to_a.flatten
      raise InvalidArgumentError, "indices has an incomplete triangle" unless (values.length % 3).zero?
      unless values.all? { |index| index.is_a?(Integer) && index >= 0 }
        raise InvalidArgumentError, "indices must contain non-negative integers"
      end

      values
    rescue NoMethodError
      raise InvalidArgumentError, "indices must be an array or packed u32 String"
    end

    def float_memory(values)
      FFI::MemoryPointer.new(:float, values.length).tap { |memory| memory.write_array_of_float(values) }
    end

    def indexed_triangle_memory(indices)
      count = indices.length / 3
      FFI::MemoryPointer.new(Native::IndexedTriangle, count).tap do |memory|
        indices.each_slice(3).with_index do |(i1, i2, i3), index|
          triangle = Native::IndexedTriangle.new(memory + index * Native::IndexedTriangle.size)
          triangle[:i1], triangle[:i2], triangle[:i3] = i1, i2, i3
          triangle[:material_index] = 0
          triangle[:user_data] = 0
        end
      end
    end

    def validate_shape(shape)
      raise InvalidArgumentError, "shape must be a Jolt::Shape" unless shape.is_a?(Shape)

      shape.native_pointer
      Jolt.init
    end
  end
end
