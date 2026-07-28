# frozen_string_literal: true

module Jolt
  module Native
    module QueryFunctions
      module_function

      def attach(native)
        install_object_layer_filter(native)
      end

      def object_layer_filter(native, layer_ids, layer_count)
        context = FFI::MemoryPointer.new(:uint8, layer_count + 4, true)
        context.write_uint32(layer_count)
        layer_ids.each { |id| context.put_uint8(id + 4, 1) }
        filter = native.JPH_ObjectLayerFilter_Create(context)
        raise InitializationError, "failed to create object layer filter" if filter.null?

        [filter, context]
      end

      def install_object_layer_filter(native)
        @object_layer_callback ||= FFI::Function.new(:bool, %i[pointer uint32]) do |context, layer|
          count = context.read_uint32
          layer < count && context.get_uint8(layer + 4) == 1
        end
        @object_layer_procs ||= ObjectLayerFilterProcs.new.tap do |procs|
          procs[:should_collide] = @object_layer_callback
        end
        native.JPH_ObjectLayerFilter_SetProcs(@object_layer_procs.pointer)
      end

      def body_collector
        hits = []
        callback = FFI::Function.new(:float, %i[pointer uint32]) do |_context, body_id|
          hits << body_id
          1.0
        end
        [callback, hits]
      end
    end
  end
end
