# frozen_string_literal: true

module Jolt
  Contact = Data.define(
    :body_a,
    :body_b,
    :sub_shape_a,
    :sub_shape_b,
    :point,
    :normal,
    :penetration
  )

  ContactEvents = Data.define(:added, :persisted, :removed, :dropped_count) do
    def self.empty
      new(added: [].freeze, persisted: [].freeze, removed: [].freeze, dropped_count: 0)
    end
  end
end
