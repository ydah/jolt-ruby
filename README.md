# jolt-ruby

Ruby bindings for [Jolt Physics](https://github.com/jrouwe/JoltPhysics), built on
the `joltc` C API, `ffi`, and `larb`.

> jolt-ruby uses SI units in a right-handed, Y-up coordinate system: metres,
> kilograms, seconds, and radians. Passing centimetres or degrees without
> conversion will produce incorrect simulation results.

## Installation

```ruby
gem "jolt-ruby"
```

```sh
bundle install
```

Release builds use platform gems for x86-64/aarch64 Linux, arm64/x86-64 macOS,
and x64-mingw-ucrt. On another platform RubyGems falls back to the source gem,
which requires CMake 3.16 or newer and a C++17 compiler.

The 1.x public API follows semantic versioning. Native declarations mirror the
vendored `joltc` header; higher-level Ruby APIs are added deliberately rather
than exposing unsafe ownership or callback behavior.

## First simulation

```ruby
require "jolt"

system = Jolt::System.new(gravity: [0, -9.81, 0])
floor = system.bodies.create(
  shape: Jolt::Shape.box([50, 0.5, 50]),
  position: [0, -0.5, 0],
  motion: :static,
  layer: :non_moving
)
ball = system.bodies.create(
  shape: Jolt::Shape.sphere(0.5),
  position: [0, 5, 0],
  mass: 2,
  restitution: 0.6,
  ccd: true
)

system.update(1.0 / 60)
puts ball.position

system.destroy
Jolt.shutdown
```

`Jolt.init` is called automatically. A `System` owns its bodies, constraints,
characters, and retained shapes. Destroying the system invalidates their Ruby
handles; subsequent access raises `Jolt::UseAfterDestroyError`. Explicit
`destroy`/`release` is supported, and shutdown is also registered with
`at_exit`.

## Layers

`Layers.default` provides `:non_moving` and `:moving`. Custom collision matrices
remain entirely native during simulation:

```ruby
layers = Jolt::Layers.define do |layer|
  layer.broad_phase :static_bp, :dynamic_bp
  layer.object :ground, broad_phase: :static_bp
  layer.object :player, :enemy, broad_phase: :dynamic_bp
  layer.collide :player, with: %i[ground enemy]
  layer.collide :enemy, with: %i[ground player enemy]
end

system = Jolt::System.new(layers:)
```

## Shapes and bodies

Primitive shapes:

```ruby
Jolt::Shape.box([1, 0.5, 1])
Jolt::Shape.sphere(0.5)
Jolt::Shape.capsule(half_height: 0.8, radius: 0.3)
Jolt::Shape.cylinder(half_height: 1, radius: 0.5)
```

The advanced builders are `convex_hull`, `mesh`, `heightfield`, `compound`,
`scaled`, and `offset`. Hull vertices and mesh vertices accept nested arrays or
packed little-endian f32 strings; mesh indices also accept packed u32 strings.
Mesh and heightfield shapes are static-only.

Bodies support `:static`, `:kinematic`, and `:dynamic` motion. Common operations
include:

```ruby
body.linear_velocity = [1, 0, 0]
body.angular_velocity = [0, 1, 0]
body.apply_impulse([0, 10, 0])
body.add_force([5, 0, 0], point: [0, 1, 0])
body.friction = 0.4
body.sensor = true
body.kinematic_move_to([2, 0, 0], [0, 0, 0, 1], 1.0 / 60)
```

Arbitrary Ruby objects can be stored in `body.user_data`. They never cross the
native boundary.

## Contacts and queries

Jolt invokes contact listeners from worker threads. jolt-ruby records those
calls into a bounded native lock-free queue, then creates immutable Ruby
snapshots after `System#update`:

```ruby
system.update(1.0 / 60)
system.contact_events.added.each do |contact|
  puts [contact.body_a, contact.body_b, contact.point, contact.normal].inspect
end

warn "contact queue overflow" if system.contact_events.dropped_count.positive?
```

Synchronous queries return registered `Jolt::Body` handles:

```ruby
hit = system.raycast(
  origin: [0, 10, 0],
  direction: [0, -20, 0],
  layer_mask: %i[non_moving moving]
)

nearby = system.overlap_sphere([0, 0, 0], 2, layer_mask: :moving)
system.overlap_point([0, 0, 0]) { |body| puts body.user_data }
```

Overlap queries use Jolt's broad phase and therefore report bodies whose bounds
overlap the query.

## Constraints

The collection supports fixed, point, distance, hinge, and slider constraints:

```ruby
hinge = system.constraints.hinge(
  body_a: door,
  body_b: frame,
  anchor: [0, 1, 0],
  axis: [0, 1, 0],
  limits: (-Math::PI / 2)..(Math::PI / 2)
)
hinge.motor_speed = 1.5
hinge.disable_motor
hinge.destroy
```

Destroying either body destroys its attached constraints first.

## Virtual characters

`CharacterVirtual#update` uses Jolt's extended update with stair walking and
stick-to-floor enabled:

```ruby
character = Jolt::CharacterVirtual.new(
  system,
  shape: Jolt::Shape.capsule(half_height: 0.8, radius: 0.3),
  position: [0, 2, 0],
  max_slope: Math::PI / 4,
  mass: 70
)

character.velocity = [3, character.velocity.y - 9.81 / 60, 0]
character.update(1.0 / 60)
puts character.ground_state # :on_ground, :sliding, or :in_air
```

## Fixed stepping and rendering

`System#update` releases Ruby's GVL while Jolt runs. Use `FixedStepper` to keep
simulation stable and interpolate rendering transforms:

```ruby
stepper = Jolt::FixedStepper.new(hz: 60, max_substeps: 5)

alpha = stepper.advance(frame_delta) { |step| system.update(step) }
render_transform = ball.interpolated(alpha)
```

Each system permits one native operation at a time. Do not read, mutate, or
destroy a system or one of its handles from another thread while
`System#update` or `CharacterVirtual#update` is running. Such access raises
`Jolt::ConcurrentAccessError`.

The returned transform exposes `position` and `rotation` as `Larb::Vec3` and
`Larb::Quat`, matching the stagecraft binding contract. See
[`examples/stagecraft_binding.rb`](examples/stagecraft_binding.rb).

## Development

Initialize the submodule and run the complete build:

```sh
git submodule update --init
bundle install
bundle exec rake
```

Useful tasks:

```sh
bundle exec rake native:compile       # build joltc and the helper library
bundle exec rake generator:generate   # regenerate all joltc FFI declarations
bundle exec rake native:verify_layout # compare Clang, C++, and FFI layouts
bundle exec rake native:gem           # build a precompiled platform gem
bundle exec rake native:smoke_gem     # install and run the platform gem
bundle exec rake package:smoke_source # compile, install, and run the source gem
JOLT_STRESS=1 bundle exec rspec spec/stress
```

The generator reads `joltc.h` through `ffi-clang`. CI rejects stale output and
compares all generated struct sizes and field offsets against a C++ probe.

## License

The gem is available under the [MIT License](LICENSE.txt). Jolt Physics and
`joltc` retain their respective upstream licenses.
