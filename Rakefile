# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rbconfig"

RSpec::Core::RakeTask.new(:spec)

module NativeBuild
  extend Rake::FileUtilsExt
  module_function

  ROOT = __dir__
  PLATFORM = "#{RbConfig::CONFIG.fetch("host_cpu")}-#{RbConfig::CONFIG.fetch("host_os")}"
  BUILD_DIR = File.join(ROOT, "tmp", "native", PLATFORM)

  def configure
    arch = RbConfig::CONFIG.fetch("host_cpu")
    command = [
      "cmake",
      "-S", File.join(ROOT, "ext", "jolt_ruby"),
      "-B", BUILD_DIR,
      "-DCMAKE_BUILD_TYPE=Release"
    ]
    command << "-DCMAKE_OSX_ARCHITECTURES=#{arch}" if RbConfig::CONFIG.fetch("host_os").include?("darwin")
    sh(*command)
  end

  def build
    sh("cmake", "--build", BUILD_DIR, "--config", "Release", "--parallel")
  end
end

namespace :native do
  desc "Configure the native joltc build"
  task :configure do
    NativeBuild.configure
  end

  desc "Build joltc and the jolt-ruby support library"
  task compile: :configure do
    NativeBuild.build
  end
end

desc "Build the native libraries"
task compile: "native:compile"

task spec: :compile
task default: :spec
