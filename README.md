[![Gem Version](https://badge.fury.io/rb/diana.svg)](https://badge.fury.io/rb/diana)
[![GitHub Actions](https://github.com/aglushkov/diana/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/aglushkov/diana/actions/workflows/main.yml)
[![Test Coverage](https://api.codeclimate.com/v1/badges/9e874aec44744552e642/test_coverage)](https://codeclimate.com/github/aglushkov/diana/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/9e874aec44744552e642/maintainability)](https://codeclimate.com/github/aglushkov/diana/maintainability)

# Diana - Lazy Dependency Injection

This module offers a DSL designed for the lazy resolution of dependency injections.

It facilitates efficient and deferred initialization of dependencies,
ensuring that resources are only allocated when necessary.

This approach optimizes performance of application.

## Features

- **Lazy Initialization**: Dependencies are lazily initialized, ensuring
  they are only loaded when you need them, optimizing performance
- **Transparent Behavior**: No hidden or undocumented behaviors, providing a
  clear and predictable experience
- **Flexible Integration**: No dependencies, no mandatory DI container, but you
  can seamlessly integrate with any container of your choice.
- **Broad Compatibility**: Supports a wide range of Ruby versions,
  including 2.6 to 3.3, head, JRuby-9.4, and TruffleRuby-24.

These features are designed to make your development process smoother and more efficient!

## Installation

```bash
bundle add diana
```

## Usage

The Diana gem provides a streamlined way to define and manage dependencies in
your Ruby application.

### Defining Dependencies

Use the `.dependencies` method to define your dependencies. You can also use the
`.dependency` alias if you prefer.

```ruby
class SomeClass
  include Diana.dependencies(
    foo: proc { Foo.new },
    bar: proc { Bar.new }
  )

  def some_method
    foo # => Foo.new
    bar # => Bar.new
  end
end
```

### Lazy Initialization

Dependencies are lazily initialized, meaning they are only loaded when accessed
for the first time.

### Methods Visibility

By default, dependency methods are **private**. You can change this behavior by
configuring the Diana module:

```ruby
Diana.methods_visibility = :public # private, public, protected
```

Using **public** methods can be more convenient in tests, allowing you to access
the real dependency and stub its methods, rather than overwriting the dependency
entirely. This approach helps ensure you are testing the correct dependency.

### Inheritance

Classes with included dependencies can be nested. Dependencies from parent and
child classes are merged.

### Adding dependencies multiple times

`Diana.dependencies` method can be used multiple times. In this case
dependencies are merged.

```ruby
class SomeClass
  include Diana.dependencies(foo: proc { Foo.new })
  include Diana.dependencies(bar: proc { Bar.new })
end
```

## How it works

- **Dependency Storage**: The `@_diana_dependencies` class variable holds the
  provided dependencies.
- **Initialization**: An `#initialize` method is added to handle dependency
  injection.
- **Reader Methods**: Private (by default) reader methods for dependencies are
  created.
- **Lazy Resolution**: Dependencies are resolved upon first access using a
  configurable resolver.

Here is an example of dependency injection and the final pseudo-code generated
by the gem:

```ruby
class SomeClass
  include Diana.dependencies(
    foo: proc { Foo.new },
    bar: proc { Bar.new }
  )
end

# Generated pseudo-code:
class SomeClass
  @_diana_dependencies = {
    foo: proc { Foo.new },
    bar: proc { Bar.new }
  }

  # handles dependency injection
  def initialize(foo: nil, bar: nil)
    @foo = foo if foo
    @bar = bar if bar
  end

  # handles inheritance
  def self.inherited(subclass)
    subclass.include Diana.dependencies(@_diana_dependencies)
    super
  end

  private

  # handles lazy `foo` resolution
  def foo
    @foo ||= Diana.resolve(self.class.instance_variable_get(:@_diana_dependencies)[:foo])
  end

  # handles lazy `bar` resolution
  def bar
    @bar ||= Diana.resolve(self.class.instance_variable_get(:@_diana_dependencies)[:bar])
  end
end
```

This structure ensures efficient and flexible dependency management.

## Custom Resolvers

The default resolver handles only procs, functioning as follows:

```ruby
DEFAULT_RESOLVER = proc do |dependency|
  dependency.is_a?(Proc) ? dependency.call : dependency
end
```

You can customize the resolver to fit your needs. For instance, to resolve
strings to a DI container, you can modify the resolver like this:

```ruby
Diana.resolver = proc do |dependency|
  case dependency
  when String then DI_CONTAINER[dependency]
  when Proc then dependency.call
  else dependency
  end
end

SomeClass.include Diana.dependencies(foo: 'utils.foo') # => DI_CONTAINER['utils.foo']
```

## Important Notes

- This gem is intended for use with classes that have no manually defined
  `#initialize` method. This design choice prevents  conflicts or unpredictable
  behavior with custom #initialize methods. If you do add a custom `#initialize`
  method, it will take precedence. In such cases, ensure you include a
  `super(**deps)` call to override dependencies if needed.

- We avoid calling `super` in the added `#initialize` method to prevent the need
  for arguments modifications, which could negatively impact performance.

These limitations ensure that the gem remains predictable and performant,
avoiding any hidden complexities or unexpected behaviors.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/aglushkov/diana>.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
