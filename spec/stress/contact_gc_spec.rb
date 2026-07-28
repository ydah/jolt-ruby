# frozen_string_literal: true

require "spec_helper"

RSpec.describe "contact callback lifetime", :stress do
  it "survives one thousand updates while the Ruby GC is stressed" do
    previous_stress = GC.stress
    system = Jolt::System.new
    system.bodies.create(
      shape: Jolt::Shape.box([5, 0.5, 5]),
      position: [0, -0.5, 0],
      motion: :static
    )
    sphere = Jolt::Shape.sphere(0.5)
    system.bodies.create(shape: sphere, position: [0, 2, 0])
    transient_bodies = []
    GC.stress = true

    1_000.times do |step|
      if (step % 100).zero?
        transient_bodies << system.bodies.create(
          shape: sphere,
          position: [(step / 100) * 0.2 - 0.9, 3, 0]
        )
      elsif (step % 100) == 50
        transient_bodies.shift.destroy
      end
      system.update(1.0 / 240.0)
    end

    expect(system.contact_events.dropped_count).to eq(0)
    expect(transient_bodies).to be_empty
  ensure
    GC.stress = previous_stress
    system&.destroy
  end
end
