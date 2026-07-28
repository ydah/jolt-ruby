# frozen_string_literal: true

RSpec.describe Jolt do
  it "has a version number" do
    expect(Jolt::VERSION).not_to be nil
  end

  it "loads every function declared by the generated binding" do
    described_class.init

    expect(Jolt::Native::Generated.missing_functions).to be_empty
  end

  it "initializes and shuts down the native engine" do
    expect(described_class.init).to equal(described_class)
    expect(described_class).to be_initialized

    described_class.shutdown

    expect(described_class).not_to be_initialized
  end
end
