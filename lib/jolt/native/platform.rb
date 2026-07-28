# frozen_string_literal: true

require "rbconfig"

module Jolt
  module Native
    module Platform
      module_function

      def tag(cpu: RbConfig::CONFIG.fetch("host_cpu"), os: RbConfig::CONFIG.fetch("host_os"))
        case os
        when /darwin/
          "#{darwin_cpu(cpu)}-darwin"
        when /linux/
          "#{linux_cpu(cpu)}-linux"
        when /mswin|mingw/
          "#{windows_cpu(cpu)}-mingw-ucrt"
        else
          "#{cpu}-#{os}".downcase.gsub(/[^a-z0-9._-]+/, "-")
        end
      end

      def darwin_cpu(cpu)
        case cpu
        when "arm64", "aarch64" then "arm64"
        when "x86_64", "amd64" then "x86_64"
        else cpu
        end
      end
      private_class_method :darwin_cpu

      def linux_cpu(cpu)
        case cpu
        when "arm64", "aarch64" then "aarch64"
        when "x64", "amd64", "x86_64" then "x86_64"
        else cpu
        end
      end
      private_class_method :linux_cpu

      def windows_cpu(cpu)
        case cpu
        when "x64", "amd64", "x86_64" then "x64"
        when "arm64", "aarch64" then "arm64"
        else cpu
        end
      end
      private_class_method :windows_cpu
    end
  end
end
