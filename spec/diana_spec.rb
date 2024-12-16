# frozen_string_literal: true

RSpec.describe Diana do
  it "has a version number" do
    expect(Diana::VERSION).not_to be_nil
  end

  describe ".resolve" do
    it "resolves a value using the default resolver" do
      expect(described_class.resolve(-> { 42 })).to eq(42)
    end

    it "resolves a value directly if it is not a proc" do
      expect(described_class.resolve(42)).to eq(42)
    end
  end

  describe ".resolver, .resolver=" do
    it "returns the default resolver if no custom resolver is set" do
      expect(described_class.resolver).to be_a Proc
    end

    it "sets & returns the custom resolver" do
      custom_resolver = ->(value) { value * 2 }
      described_class.resolver = custom_resolver
      expect(described_class.resolver).to eq(custom_resolver)
    ensure
      described_class.remove_instance_variable(:@resolver)
    end
  end

  describe ".dependencies" do
    it "includes dependencies into the current context" do
      obj = Class.new { include Diana.dependencies(foo: proc { "FOO" }) }.new
      expect(obj.foo).to eq "FOO"
    end

    it "aliases .dependencies method to .dependency" do
      expect(described_class.method(:dependency)).to eq(described_class.method(:dependencies))
    end

    it "memorizes dependency" do
      obj = Class.new { include Diana.dependency(foo: proc { rand }) }.new
      expect(obj.foo).to equal(obj.foo)
    end

    it "add dependency lazily" do
      obj = Class.new { include Diana.dependency(foo: proc {}) }.new
      expect(obj.instance_variable_defined?(:@foo)).to be false
      expect(obj.foo).to be_nil
      expect(obj.instance_variable_defined?(:@foo)).to be true
    end

    it "adds dependency to a child" do
      klass = Class.new { include Diana.dependency(foo: proc { "FOO" }) }
      child = Class.new(klass).new
      expect(child.foo).to eq "FOO"
    end

    it "adds dependency to a child of a child" do
      klass = Class.new { include Diana.dependency(foo: proc { "FOO" }) }
      child_class = Class.new(klass)
      child_of_a_child = Class.new(child_class).new
      expect(child_of_a_child.foo).to eq "FOO"
    end

    it "allows to overwrite dependency with an initializer" do
      klass = Class.new { include Diana.dependency(foo: proc { "FOO" }) }
      obj = klass.new(foo: "new-foo")
      expect(obj.instance_variable_get(:@foo)).to eq "new-foo"
      expect(obj.foo).to eq "new-foo"
    end

    it "allows to overwrite dependency with another dependency" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { raise })
      klass.include described_class.dependency(foo: proc { "FOO" })
      expect(klass.new.foo).to eq "FOO"
    end

    it "allows to overwrite dependency with another dependency for a child class" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { raise })
      child_class = Class.new(klass)
      child_class.include described_class.dependency(foo: proc { "FOO" })
      expect(child_class.new.foo).to eq "FOO"
    end

    it "allows to overwrite dependency with another dependency for a child of a child class" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { raise })
      child_class = Class.new(klass)
      child_class.include described_class.dependency(foo: proc { raise })
      child_of_a_child_class = Class.new(child_class)
      child_of_a_child_class.include described_class.dependency(foo: proc { "FOO" })

      expect(child_of_a_child_class.new.foo).to eq "FOO"
    end

    it "does not modifies parent dependencies when dependencies are inherited" do
      klass = Class.new
      klass.include described_class.dependency(foo: "FOO1", bar: "BAR1")
      child_class = Class.new(klass)
      child_class.include described_class.dependency(foo: "FOO2", bazz: "BAZZ2")

      expect(klass.instance_variable_get(:@_diana_dependencies)).to eq(foo: "FOO1", bar: "BAR1")
      expect(child_class.instance_variable_get(:@_diana_dependencies)).to eq(foo: "FOO2", bar: "BAR1", bazz: "BAZZ2")
    end

    it "allows to use `.dependencies` method as alias to `.dependency`" do
      klass = Class.new
      klass.include described_class.dependency(foo: proc { "DEPENDENCY" })
      klass.include described_class.dependencies(foo: proc { "DEPENDENCIES" })
      expect(klass.new.foo).to eq "DEPENDENCIES"
    end

    it "allows to extend Diana module and use `dependencies` or `dependency` DSL" do
      klass = Class.new
      klass.extend described_class
      klass.dependencies(foo: proc { "FOO" })
      klass.dependency(bar: proc { "BAR" })
      obj = klass.new
      expect(obj.foo).to eq "FOO"
      expect(obj.bar).to eq "BAR"
    end

    it "allows to include multiple dependencies" do
      klass = Class.new do
        include Diana.dependencies(
          foo: proc { "FOO" },
          bar: proc { "BAR" }
        )
      end

      obj = klass.new
      expect(obj.foo).to eq "FOO"
      expect(obj.bar).to eq "BAR"
    end

    it "allows to include dependencies to classes with custom initializers" do
      klass = Class.new do
        include Diana.dependencies(foo: proc { "FOO" })

        def initialize(arg, kwarg:)
        end
      end

      obj = klass.new(nil, kwarg: nil)
      expect(obj.foo).to eq "FOO"
    end

    it "allows to overwrite dependencies in classes with custom initializers" do
      klass = Class.new do
        include Diana.dependencies(foo: proc { "FOO" })

        def initialize(_arg, _kwarg:)
        end
      end

      obj = klass.new(nil, _kwarg: nil, foo: "NEW-FOO")
      expect(obj.foo).to eq "NEW-FOO"
    end

    it "allows to overwrite dependencies in child classes with custom initializers" do
      klass = Class.new do
        include Diana.dependencies(foo: proc { "FOO" })

        def initialize(_arg, _kwarg:)
        end
      end

      child_class = Class.new(klass) do
        def initialize(arg1, _arg2, kwarg1:)
          super(arg1, _kwarg: kwarg1)
        end
      end

      obj = child_class.new(nil, nil, kwarg1: nil, foo: "NEW-FOO")
      expect(obj.foo).to eq "NEW-FOO"
    end

    it "loads single Diana module for class && instance" do
      klass = Class.new { include Diana.dependencies(foo: nil) }

      expect(klass.ancestors).to be_one { |mod| mod.name&.start_with?("<Diana.instance_module") }
      expect(klass.singleton_class.ancestors).to be_one { |mod| mod.name&.start_with?("<Diana.class_module") }
    end
  end
end
