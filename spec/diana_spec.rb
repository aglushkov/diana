# frozen_string_literal: true

RSpec.describe Diana do
  describe ".dependencies" do
    it "includes dependencies into the current context" do
      obj = Class.new { include Diana.dependencies(foo: proc { "FOO" }) }.new
      expect(obj.__send__(:foo)).to eq "FOO"
    end

    it "includes public dependencies if configured" do
      described_class.methods_visibility = :public
      obj = Class.new { include Diana.dependencies(foo: proc { "FOO" }) }.new
      expect(obj.foo).to eq "FOO" # `foo` is a public method
    ensure
      described_class.remove_instance_variable(:@methods_visibility)
    end

    it "aliases .dependencies method to .dependency" do
      expect(described_class.method(:dependency)).to eq(described_class.method(:dependencies))
    end

    it "memorizes dependency" do
      obj = Class.new { include Diana.dependency(foo: proc { rand }) }.new
      expect(obj.__send__(:foo)).to equal(obj.__send__(:foo))
    end

    it "add dependency lazily" do
      obj = Class.new { include Diana.dependency(foo: proc { "VALUE" }) }.new
      expect(obj.instance_variable_defined?(:@foo)).to be false
      expect(obj.__send__(:foo)).to eq "VALUE"
      expect(obj.instance_variable_defined?(:@foo)).to be true
    end

    it "allows to overwrite dependency with an initializer" do
      klass = Class.new { include Diana.dependency(foo: proc { "FOO" }) }
      obj = klass.new(foo: "new-foo")
      expect(obj.instance_variable_get(:@foo)).to eq "new-foo"
      expect(obj.__send__(:foo)).to eq "new-foo"
    end

    it "allows to overwrite dependency with another dependency" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { raise }, bar: proc { "BAR" })
      klass.include described_class.dependency(foo: proc { "FOO" }, bazz: proc { "BAZZ" })
      obj = klass.new
      expect(obj.__send__(:foo)).to eq "FOO"
      expect(obj.__send__(:bar)).to eq "BAR"
      expect(obj.__send__(:bazz)).to eq "BAZZ"
    end

    it "allows to overwrite multiple dependencies through initializer" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { "FOO" })
      klass.include described_class.dependency(bar: proc { "BAR" })
      obj = klass.new(foo: "foo", bar: "bar")
      expect(obj.__send__(:foo)).to eq "foo"
      expect(obj.__send__(:bar)).to eq "bar"
    end

    it "allows to use `.dependencies` method as alias to `.dependency`" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { "DEPENDENCY" })
      klass.include described_class.dependencies(foo: proc { "DEPENDENCIES" })
      obj = klass.new
      expect(obj.__send__(:foo)).to eq "DEPENDENCIES"
    end

    it "allows to include multiple dependencies" do
      klass = Class.new do
        include Diana.dependencies(
          foo: proc { "FOO" },
          bar: proc { "BAR" }
        )
      end

      obj = klass.new
      expect(obj.__send__(:foo)).to eq "FOO"
      expect(obj.__send__(:bar)).to eq "BAR"
    end

    it "loads single Diana module for instance" do
      klass = Class.new { include Diana.dependencies(foo: nil) }

      expect(klass.ancestors).to be_one { |mod| mod.inspect.start_with?("<Diana.dependencies:") }
    end
  end
end
