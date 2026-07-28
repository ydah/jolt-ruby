# frozen_string_literal: true

module Jolt
  module Native
    class Vec3 < FFI::Struct
      layout :x, :float,
             :y, :float,
             :z, :float
    end

    class Vec4 < FFI::Struct
      layout :x, :float,
             :y, :float,
             :z, :float,
             :w, :float
    end

    class Quat < FFI::Struct
      layout :x, :float,
             :y, :float,
             :z, :float,
             :w, :float
    end

    class Mat4 < FFI::Struct
      layout :column, [Vec4.by_value, 4]
    end

    class MassProperties < FFI::Struct
      layout :mass, :float,
             :inertia, Mat4.by_value
    end

    class PhysicsSystemSettings < FFI::Struct
      layout :max_bodies, :uint32,
             :num_body_mutexes, :uint32,
             :max_body_pairs, :uint32,
             :max_contact_constraints, :uint32,
             :padding, :uint32,
             :broad_phase_layer_interface, :pointer,
             :object_layer_pair_filter, :pointer,
             :object_vs_broad_phase_layer_filter, :pointer
    end

    class ContactEvent < FFI::Struct
      layout :type, :uint32,
             :body_a, :uint32,
             :body_b, :uint32,
             :sub_shape_a, :uint32,
             :sub_shape_b, :uint32,
             :point, [:float, 3],
             :normal, [:float, 3],
             :penetration, :float
    end

    class RayCastResult < FFI::Struct
      layout :body_id, :uint32,
             :fraction, :float,
             :sub_shape_id, :uint32
    end

    class IndexedTriangle < FFI::Struct
      layout :i1, :uint32,
             :i2, :uint32,
             :i3, :uint32,
             :material_index, :uint32,
             :user_data, :uint32
    end

    class ObjectLayerFilterProcs < FFI::Struct
      layout :should_collide, :pointer
    end
  end
end
