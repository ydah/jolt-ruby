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

#ifdef __cplusplus
}
#endif

#endif
