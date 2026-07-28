#include "helper.h"

#include <joltc.h>

namespace {

JPH_Vec3 to_vec3(const float* value) {
  return JPH_Vec3{value[0], value[1], value[2]};
}

JPH_Body* find_body(JPH_PhysicsSystem* system, uint32_t body_id) {
  return const_cast<JPH_Body*>(JPH_PhysicsSystem_GetBodyPtr(system, body_id));
}

JPH_Constraint* add_constraint(JPH_PhysicsSystem* system, JPH_Constraint* constraint) {
  if (!constraint) return nullptr;

  JPH_PhysicsSystem_AddConstraint(system, constraint);
  return constraint;
}

}  // namespace

JPH_Constraint* JR_Constraint_CreateFixed(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor) {
  auto* first = find_body(system, body_a);
  auto* second = find_body(system, body_b);
  if (!first || !second) return nullptr;

  JPH_FixedConstraintSettings settings{};
  JPH_FixedConstraintSettings_Init(&settings);
  settings.space = JPH_ConstraintSpace_WorldSpace;
  if (anchor) {
    settings.autoDetectPoint = false;
    settings.point1 = to_vec3(anchor);
    settings.point2 = settings.point1;
  }
  return add_constraint(
      system,
      reinterpret_cast<JPH_Constraint*>(
          JPH_FixedConstraint_Create(&settings, first, second)));
}

JPH_Constraint* JR_Constraint_CreatePoint(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor) {
  auto* first = find_body(system, body_a);
  auto* second = find_body(system, body_b);
  if (!first || !second || !anchor) return nullptr;

  JPH_PointConstraintSettings settings{};
  JPH_PointConstraintSettings_Init(&settings);
  settings.space = JPH_ConstraintSpace_WorldSpace;
  settings.point1 = to_vec3(anchor);
  settings.point2 = settings.point1;
  return add_constraint(
      system,
      reinterpret_cast<JPH_Constraint*>(
          JPH_PointConstraint_Create(&settings, first, second)));
}

JPH_Constraint* JR_Constraint_CreateDistance(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* point_a,
    const float* point_b,
    float min_distance,
    float max_distance) {
  auto* first = find_body(system, body_a);
  auto* second = find_body(system, body_b);
  if (!first || !second || !point_a || !point_b) return nullptr;

  JPH_DistanceConstraintSettings settings{};
  JPH_DistanceConstraintSettings_Init(&settings);
  settings.space = JPH_ConstraintSpace_WorldSpace;
  settings.point1 = to_vec3(point_a);
  settings.point2 = to_vec3(point_b);
  settings.minDistance = min_distance;
  settings.maxDistance = max_distance;
  return add_constraint(
      system,
      reinterpret_cast<JPH_Constraint*>(
          JPH_DistanceConstraint_Create(&settings, first, second)));
}

JPH_Constraint* JR_Constraint_CreateHinge(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor,
    const float* axis,
    const float* normal,
    bool has_limits,
    float min_angle,
    float max_angle) {
  auto* first = find_body(system, body_a);
  auto* second = find_body(system, body_b);
  if (!first || !second || !anchor || !axis || !normal) return nullptr;

  JPH_HingeConstraintSettings settings{};
  JPH_HingeConstraintSettings_Init(&settings);
  settings.space = JPH_ConstraintSpace_WorldSpace;
  settings.point1 = to_vec3(anchor);
  settings.point2 = settings.point1;
  settings.hingeAxis1 = to_vec3(axis);
  settings.hingeAxis2 = settings.hingeAxis1;
  settings.normalAxis1 = to_vec3(normal);
  settings.normalAxis2 = settings.normalAxis1;
  if (has_limits) {
    settings.limitsMin = min_angle;
    settings.limitsMax = max_angle;
  }
  return add_constraint(
      system,
      reinterpret_cast<JPH_Constraint*>(
          JPH_HingeConstraint_Create(&settings, first, second)));
}

JPH_Constraint* JR_Constraint_CreateSlider(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor,
    const float* axis,
    bool has_limits,
    float min_distance,
    float max_distance) {
  auto* first = find_body(system, body_a);
  auto* second = find_body(system, body_b);
  if (!first || !second || !anchor || !axis) return nullptr;

  JPH_SliderConstraintSettings settings{};
  JPH_SliderConstraintSettings_Init(&settings);
  settings.space = JPH_ConstraintSpace_WorldSpace;
  settings.autoDetectPoint = false;
  settings.point1 = to_vec3(anchor);
  settings.point2 = settings.point1;
  const JPH_Vec3 slider_axis = to_vec3(axis);
  JPH_SliderConstraintSettings_SetSliderAxis(&settings, &slider_axis);
  if (has_limits) {
    settings.limitsMin = min_distance;
    settings.limitsMax = max_distance;
  }
  return add_constraint(
      system,
      reinterpret_cast<JPH_Constraint*>(
          JPH_SliderConstraint_Create(&settings, first, second)));
}
