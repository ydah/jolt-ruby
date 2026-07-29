# frozen_string_literal: true

require "rubygems/package"

directory, tag = ARGV
abort "usage: #{$PROGRAM_NAME} GEM_DIRECTORY vVERSION" unless directory && tag
abort "release tag must have the form v1.2.3" unless tag.match?(/\Av\d+\.\d+\.\d+\z/)

version = tag.delete_prefix("v")
expected_platforms = %w[
  ruby
  x86_64-linux
  aarch64-linux
  arm64-darwin
  x86_64-darwin
  x64-mingw-ucrt
].sort
gem_paths = Dir[File.join(directory, "*.gem")].sort
specifications = gem_paths.map { |path| Gem::Package.new(path).spec }

unless specifications.length == expected_platforms.length
  abort "expected #{expected_platforms.length} gems, found #{specifications.length}"
end
unless specifications.all? { |specification| specification.name == "jolt-ruby" }
  abort "release directory contains a gem other than jolt-ruby"
end
unless specifications.all? { |specification| specification.version.to_s == version }
  abort "release gem version does not match tag #{tag}"
end

actual_platforms = specifications.map { |specification| specification.platform.to_s }.sort
unless actual_platforms == expected_platforms
  abort "expected platforms #{expected_platforms.join(", ")}, found #{actual_platforms.join(", ")}"
end

puts "verified jolt-ruby #{version} for #{actual_platforms.join(", ")}"
