# frozen_string_literal: true

RSpec.describe "Diana::Config" do
  describe ".resolver, .resolver=" do
    it "returns the default resolver if no custom resolver is set" do
      expect(Diana.resolver).to be_a Proc
    end

    it "sets & returns the custom resolver" do
      custom_resolver = ->(value) { value * 2 }
      Diana.resolver = custom_resolver
      expect(Diana.resolver).to eq(custom_resolver)
    ensure
      Diana.remove_instance_variable(:@resolver)
    end
  end

  describe ".resolve" do
    it "resolves a value using the default resolver" do
      expect(Diana.resolve(-> { 42 })).to eq(42)
    end

    it "resolves a value directly if it is not a proc" do
      expect(Diana.resolve(42)).to eq(42)
    end
  end

  describe ".methods_visibility, .methods_visibility=" do
    it "returns the default private visibility if no custom visibility is set" do
      expect(Diana.methods_visibility).to eq :private
    end

    it "sets & returns the custom visibility" do
      Diana.methods_visibility = :public
      expect(Diana.methods_visibility).to eq(:public)
    ensure
      Diana.remove_instance_variable(:@methods_visibility)
    end

    it "raises error for invalid visibility" do
      expect { Diana.methods_visibility = :protected }
        .to raise_error ArgumentError, "methods_visibility value must be :private or :public"
    end
  end
end
