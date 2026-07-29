# frozen_string_literal: true

require "jolt"
require "stagecraft"

def run_stagecraft_physics(app:, mesh_node:)
  begin
    system = Jolt::System.new
    ball = system.bodies.create(
      shape: Jolt::Shape.sphere(0.5),
      position: [0, 5, 0]
    )

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
end

# Call from a stagecraft scene with:
# run_stagecraft_physics(app:, mesh_node:)
