# frozen_string_literal: true

require "rubygems"

gem "jolt-ruby"
require "jolt"

smoke_home = File.realpath(ENV.fetch("JOLT_RUBY_SMOKE_HOME"))
loaded_gem = File.realpath(Gem.loaded_specs.fetch("jolt-ruby").full_gem_path)
unless loaded_gem.start_with?("#{smoke_home}#{File::SEPARATOR}")
  raise "loaded jolt-ruby from #{loaded_gem}, expected an installation under #{smoke_home}"
end

begin
  system = Jolt::System.new
  body = system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [0, 2, 0])
  system.update(1.0 / 60.0)
  raise "packaged simulation did not advance" unless body.position.y < 2

  puts "loaded and simulated with #{File.basename(loaded_gem)}"
ensure
  system&.destroy
  Jolt.shutdown
end
