# frozen_string_literal: true

require_relative "generated"

module Jolt
  module Native
    Vec3 = Generated::Vec3
    Vec4 = Generated::Vec4
    Quat = Generated::Quat
    Mat4 = Generated::Mat4
    MassProperties = Generated::MassProperties
    PhysicsSystemSettings = Generated::PhysicsSystemSettings
    RayCastResult = Generated::RayCastResult
    IndexedTriangle = Generated::IndexedTriangle
    ObjectLayerFilterProcs = Generated::ObjectLayerFilter_Procs

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
  end
end
