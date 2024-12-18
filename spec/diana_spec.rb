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

    it "merges parent and subclasses dependencies" do
      parent = Class.new
      parent.include described_class.dependency(foo: "PARENT_FOO", bar: "PARENT_BAR")
      subclass1 = Class.new(parent)
      subclass1.include described_class.dependency(bar: "CHILD_BAR", bazz: "CHILD_BAZZ")
      subclass2 = Class.new(subclass1)
      subclass2.include described_class.dependency(bazz: "CHILD_BAZZ_2")

      expect(parent.instance_variable_get(:@_diana_dependencies))
        .to eq(foo: "PARENT_FOO", bar: "PARENT_BAR")

      expect(subclass1.instance_variable_get(:@_diana_dependencies))
        .to eq(foo: "PARENT_FOO", bar: "CHILD_BAR", bazz: "CHILD_BAZZ")

      expect(subclass2.instance_variable_get(:@_diana_dependencies))
        .to eq(foo: "PARENT_FOO", bar: "CHILD_BAR", bazz: "CHILD_BAZZ_2")

      obj = subclass2.new
      expect(obj.__send__(:foo)).to eq "PARENT_FOO"
      expect(obj.__send__(:bar)).to eq "CHILD_BAR"
      expect(obj.__send__(:bazz)).to eq "CHILD_BAZZ_2"
    end

    it "allows to overwrite parent dependencies in subclass `initialize` method" do
      parent = Class.new
      parent.include described_class.dependency(foo: "PARENT_FOO")
      subclass = Class.new(parent)

      obj = subclass.new(foo: "OVERWRITE_FOO")
      expect(obj.__send__(:foo)).to eq "OVERWRITE_FOO"
    end

    it "allows to use `include Diana.dependency` multiple times and merges this dependencies" do
      klass = Class.new
      klass.include described_class.dependencies(foo: "FOO", bar: "BAR")
      klass.include described_class.dependencies(bar: "BAR2", baz: "BAZ")

      obj = klass.new
      expect(obj.__send__(:foo)).to eq "FOO"
      expect(obj.__send__(:bar)).to eq "BAR2"
      expect(obj.__send__(:baz)).to eq "BAZ"
    end

    it "allows to use `.dependency` method as alias to `.dependencies`" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { "DEPENDENCY" })
      obj = klass.new
      expect(obj.__send__(:foo)).to eq "DEPENDENCY"
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

    it "adds `inspect` method to loaded modules" do
      klass = Class.new { include Diana.dependencies(foo: nil) }

      expect(klass.ancestors).to be_one { |mod| mod.inspect.start_with?("<Diana.dependencies:") }
      expect(klass.singleton_class.ancestors).to be_one { |mod| mod.inspect.start_with?("<Diana.inheritance:") }
    end
  end
end
