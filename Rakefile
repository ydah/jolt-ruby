# frozen_string_literal: true

require "bundler/gem_tasks"
require "fileutils"
require "open3"
require "rspec/core/rake_task"
require "rbconfig"
require "shellwords"
require_relative "lib/jolt/native/platform"
require_relative "lib/jolt/version"

RSpec::Core::RakeTask.new(:spec)

module NativeBuild
  extend Rake::FileUtilsExt
  module_function

  ROOT = __dir__
  PLATFORM = Jolt::Native::Platform.tag
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

  def library_directory
    [
      File.join(BUILD_DIR, "lib"),
      File.join(BUILD_DIR, "lib", "Release"),
      File.join(BUILD_DIR, "Release")
    ].find { |directory| library_names.all? { |name| File.file?(File.join(directory, name)) } } ||
      raise("native libraries were not found in #{BUILD_DIR}")
  end

  def stage
    destination = File.join(ROOT, "lib", "jolt", "native", PLATFORM)
    FileUtils.rm_rf(destination)
    FileUtils.mkdir_p(destination)
    library_names.each do |name|
      FileUtils.cp(File.join(library_directory, name), destination)
    end
  end

  def verify_layout
    directory = File.join(ROOT, "tmp", "layout")
    FileUtils.mkdir_p(directory)
    executable = File.join(directory, "layout_probe#{RbConfig::CONFIG.fetch("EXEEXT")}")
    compiler = Shellwords.split(ENV.fetch("CXX", RbConfig::CONFIG.fetch("CXX")))
    sh(
      *compiler,
      "-std=c++17",
      "-I#{File.join(ROOT, "ext", "joltc", "include")}",
      File.join(ROOT, "generator", "layout_probe.cpp"),
      "-o", executable
    )
    output, status = Open3.capture2e(executable)
    raise "layout probe failed:\n#{output}" unless status.success?

    output_path = File.join(directory, "layouts.tsv")
    File.binwrite(output_path, output)
    sh(
      RbConfig.ruby,
      File.join(ROOT, "generator", "verify_layout.rb"),
      output_path
    )
  end
end

module PackageSmoke
  extend Rake::FileUtilsExt
  module_function

  ROOT = __dir__

  def run(gem_path, label)
    raise "gem was not built: #{gem_path}" unless File.file?(gem_path)

    install_dir = File.join(ROOT, "tmp", "gem-smoke", label)
    FileUtils.rm_rf(install_dir)
    FileUtils.mkdir_p(install_dir)
    sh(
      "gem", "install", "--local", "--ignore-dependencies", "--no-document",
      "--install-dir", install_dir, gem_path
    )

    gem_path_entries = [install_dir, *Gem.path].uniq.join(File::PATH_SEPARATOR)
    environment = {
      "GEM_HOME" => install_dir,
      "GEM_PATH" => gem_path_entries,
      "JOLT_RUBY_SMOKE_HOME" => install_dir
    }
    Bundler.with_unbundled_env do
      sh(environment, RbConfig.ruby, File.join(ROOT, "script", "smoke_gem.rb"))
    end
  end
end

namespace :generator do
  desc "Regenerate FFI declarations and the native layout probe"
  task :generate do
    sh(RbConfig.ruby, File.join(__dir__, "generator", "generate.rb"))
  end

  desc "Fail if generated FFI declarations are stale"
  task :check do
    sh(RbConfig.ruby, File.join(__dir__, "generator", "generate.rb"), "--check")
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

  desc "Verify every generated FFI struct against the C compiler"
  task verify_layout: "generator:check" do
    NativeBuild.verify_layout
  end

  desc "Build a platform gem containing the native libraries"
  task gem: :compile do
    NativeBuild.stage
    sh({ "JOLT_RUBY_PLATFORM_GEM" => "1" }, "gem", "build", "jolt.gemspec")
  end

  desc "Build, install, and execute the current platform gem"
  task smoke_gem: :gem do
    platform = Gem::Platform.new(NativeBuild::PLATFORM)
    gem_path = File.join(__dir__, "jolt-ruby-#{Jolt::VERSION}-#{platform}.gem")
    PackageSmoke.run(gem_path, "platform")
  end
end

namespace :package do
  desc "Build the source gem"
  task :source_gem do
    sh("gem", "build", "jolt.gemspec")
  end

  desc "Build, install, compile, and execute the source gem fallback"
  task smoke_source: :source_gem do
    gem_path = File.join(__dir__, "jolt-ruby-#{Jolt::VERSION}.gem")
    PackageSmoke.run(gem_path, "source")
  end
end

desc "Build the native libraries"
task compile: "native:compile"

task spec: [:compile, "native:verify_layout"]
task default: :spec
