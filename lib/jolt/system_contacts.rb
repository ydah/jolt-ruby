# frozen_string_literal: true

module Jolt
  module SystemContacts
    CONTACT_EVENT_TYPES = %i[added persisted removed].freeze

    def __create_contact_queue(capacity)
      unless capacity.is_a?(Integer) && capacity >= 2
        raise InvalidArgumentError, "contact_queue_capacity must be an integer greater than 1"
      end

      @contact_queue = Native.JR_ContactQueue_Create(capacity)
      raise InitializationError, "failed to create contact event queue" if @contact_queue.null?

      listener = Native.JR_ContactQueue_GetListener(@contact_queue)
      raise InitializationError, "failed to create contact listener" if listener.null?

      Native.JPH_PhysicsSystem_SetContactListener(@pointer, listener)
      @contact_events = ContactEvents.empty
    end

    def __drain_contact_events
      grouped = {added: [], persisted: [], removed: []}
      native = Native::ContactEvent.new
      while Native.JR_ContactQueue_Pop(@contact_queue, native.pointer)
        type = CONTACT_EVENT_TYPES.fetch(native[:type])
        removed = type == :removed
        grouped.fetch(type) << Contact.new(
          body_a: @body_registry[native[:body_a]],
          body_b: @body_registry[native[:body_b]],
          sub_shape_a: native[:sub_shape_a],
          sub_shape_b: native[:sub_shape_b],
          point: removed ? nil : Larb::Vec3.new(*native[:point].to_a),
          normal: removed ? nil : Larb::Vec3.new(*native[:normal].to_a),
          penetration: removed ? nil : native[:penetration]
        )
      end
      dropped = Native.JR_ContactQueue_GetDroppedCount(@contact_queue)
      @contact_events = ContactEvents.new(
        added: grouped[:added].freeze,
        persisted: grouped[:persisted].freeze,
        removed: grouped[:removed].freeze,
        dropped_count: dropped
      )
    end

    def __destroy_contact_queue
      return unless @contact_queue && !@contact_queue.null?

      Native.JPH_PhysicsSystem_SetContactListener(@pointer, nil) if @pointer && !@pointer.null?
      Native.JR_ContactQueue_Destroy(@contact_queue)
      @contact_queue = nil
    end
  end
end
