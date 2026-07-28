# frozen_string_literal: true

require "jolt"
require "stagecraft"

begin
  system = Jolt::System.new
  ball = system.bodies.create(
    shape: Jolt::Shape.sphere(0.5),
    position: [0, 5, 0]
  )

  # `mesh_node` and `app` are supplied by the surrounding stagecraft scene.
  binding = Stagecraft::PhysicsBinding.new
  binding.bind(mesh_node, ball)
  stepper = Jolt::FixedStepper.new(hz: 60)

  app.run do |delta_time|
    alpha = stepper.advance(delta_time) { |step| system.update(step) }
    binding.sync!(alpha)
  end
ensure
  system&.destroy
  Jolt.shutdown
end
