# frozen_string_literal: true

require_relative "diana/version"

# @main Diana
# @title Diana - Lazy Dependency Injection
# @description This module provides DSL for dependency injection.
module Diana
  # Default resolver for dependencies.
  DEFAULT_RESOLVER = proc { |dependency| dependency.is_a?(Proc) ? dependency.call : dependency }
  private_constant :DEFAULT_RESOLVER

  # Resolves a given value using the current resolver.
  #
  # @api private
  # @param value [Object] The value to resolve.
  # @return [Object] The resolved value.
  def self.resolve(value)
    resolver.call(value)
  end

  # Returns the current resolver.
  #
  # @api private
  # @return [#call] The current resolver.
  def self.resolver
    @resolver || DEFAULT_RESOLVER
  end

  # Sets a new resolver.
  #
  # @example Adding a resolver that can resolve strings to some DI container.
  #   Diana.resolver = proc do |value|
  #     case value
  #     when Proc then value.call
  #     when String then MyContainer[value].call
  #     else value
  #     end
  #   end
  #
  #   class MyClass
  #     include Diana.dependencies(foo: 'my_utils.foo')
  #   end
  #
  # @param new_resolver [#call] The new resolver to set.
  # @return [#call] new resolver
  #
  def self.resolver=(new_resolver)
    @resolver = new_resolver
  end

  # Includes dependencies into the current class.
  #
  # @example
  #   class MyClass
  #     extend Diana
  #     dependencies(foo: proc { MyFoo.new })
  #   end
  #
  # @param deps [Hash] A hash where the keys are the name of the dependencies,
  #   and the values are directly dependencies or wrappers over the dependencies,
  #   which will be determined lazily using Diana.resolver when the dependency
  #   is first accessed by name
  #
  # @return void
  def dependencies(**deps)
    include Diana.dependencies(**deps)
  end

  alias_method :dependency, :dependencies

  class << self
    # Defines dependencies.
    #
    # @example
    #   class MyClass
    #     include Diana.dependencies(
    #       foo: proc { MyFoo.new }
    #       bar: proc { MyBar.new }
    #     )
    #   end
    #
    # @param deps [Hash] Named dependencies, where keys are dependencies names
    #   and values are dependencies values which resolved lazily.
    #
    # @return [Module] The module which must be included into your class.
    #
    def dependencies(**deps)
      Module.new do
        class_mod = Module.new do
          define_method :new do |*args, **kwargs, &block|
            overwritten_dependencies =
              deps.each_key.reduce(nil) do |res, key|
                kwargs.key?(key) ? (res || []) << [key, kwargs.delete(key)] : res
              end

            instance = super(*args, **kwargs, &block)

            overwritten_dependencies&.each do |key, value|
              instance.instance_variable_set(:"@#{key}", value)
            end

            instance
          end

          define_method :inherited do |subclass|
            parent_dependencies = subclass.superclass.instance_variable_get(:@_diana_dependencies)
            subclass.instance_variable_set(:@_diana_dependencies, parent_dependencies.dup)
            super(subclass)
          end
        end.tap { |mod| mod.set_temporary_name("<Diana.class_module:#{mod.object_id.to_s(16)}>") }

        define_singleton_method(:included) do |base|
          if base.instance_variable_defined?(:@_diana_dependencies)
            base.instance_variable_get(:@_diana_dependencies).merge!(deps)
          else
            base.instance_variable_set(:@_diana_dependencies, deps.dup)
          end

          base.extend(class_mod)
        end

        deps.each_key do |dependency|
          instance_variable_name = :"@#{dependency}"

          define_method(dependency) do
            return instance_variable_get(instance_variable_name) if instance_variable_defined?(instance_variable_name)

            dependency = self.class.instance_variable_get(:@_diana_dependencies)[dependency]
            instance_variable_set(instance_variable_name, Diana.resolve(dependency))
          end
        end
      end.tap { |mod| mod.set_temporary_name("<Diana.instance_module:#{mod.object_id.to_s(16)}>") }
    end

    alias_method :dependency, :dependencies
  end
end
