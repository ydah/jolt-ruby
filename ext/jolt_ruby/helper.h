#ifndef JOLT_RUBY_HELPER_H
#define JOLT_RUBY_HELPER_H

#include <stdbool.h>
#include <stdint.h>

#if defined(_WIN32)
#  define JR_EXPORT __declspec(dllexport)
#else
#  define JR_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct JPH_ContactListener JPH_ContactListener;
typedef struct JPH_Constraint JPH_Constraint;
typedef struct JPH_CharacterVirtual JPH_CharacterVirtual;
typedef struct JPH_PhysicsSystem JPH_PhysicsSystem;
typedef struct JPH_Shape JPH_Shape;

typedef enum JR_ContactEventType {
  JR_CONTACT_ADDED = 0,
  JR_CONTACT_PERSISTED = 1,
  JR_CONTACT_REMOVED = 2
} JR_ContactEventType;

typedef struct JR_ContactEvent {
  uint32_t type;
  uint32_t body_a;
  uint32_t body_b;
  uint32_t sub_shape_a;
  uint32_t sub_shape_b;
  float point[3];
  float normal[3];
  float penetration;
} JR_ContactEvent;

typedef struct JR_ContactQueue JR_ContactQueue;

JR_EXPORT JR_ContactQueue* JR_ContactQueue_Create(uint32_t capacity);
JR_EXPORT void JR_ContactQueue_Destroy(JR_ContactQueue* queue);
JR_EXPORT JPH_ContactListener* JR_ContactQueue_GetListener(JR_ContactQueue* queue);
JR_EXPORT bool JR_ContactQueue_Pop(JR_ContactQueue* queue, JR_ContactEvent* event);
JR_EXPORT uint64_t JR_ContactQueue_GetDroppedCount(const JR_ContactQueue* queue);

JR_EXPORT JPH_Constraint* JR_Constraint_CreateFixed(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor);
JR_EXPORT JPH_Constraint* JR_Constraint_CreatePoint(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor);
JR_EXPORT JPH_Constraint* JR_Constraint_CreateDistance(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* point_a,
    const float* point_b,
    float min_distance,
    float max_distance);
JR_EXPORT JPH_Constraint* JR_Constraint_CreateHinge(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor,
    const float* axis,
    const float* normal,
    bool has_limits,
    float min_angle,
    float max_angle);
JR_EXPORT JPH_Constraint* JR_Constraint_CreateSlider(
    JPH_PhysicsSystem* system,
    uint32_t body_a,
    uint32_t body_b,
    const float* anchor,
    const float* axis,
    bool has_limits,
    float min_distance,
    float max_distance);

JR_EXPORT JPH_CharacterVirtual* JR_CharacterVirtual_Create(
    JPH_PhysicsSystem* system,
    const JPH_Shape* shape,
    const float* position,
    const float* rotation,
    float max_slope_angle,
    float mass);
JR_EXPORT void JR_CharacterVirtual_ExtendedUpdate(
    JPH_CharacterVirtual* character,
    float delta_time,
    uint32_t layer,
    JPH_PhysicsSystem* system);

#ifdef __cplusplus
}
#endif

#endif
