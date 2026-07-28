# frozen_string_literal: true

require "ffi"
require "rbconfig"
require_relative "native/platform"
require_relative "native/types"
require_relative "native/core_functions"
require_relative "native/query_functions"
require_relative "native/constraint_functions"
require_relative "native/character_functions"

module Jolt
  module Native
    extend FFI::Library

    class << self
      def load!
        return self if @loaded

        ffi_lib(*Loader.library_paths)
        Generated.attach(self)
        [
          CoreFunctions,
          QueryFunctions,
          ConstraintFunctions,
          CharacterFunctions
        ].each { |functions| functions.attach(self) }
        @loaded = true
        self
      rescue LoadError => error
        raise NativeLoadError, error.message
      end

      def loaded?
        @loaded == true
      end

    end

    module Loader
      module_function

      def library_paths
        directory = candidate_directories.find { |path| libraries_exist?(path) }
        return library_names unless directory

        library_names.map { |name| File.join(directory, name) }
      end

      def candidate_directories
        [
          ENV["JOLT_RUBY_NATIVE_DIR"],
          File.join(__dir__, "native", platform),
          installed_extension_directory,
          File.join(project_root, "tmp", "native", platform, "lib"),
          File.join(project_root, "tmp", "native", platform, "lib", "Release"),
          File.join(project_root, "tmp", "native", platform, "Release")
        ].compact
      end

      def installed_extension_directory
        return unless defined?(Gem)

        specification = Gem.loaded_specs["jolt-ruby"]
        return unless specification

        File.join(specification.extension_dir, "jolt", "native", platform)
      end

      def platform
        Platform.tag
      end

      def project_root
        File.expand_path("../..", __dir__)
      end

      def library_names
        case RbConfig::CONFIG.fetch("host_os")
        when /darwin/
          %w[libjoltc.dylib libjolt_ruby_helper.dylib]
        when /mswin|mingw/
          %w[joltc.dll jolt_ruby_helper.dll]
        else
          %w[libjoltc.so libjolt_ruby_helper.so]
        end
      end

      def libraries_exist?(directory)
        library_names.all? { |name| File.file?(File.join(directory, name)) }
      end
    end
  end
end
