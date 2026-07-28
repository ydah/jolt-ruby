# frozen_string_literal: true

require "fileutils"
require "mkmf"
require "rbconfig"

source_dir = __dir__
platform = "#{RbConfig::CONFIG.fetch("host_cpu")}-#{RbConfig::CONFIG.fetch("host_os")}"
build_dir = File.join(source_dir, "build", platform)
artifact_dir = File.join(source_dir, "native-artifacts")
host_os = RbConfig::CONFIG.fetch("host_os")
library_names =
  case host_os
  when /darwin/
    %w[libjoltc.dylib libjolt_ruby_helper.dylib]
  when /mswin|mingw/
    %w[joltc.dll jolt_ruby_helper.dll]
  else
    %w[libjoltc.so libjolt_ruby_helper.so]
  end

configure = [
  "cmake",
  "-S", source_dir,
  "-B", build_dir,
  "-DCMAKE_BUILD_TYPE=Release"
]
configure << "-DCMAKE_OSX_ARCHITECTURES=#{RbConfig::CONFIG.fetch("host_cpu")}" if host_os.include?("darwin")

abort "CMake configuration failed" unless system(*configure)
abort "native build failed" unless system(
  "cmake", "--build", build_dir, "--config", "Release", "--parallel"
)

search_directories = [
  File.join(build_dir, "lib"),
  File.join(build_dir, "lib", "Release"),
  File.join(build_dir, "Release")
]
FileUtils.rm_rf(artifact_dir)
FileUtils.mkdir_p(artifact_dir)
library_names.each do |name|
  source = search_directories.lazy
    .map { |directory| File.join(directory, name) }
    .find { |path| File.file?(path) }
  abort "native build did not produce #{name}" unless source

  FileUtils.cp(source, artifact_dir)
end

$srcs = []
$INSTALLFILES = library_names.map do |name|
  ["./native-artifacts/#{name}", "$(RUBYARCHDIR)/jolt/native/#{platform}", "native-artifacts"]
end
create_makefile("jolt_ruby_native")
