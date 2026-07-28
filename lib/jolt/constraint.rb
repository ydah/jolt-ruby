# frozen_string_literal: true

module Jolt
  class Constraint
    attr_reader :kind, :body_a, :body_b, :system

    def initialize(system, pointer, kind, body_a, body_b)
      @system = system
      @pointer = pointer
      @kind = kind
      @body_a = body_a
      @body_b = body_b
      @destroyed = false
    end

    def enabled?
      check_alive!
      Native.JPH_Constraint_GetEnabled(@pointer)
    end

    def enabled=(value)
      check_alive!
      Native.JPH_Constraint_SetEnabled(@pointer, !!value)
    end

    def limits
      check_alive!
      functions = limit_functions
      [
        Native.public_send(functions.fetch(:min), @pointer),
        Native.public_send(functions.fetch(:max), @pointer)
      ]
    end

    def limits=(value)
      check_alive!
      minimum, maximum = ConstraintCollection.interval(value, "limits")
      Native.public_send(limit_functions.fetch(:set), @pointer, minimum, maximum)
      value
    end

    def current_position
      check_alive!
      function = case @kind
                 when :hinge then :JPH_HingeConstraint_GetCurrentAngle
                 when :slider then :JPH_SliderConstraint_GetCurrentPosition
                 else
                   raise InvalidArgumentError, "#{@kind} constraints do not have a scalar position"
                 end
      Native.public_send(function, @pointer)
    end

    def motor_speed
      check_alive!
      Native.public_send(motor_functions.fetch(:get), @pointer)
    end

    def motor_speed=(value)
      check_alive!
      speed = Conversions.finite_float(value, "motor_speed")
      functions = motor_functions
      Native.public_send(functions.fetch(:state), @pointer, 1)
      Native.public_send(functions.fetch(:set), @pointer, speed)
      value
    end

    def disable_motor
      check_alive!
      Native.public_send(motor_functions.fetch(:state), @pointer, 0)
      self
    end

    def destroy
      @system.__destroy_constraint(self)
    end

    def destroyed?
      @destroyed
    end

    def __native_pointer
      check_alive!
      @pointer
    end

    def __involves?(body)
      @body_a.equal?(body) || @body_b.equal?(body)
    end

    def __mark_destroyed
      @destroyed = true
      @pointer = nil
    end

    private

    def limit_functions
      prefix = case @kind
               when :distance then "Distance"
               when :hinge then "Hinge"
               when :slider then "Slider"
               else
                 raise InvalidArgumentError, "#{@kind} constraints do not have limits"
               end
      {
        set: :"JPH_#{prefix}Constraint_Set#{prefix == "Distance" ? "Distance" : "Limits"}",
        min: :"JPH_#{prefix}Constraint_Get#{prefix == "Distance" ? "MinDistance" : "LimitsMin"}",
        max: :"JPH_#{prefix}Constraint_Get#{prefix == "Distance" ? "MaxDistance" : "LimitsMax"}"
      }
    end

    def motor_functions
      case @kind
      when :hinge
        {
          state: :JPH_HingeConstraint_SetMotorState,
          set: :JPH_HingeConstraint_SetTargetAngularVelocity,
          get: :JPH_HingeConstraint_GetTargetAngularVelocity
        }
      when :slider
        {
          state: :JPH_SliderConstraint_SetMotorState,
          set: :JPH_SliderConstraint_SetTargetVelocity,
          get: :JPH_SliderConstraint_GetTargetVelocity
        }
      else
        raise InvalidArgumentError, "#{@kind} constraints do not have a motor"
      end
    end

    def check_alive!
      raise UseAfterDestroyError, "#{@kind} constraint has been destroyed" if @destroyed
      raise UseAfterDestroyError, "system has been destroyed" if @system.destroyed?
    end
  end
end
