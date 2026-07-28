#include "helper.h"

#include <joltc.h>

#include <cmath>

JPH_CharacterVirtual* JR_CharacterVirtual_Create(
    JPH_PhysicsSystem* system,
    const JPH_Shape* shape,
    const float* position,
    const float* rotation,
    float max_slope_angle,
    float mass) {
  if (!system || !shape || !position || !rotation) return nullptr;

  JPH_CharacterVirtualSettings settings{};
  JPH_CharacterVirtualSettings_Init(&settings);
  settings.base.shape = shape;
  settings.base.maxSlopeAngle = max_slope_angle;
  settings.mass = mass;

  const JPH_RVec3 native_position{position[0], position[1], position[2]};
  const JPH_Quat native_rotation{
      rotation[0], rotation[1], rotation[2], rotation[3]};
  return JPH_CharacterVirtual_Create(
      &settings, &native_position, &native_rotation, 0, system);
}

void JR_CharacterVirtual_ExtendedUpdate(
    JPH_CharacterVirtual* character,
    float delta_time,
    uint32_t layer,
    JPH_PhysicsSystem* system) {
  JPH_ExtendedUpdateSettings settings{};
  settings.stickToFloorStepDown = JPH_Vec3{0.0f, -0.5f, 0.0f};
  settings.walkStairsStepUp = JPH_Vec3{0.0f, 0.4f, 0.0f};
  settings.walkStairsMinStepForward = 0.02f;
  settings.walkStairsStepForwardTest = 0.15f;
  settings.walkStairsCosAngleForwardContact =
      std::cos(75.0f * JPH_M_PI / 180.0f);
  settings.walkStairsStepDownExtra = JPH_Vec3{0.0f, 0.0f, 0.0f};
  JPH_CharacterVirtual_ExtendedUpdate(
      character, delta_time, &settings, layer, system, nullptr, nullptr);
}
