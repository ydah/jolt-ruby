# frozen_string_literal: true

require "spec_helper"

RSpec.describe "contact callback lifetime", :stress do
  it "survives one thousand updates while the Ruby GC is stressed" do
    system = Jolt::System.new
    system.bodies.create(
      shape: Jolt::Shape.box([5, 0.5, 5]),
      position: [0, -0.5, 0],
      motion: :static
    )
    system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [0, 2, 0])
    previous_stress = GC.stress
    GC.stress = true

    1_000.times { system.update(1.0 / 240.0) }

    expect(system.contact_events.dropped_count).to eq(0)
  ensure
    GC.stress = previous_stress
    system&.destroy
  end
end
