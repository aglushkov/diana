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
        def self.inspect
          "<Diana.dependencies:#{object_id.to_s(16)}>"
        end

        define_singleton_method(:included) do |base|
          merged_deps =
            if base.instance_variable_defined?(:@_diana_dependencies)
              base.instance_variable_get(:@_diana_dependencies).merge!(deps)
            else
              base.instance_variable_set(:@_diana_dependencies, deps.dup)
            end

          class_eval(<<~INITIALIZE, __FILE__, __LINE__ + 1)
            def initialize(#{merged_deps.each_key.map { |dependency| "#{dependency}: nil" }.join(", ")})
            #{merged_deps.each_key.map { |dependency| "  @#{dependency} = #{dependency} if #{dependency}" }.join("\n")}
            end
          INITIALIZE
        end

        deps.each_key do |dependency|
          class_eval(<<~ATTR_READER, __FILE__, __LINE__ + 1)
            def #{dependency}
              @#{dependency} ||= Diana.resolve(self.class.instance_variable_get(:@_diana_dependencies)[:#{dependency}])
            end

            private :#{dependency} if Diana.methods_visibility == :private
          ATTR_READER
        end
      end
    end

    alias_method :dependency, :dependencies
  end
end
