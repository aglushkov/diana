# frozen_string_literal: true

module Diana
  #
  # Defines Diana module configuration methods
  #
  module Config
    # The default resolver for dependencies.
    DEFAULT_RESOLVER = proc { |dependency| dependency.is_a?(Proc) ? dependency.call : dependency }

    # The default visibility for generated dependency methods.
    DEFAULT_METHODS_VISIBILITY = :private

    private_constant :DEFAULT_RESOLVER
    private_constant :DEFAULT_METHODS_VISIBILITY

    # Returns the current resolver.
    #
    # @api private
    # @return [#call] The current resolver.
    def resolver
      @resolver || DEFAULT_RESOLVER
    end

    # Sets a new resolver.
    #
    # @example Setting a resolver that can resolve strings to a DI container.
    #   Diana.resolver = proc do |value|
    #     case value
    #     when Proc then value.call
    #     when String then MyContainer[value].call
    #     else value
    #     end
    #   end
    #
    # @param new_resolver [#call] The new resolver to set.
    # @return [#call] The new resolver.
    def resolver=(new_resolver)
      @resolver = new_resolver
    end

    # Resolves a given value using the current resolver.
    #
    # @api private
    # @param value [Object] The value to resolve.
    # @return [Object] The resolved value.
    def resolve(value)
      resolver.call(value)
    end

    # Returns the current visibility of dependency methods.
    #
    # @api private
    # @return [Symbol] The current visibility of dependency methods.
    def methods_visibility
      @methods_visibility || DEFAULT_METHODS_VISIBILITY
    end

    # Sets the visibility of dependency methods.
    #
    # @example Setting the default visibility of dependency methods to public.
    #   Diana.methods_visibility = :public
    #
    # @param visibility [Symbol] The new visibility for dependency methods (:private, :public, :protected).
    # @return [Symbol] The new default visibility for dependency methods.
    # @raise [ArgumentError] If the visibility is not :private, :public, or :protected.
    #
    def methods_visibility=(visibility)
      if (visibility != :private) && (visibility != :public) && (visibility != :protected)
        raise ArgumentError, "methods_visibility value must be :private, :public, or :protected"
      end

      @methods_visibility = visibility
    end
  end
end
