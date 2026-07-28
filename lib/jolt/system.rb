# frozen_string_literal: true

module Jolt
  class System
    include SystemContacts
    include SystemQueries
    include SystemConstraints

    DEFAULT_LIMITS = {
      max_bodies: 10_240,
      max_body_pairs: 65_536,
      max_contact_constraints: 10_240
    }.freeze

    attr_reader :layers, :bodies, :constraints, :contact_events

    def initialize(max_bodies: DEFAULT_LIMITS[:max_bodies],
                   max_body_pairs: DEFAULT_LIMITS[:max_body_pairs],
                   max_contact_constraints: DEFAULT_LIMITS[:max_contact_constraints],
                   gravity: [0, -9.81, 0], layers: Layers.default,
                   contact_queue_capacity: 65_536)
      Jolt.init
      @destroyed = false
      @updating = false
      @body_registry = {}
      @constraint_registry = []
      @user_data = {}
      @shapes = {}
      @layers = validate_layers(layers)
      create_native_system(
        max_bodies, max_body_pairs, max_contact_constraints, contact_queue_capacity
      )
      self.gravity = gravity
      @bodies = BodyCollection.new(self)
      @constraints = ConstraintCollection.new(self)
      Jolt.__register_system(self)
    rescue StandardError
      destroy_native_resources
      raise
    end

    def update(delta_time, collision_steps: 1)
      __check_alive!
      delta_time = Conversions.positive_float(delta_time, "delta_time")
      unless collision_steps.is_a?(Integer) && collision_steps.positive?
        raise InvalidArgumentError, "collision_steps must be a positive integer"
      end
      raise Error, "recursive System#update is not allowed" if @updating

      @updating = true
      @body_registry.each_value(&:__capture_before_step)
      error = Native.JPH_PhysicsSystem_Update(@pointer, delta_time, collision_steps, @job_system)
      @body_registry.each_value(&:__capture_after_step)
      __drain_contact_events
      raise_update_error!(error) unless error.zero?
      self
    ensure
      @updating = false
    end

    def gravity
      __check_alive!
      native = Native::Vec3.new
      Native.JPH_PhysicsSystem_GetGravity(@pointer, native.pointer)
      Conversions.vec3(native)
    end

    def gravity=(value)
      __check_alive!
      native = Conversions.native_vec3(value, name: "gravity")
      Native.JPH_PhysicsSystem_SetGravity(@pointer, native.pointer)
      value
    end

    def optimize_broad_phase
      __check_alive!
      Native.JPH_PhysicsSystem_OptimizeBroadPhase(@pointer)
      self
    end

    def destroy
      return if @destroyed

      __destroy_all_constraints
      @body_registry.each_value(&:__mark_destroyed)
      @body_registry.clear
      @user_data.clear
      destroy_native_resources
      @shapes.each_value { |shape| shape.release unless shape.released? }
      @shapes.clear
      @destroyed = true
      Jolt.__unregister_system(self)
      nil
    end

    def destroyed?
      @destroyed
    end

    def __body_interface
      __check_alive!
      @body_interface
    end

    def __register_body(body, shape)
      @body_registry[body.id] = body
      @shapes[shape.object_id] = shape
    end

    def __destroy_body(body)
      return if body.destroyed?

      __check_alive!
      registered = @body_registry.delete(body.id)
      raise InvalidArgumentError, "body does not belong to this system" unless registered.equal?(body)

      __destroy_constraints_for(body)
      Native.JPH_BodyInterface_RemoveAndDestroyBody(@body_interface, body.id)
      @user_data.delete(body.id)
      body.__mark_destroyed
      nil
    end

    def __body(id)
      @body_registry[id]
    end

    def __native_pointer
      __check_alive!
      @pointer
    end

    def __bodies_snapshot
      @body_registry.values
    end

    def __user_data(id)
      @user_data[id]
    end

    def __set_user_data(id, value)
      @user_data[id] = value
    end

    def __check_alive!
      raise UseAfterDestroyError, "system has been destroyed" if @destroyed
    end

    private

    def validate_layers(layers)
      raise InvalidArgumentError, "layers must be a Jolt::Layers" unless layers.is_a?(Layers)

      layers
    end

    def create_native_system(max_bodies, max_body_pairs, max_contact_constraints, contact_queue_capacity)
      limits = [max_bodies, max_body_pairs, max_contact_constraints]
      unless limits.all? { |value| value.is_a?(Integer) && value.positive? }
        raise InvalidArgumentError, "system limits must be positive integers"
      end

      @layer_resources = @layers.native_resources
      @job_system = Native.JPH_JobSystemThreadPool_Create(nil)
      raise InitializationError, "failed to create Jolt job system" if @job_system.null?

      settings = Native::PhysicsSystemSettings.new
      settings[:max_bodies], settings[:max_body_pairs], settings[:max_contact_constraints] = limits
      settings[:num_body_mutexes] = 0
      settings[:padding] = 0
      settings[:broad_phase_layer_interface] = @layer_resources.broad_phase_interface
      settings[:object_layer_pair_filter] = @layer_resources.object_pair_filter
      settings[:object_vs_broad_phase_layer_filter] = @layer_resources.object_vs_broad_phase_filter
      @pointer = Native.JPH_PhysicsSystem_Create(settings.pointer)
      raise InitializationError, "failed to create Jolt physics system" if @pointer.null?

      @layer_resources.transfer_to_system!
      @body_interface = Native.JPH_PhysicsSystem_GetBodyInterface(@pointer)
      raise InitializationError, "failed to get Jolt body interface" if @body_interface.null?

      @narrow_phase_query = Native.JPH_PhysicsSystem_GetNarrowPhaseQuery(@pointer)
      raise InitializationError, "failed to get Jolt narrow-phase query" if @narrow_phase_query.null?

      __create_contact_queue(contact_queue_capacity)
    end

    def destroy_native_resources
      __destroy_contact_queue
      Native.JPH_PhysicsSystem_Destroy(@pointer) if @pointer && !@pointer.null?
      Native.JPH_JobSystem_Destroy(@job_system) if @job_system && !@job_system.null?
      @layer_resources&.destroy
      @pointer = nil
      @job_system = nil
      @body_interface = nil
      @narrow_phase_query = nil
      @layer_resources = nil
    end

    def raise_update_error!(error)
      names = []
      names << "manifold cache full" unless (error & 1).zero?
      names << "body pair cache full" unless (error & 2).zero?
      names << "contact constraints full" unless (error & 4).zero?
      raise PhysicsUpdateError, "physics update failed: #{names.join(", ")}"
    end
  end
end
