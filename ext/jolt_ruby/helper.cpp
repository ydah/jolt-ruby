#include "helper.h"

#include <joltc.h>

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <new>

namespace {

struct Slot {
  std::atomic<size_t> sequence;
  JR_ContactEvent event;
};

uint32_t next_power_of_two(uint32_t value) {
  if (value < 2) return 2;

  --value;
  value |= value >> 1;
  value |= value >> 2;
  value |= value >> 4;
  value |= value >> 8;
  value |= value >> 16;
  return value + 1;
}

void copy_vec3(float target[3], const JPH_Vec3& source) {
  target[0] = source.x;
  target[1] = source.y;
  target[2] = source.z;
}

void copy_rvec3(float target[3], const JPH_RVec3& source) {
  target[0] = static_cast<float>(source.x);
  target[1] = static_cast<float>(source.y);
  target[2] = static_cast<float>(source.z);
}

}  // namespace

struct JR_ContactQueue {
  explicit JR_ContactQueue(uint32_t requested_capacity)
      : capacity(next_power_of_two(requested_capacity)),
        mask(capacity - 1),
        slots(new Slot[capacity]) {
    for (size_t index = 0; index < capacity; ++index) {
      slots[index].sequence.store(index, std::memory_order_relaxed);
    }
  }

  bool push(const JR_ContactEvent& event) {
    size_t position = enqueue_position.load(std::memory_order_relaxed);
    Slot* slot = nullptr;

    for (;;) {
      slot = &slots[position & mask];
      const size_t sequence = slot->sequence.load(std::memory_order_acquire);
      const intptr_t difference = static_cast<intptr_t>(sequence) - static_cast<intptr_t>(position);
      if (difference == 0) {
        if (enqueue_position.compare_exchange_weak(position, position + 1, std::memory_order_relaxed)) break;
      } else if (difference < 0) {
        dropped.fetch_add(1, std::memory_order_relaxed);
        return false;
      } else {
        position = enqueue_position.load(std::memory_order_relaxed);
      }
    }

    slot->event = event;
    slot->sequence.store(position + 1, std::memory_order_release);
    return true;
  }

  bool pop(JR_ContactEvent& event) {
    size_t position = dequeue_position.load(std::memory_order_relaxed);
    Slot* slot = nullptr;

    for (;;) {
      slot = &slots[position & mask];
      const size_t sequence = slot->sequence.load(std::memory_order_acquire);
      const intptr_t difference =
          static_cast<intptr_t>(sequence) - static_cast<intptr_t>(position + 1);
      if (difference == 0) {
        if (dequeue_position.compare_exchange_weak(position, position + 1, std::memory_order_relaxed)) break;
      } else if (difference < 0) {
        return false;
      } else {
        position = dequeue_position.load(std::memory_order_relaxed);
      }
    }

    event = slot->event;
    slot->sequence.store(position + capacity, std::memory_order_release);
    return true;
  }

  const size_t capacity;
  const size_t mask;
  std::unique_ptr<Slot[]> slots;
  alignas(64) std::atomic<size_t> enqueue_position{0};
  alignas(64) std::atomic<size_t> dequeue_position{0};
  std::atomic<uint64_t> dropped{0};
  JPH_ContactListener* listener{nullptr};
};

namespace {

JPH_ValidateResult on_contact_validate(
    void*,
    const JPH_Body*,
    const JPH_Body*,
    const JPH_RVec3*,
    const JPH_CollideShapeResult*) {
  return JPH_ValidateResult_AcceptAllContactsForThisBodyPair;
}

void push_manifold_event(
    JR_ContactQueue* queue,
    JR_ContactEventType type,
    const JPH_Body* body1,
    const JPH_Body* body2,
    const JPH_ContactManifold* manifold) {
  JR_ContactEvent event{};
  event.type = type;
  event.body_a = JPH_Body_GetID(body1);
  event.body_b = JPH_Body_GetID(body2);
  event.sub_shape_a = JPH_ContactManifold_GetSubShapeID1(manifold);
  event.sub_shape_b = JPH_ContactManifold_GetSubShapeID2(manifold);
  event.penetration = JPH_ContactManifold_GetPenetrationDepth(manifold);

  JPH_Vec3 normal{};
  JPH_ContactManifold_GetWorldSpaceNormal(manifold, &normal);
  copy_vec3(event.normal, normal);

  if (JPH_ContactManifold_GetPointCount(manifold) > 0) {
    JPH_RVec3 point{};
    JPH_ContactManifold_GetWorldSpaceContactPointOn1(manifold, 0, &point);
    copy_rvec3(event.point, point);
  }

  queue->push(event);
}

void on_contact_added(
    void* user_data,
    const JPH_Body* body1,
    const JPH_Body* body2,
    const JPH_ContactManifold* manifold,
    JPH_ContactSettings*) {
  push_manifold_event(
      static_cast<JR_ContactQueue*>(user_data), JR_CONTACT_ADDED, body1, body2, manifold);
}

void on_contact_persisted(
    void* user_data,
    const JPH_Body* body1,
    const JPH_Body* body2,
    const JPH_ContactManifold* manifold,
    JPH_ContactSettings*) {
  push_manifold_event(
      static_cast<JR_ContactQueue*>(user_data), JR_CONTACT_PERSISTED, body1, body2, manifold);
}

void on_contact_removed(void* user_data, const JPH_SubShapeIDPair* pair) {
  JR_ContactEvent event{};
  event.type = JR_CONTACT_REMOVED;
  event.body_a = pair->Body1ID;
  event.body_b = pair->Body2ID;
  event.sub_shape_a = pair->subShapeID1;
  event.sub_shape_b = pair->subShapeID2;
  static_cast<JR_ContactQueue*>(user_data)->push(event);
}

void install_contact_procs() {
  static JPH_ContactListener_Procs procs{};
  procs.OnContactValidate = on_contact_validate;
  procs.OnContactAdded = on_contact_added;
  procs.OnContactPersisted = on_contact_persisted;
  procs.OnContactRemoved = on_contact_removed;
  JPH_ContactListener_SetProcs(&procs);
}

}  // namespace

JR_ContactQueue* JR_ContactQueue_Create(uint32_t capacity) {
  if (capacity < 2 || capacity > (1U << 30)) return nullptr;

  static std::once_flag contact_procs_once;
  std::call_once(contact_procs_once, install_contact_procs);

  JR_ContactQueue* queue = nullptr;
  try {
    queue = new JR_ContactQueue(capacity);
  } catch (const std::bad_alloc&) {
    return nullptr;
  }
  queue->listener = JPH_ContactListener_Create(queue);
  if (queue->listener) return queue;

  delete queue;
  return nullptr;
}

void JR_ContactQueue_Destroy(JR_ContactQueue* queue) {
  if (!queue) return;

  if (queue->listener) JPH_ContactListener_Destroy(queue->listener);
  delete queue;
}

JPH_ContactListener* JR_ContactQueue_GetListener(JR_ContactQueue* queue) {
  return queue ? queue->listener : nullptr;
}

bool JR_ContactQueue_Pop(JR_ContactQueue* queue, JR_ContactEvent* event) {
  return queue && event && queue->pop(*event);
}

uint64_t JR_ContactQueue_GetDroppedCount(const JR_ContactQueue* queue) {
  return queue ? queue->dropped.load(std::memory_order_relaxed) : 0;
}
