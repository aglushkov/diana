# frozen_string_literal: true

require_relative "diana/version"
require_relative "diana/config"

#
# Dependency Injection DSL
#
# This module offers a DSL designed for the lazy resolution of dependency
# injections. It facilitates efficient and deferred initialization of
# dependencies ensuring that resources are only allocated when necessary.
#
# This approach optimizes performance of application.
#
# @example
#   class MyClass
#     include Diana.dependencies(
#       foo: proc { Foo.new },
#       bar: proc { Bar.new }
#     )
#   end
#
#
module Diana
  extend Config

  class << self
    # Define dependencies for a class.
    #
    # @example
    #   class MyClass
    #     include Diana.dependencies(
    #       foo: proc { MyFoo.new }
    #       bar: proc { MyBar.new }
    #     )
    #   end
    #
    # param deps [Hash] A hash where keys are the names of the dependencies and
    #   values are the dependencies themselves, resolved lazily.
    #
    # @return [Module] A module to be included in your class, providing the
    #   defined dependencies.
    #
    def dependencies(deps)
      Module.new do
        # Adds readable name to this anonymous module when showing `MyClass.ancestors`
        def self.inspect
          "<Diana.dependencies:#{object_id.to_s(16)}>"
        end

        class_mod = Module.new do
          # Adds readable name to this anonymous module when showing `MyClass.singleton_class.ancestors`
          def self.inspect
            "<Diana.inheritance:#{object_id.to_s(16)}>"
          end

          private

          def inherited(subclass)
            # When `inherited` is called for the first time, we add the parent's
            # `@_diana_dependencies`. To avoid adding dependencies from
            # ancestors in the `super` call, we check if `@_diana_dependencies`
            # is already defined.
            unless subclass.instance_variable_defined?(:@_diana_dependencies)
              subclass.include Diana.dependencies(@_diana_dependencies)
            end

            super
          end
        end

        define_singleton_method(:included) do |base|
          # Adds .inherited method
          base.extend(class_mod)

          #
          # Merging dependencies allows to add dependencies multiple times
          #
          # Example:
          #   class MyClass
          #     include Diana.dependencies(foo: 'foo')
          #     include Diana.dependencies(bar: 'bar')
          #   end
          #
          merged_deps =
            if base.instance_variable_defined?(:@_diana_dependencies)
              base.instance_variable_get(:@_diana_dependencies).merge!(deps)
            else
              base.instance_variable_set(:@_diana_dependencies, deps.dup)
            end

          # Add initialize method
          # Instance variables are set only for not-null dependencies.
          # Using class_eval is slower to define the method, yet it provides the
          # benefit of executing faster than if it were defined using define_method.
          class_eval(<<~INITIALIZE, __FILE__, __LINE__ + 1)
            def initialize(#{merged_deps.each_key.map { |dependency| "#{dependency}: nil" }.join(", ")})
            #{merged_deps.each_key.map { |dependency| "  @#{dependency} = #{dependency} if #{dependency}" }.join("\n")}
            end
          INITIALIZE
        end

        # Add dependencies attribute readers and set their visibility.
        # Using class_eval is slower to define the method, yet it provides the
        # benefit of executing faster than if it were defined using define_method.
        deps.each_key do |dependency|
          class_eval(<<~ATTR_READER, __FILE__, __LINE__ + 1)
            def #{dependency}
              @#{dependency} ||= Diana.resolve(self.class.instance_variable_get(:@_diana_dependencies)[:#{dependency}])
            end

            #{Diana.methods_visibility} :#{dependency}
          ATTR_READER
        end
      end
    end

    alias_method :dependency, :dependencies
  end
end
