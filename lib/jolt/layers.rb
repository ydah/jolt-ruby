# frozen_string_literal: true

require "set"

module Jolt
  class Layers
    class << self
      def default
        @default ||= define do |layers|
          layers.broad_phase :static_bp, :dynamic_bp
          layers.object :non_moving, broad_phase: :static_bp
          layers.object :moving, broad_phase: :dynamic_bp
          layers.collide :non_moving, with: :moving
          layers.collide :moving, with: :moving
        end
      end

      def define
        builder = Builder.new
        yield builder
        builder.build
      end
    end

    attr_reader :object_layers, :broad_phase_layers

    def initialize(object_layers:, broad_phase_layers:, mappings:, collisions:)
      @object_layers = object_layers.freeze
      @broad_phase_layers = broad_phase_layers.freeze
      @mappings = mappings.freeze
      @collisions = collisions.freeze
      freeze
    end

    def object_layer_id(name)
      @object_layers.fetch(name.to_sym)
    rescue KeyError
      raise InvalidArgumentError, "unknown object layer: #{name.inspect}"
    end

    def native_resources
      NativeResources.new(self, @mappings, @collisions)
    end

    class Builder
      def initialize
        @broad_phase_layers = {}
        @object_layers = {}
        @mappings = {}
        @collisions = Set.new
      end

      def broad_phase(*names)
        names.each { |name| add_named_layer(@broad_phase_layers, name, 256, "broad-phase") }
      end

      def object(*names, broad_phase:)
        broad_name = normalize_name(broad_phase)
        names.each do |name|
          object_name = add_named_layer(@object_layers, name, nil, "object")
          @mappings[object_name] = broad_name
        end
      end

      def collide(layer, with:)
        first = normalize_name(layer)
        Array(with).each do |other|
          second = normalize_name(other)
          @collisions << [first, second].sort.freeze
        end
      end

      def build
        raise InvalidArgumentError, "at least one broad-phase layer is required" if @broad_phase_layers.empty?
        raise InvalidArgumentError, "at least one object layer is required" if @object_layers.empty?

        missing_mappings = @mappings.values.reject { |name| @broad_phase_layers.key?(name) }.uniq
        unless missing_mappings.empty?
          raise InvalidArgumentError, "unknown broad-phase layer(s): #{missing_mappings.join(", ")}"
        end

        collision_names = @collisions.to_a.flatten.uniq
        missing_collisions = collision_names.reject { |name| @object_layers.key?(name) }
        unless missing_collisions.empty?
          raise InvalidArgumentError, "unknown collision layer(s): #{missing_collisions.join(", ")}"
        end

        Layers.new(
          object_layers: @object_layers.dup,
          broad_phase_layers: @broad_phase_layers.dup,
          mappings: @mappings.dup,
          collisions: @collisions.to_a
        )
      end

      private

      def add_named_layer(collection, name, limit, kind)
        normalized = normalize_name(name)
        raise InvalidArgumentError, "duplicate #{kind} layer: #{normalized}" if collection.key?(normalized)
        raise InvalidArgumentError, "too many #{kind} layers" if limit && collection.length >= limit

        collection[normalized] = collection.length
        normalized
      end

      def normalize_name(name)
        normalized = name.to_sym
        raise InvalidArgumentError, "layer name must not be empty" if normalized.to_s.empty?

        normalized
      rescue NoMethodError
        raise InvalidArgumentError, "layer name must be convertible to a symbol"
      end
    end

    class NativeResources
      attr_reader :broad_phase_interface, :object_pair_filter, :object_vs_broad_phase_filter

      def initialize(layers, mappings, collisions)
        @destroyed = false
        create_filters(layers, mappings, collisions)
      rescue StandardError
        destroy
        raise
      end

      def destroy
        return if @destroyed

        Native.JPH_ObjectVsBroadPhaseLayerFilter_Destroy(@object_vs_broad_phase_filter) if present?(@object_vs_broad_phase_filter)
        Native.JPH_ObjectLayerPairFilter_Destroy(@object_pair_filter) if present?(@object_pair_filter)
        Native.JPH_BroadPhaseLayerInterface_Destroy(@broad_phase_interface) if present?(@broad_phase_interface)
        @destroyed = true
      end

      def transfer_to_system!
        @destroyed = true
      end

      private

      def create_filters(layers, mappings, collisions)
        object_count = layers.object_layers.length
        broad_count = layers.broad_phase_layers.length
        @broad_phase_interface = Native.JPH_BroadPhaseLayerInterfaceTable_Create(object_count, broad_count)
        check_pointer!(@broad_phase_interface, "broad-phase layer interface")

        mappings.each do |object_name, broad_name|
          Native.JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(
            @broad_phase_interface,
            layers.object_layers.fetch(object_name),
            layers.broad_phase_layers.fetch(broad_name)
          )
        end

        @object_pair_filter = Native.JPH_ObjectLayerPairFilterTable_Create(object_count)
        check_pointer!(@object_pair_filter, "object layer pair filter")
        collisions.each do |first, second|
          Native.JPH_ObjectLayerPairFilterTable_EnableCollision(
            @object_pair_filter,
            layers.object_layers.fetch(first),
            layers.object_layers.fetch(second)
          )
        end

        @object_vs_broad_phase_filter = Native.JPH_ObjectVsBroadPhaseLayerFilterTable_Create(
          @broad_phase_interface, broad_count, @object_pair_filter, object_count
        )
        check_pointer!(@object_vs_broad_phase_filter, "object-vs-broad-phase filter")
      end

      def check_pointer!(pointer, description)
        raise InitializationError, "failed to create #{description}" unless present?(pointer)
      end

      def present?(pointer)
        pointer && !pointer.null?
      end
    end
  end
end
