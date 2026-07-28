# frozen_string_literal: true

require "rubygems"
require_relative "lib/jolt/native/platform"
require_relative "lib/jolt/version"

Gem::Specification.new do |spec|
  spec.name = "jolt-ruby"
  spec.version = Jolt::VERSION
  spec.authors = ["Yudai Takada"]
  spec.email = ["t.yudai92@gmail.com"]

  spec.summary = "Ruby bindings for the Jolt Physics engine"
  spec.description = "A Ruby-friendly 3D physics API backed by Jolt Physics through joltc and FFI."
  spec.homepage = "https://github.com/ydah/jolt-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  platform_gem = ENV["JOLT_RUBY_PLATFORM_GEM"] == "1"
  spec.files = IO.popen(%w[git ls-files --recurse-submodules -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  if platform_gem
    native_platform = Jolt::Native::Platform.tag
    spec.platform = Gem::Platform.new(native_platform)
    spec.files.reject! { |file| file.start_with?("ext/", "generator/") }
    spec.files.concat Dir[File.join(__dir__, "lib", "jolt", "native", native_platform, "*")]
      .select { |file| File.file?(file) }
      .map { |file| file.delete_prefix("#{__dir__}/") }
  else
    spec.extensions = ["ext/jolt_ruby/extconf.rb"]
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.17"
  spec.add_dependency "larb", "~> 1.0"

  spec.add_development_dependency "ffi-clang", "~> 0.16"
end
