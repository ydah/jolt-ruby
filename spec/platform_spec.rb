# frozen_string_literal: true

RSpec.describe Jolt::Native::Platform do
  describe ".tag" do
    it "normalizes every supported release target" do
      expect(described_class.tag(cpu: "x86_64", os: "linux-gnu")).to eq("x86_64-linux")
      expect(described_class.tag(cpu: "aarch64", os: "linux-gnu")).to eq("aarch64-linux")
      expect(described_class.tag(cpu: "arm64", os: "darwin24")).to eq("arm64-darwin")
      expect(described_class.tag(cpu: "x86_64", os: "darwin23")).to eq("x86_64-darwin")
      expect(described_class.tag(cpu: "x64", os: "mingw-ucrt")).to eq("x64-mingw-ucrt")
    end
  end
end
