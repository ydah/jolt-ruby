# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::Layers do
  it "provides the conventional static and moving layers" do
    layers = described_class.default

    expect(layers.object_layer_id(:non_moving)).to eq(0)
    expect(layers.object_layer_id(:moving)).to eq(1)
  end

  it "builds custom table-driven collision layers" do
    layers = described_class.define do |builder|
      builder.broad_phase :static, :dynamic
      builder.object :ground, broad_phase: :static
      builder.object :player, :enemy, broad_phase: :dynamic
      builder.collide :player, with: %i[ground enemy]
    end

    expect(layers.object_layers).to eq(ground: 0, player: 1, enemy: 2)
    expect(layers.broad_phase_layers).to eq(static: 0, dynamic: 1)
  end

  it "rejects incomplete definitions before reaching native code" do
    expect do
      described_class.define do |builder|
        builder.broad_phase :static
        builder.object :ground, broad_phase: :missing
      end
    end.to raise_error(Jolt::InvalidArgumentError, /unknown broad-phase/)
  end
end
