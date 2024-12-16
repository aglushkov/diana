# Diana - Lazy Dependency Injection

## Features

- Lazy by nature, each dependency will be lazily initialized when firstly
  accessed
- Works anywhere - custom classes, sidekiq jobs or Rails controllers
- Works in nested classed
- No DI container. (But you can use any container you have if you want)
- Supported ruby versions - *(2.6 .. 3.3), head, jruby-9.4, truffleruby-24*

## Installation

```bash
bundle add diana
```

## Usage

- Diana module has main method `.dependencies` to define dependencies
- It has also alias `.dependency` if you like it more.
- Dependencies are automatically resolved when firstly accessed.
- You can provide your own resolver.

Example 1. Basic usage:

```ruby
  class MyClass
    # Declare your named dependencies
    include Diana.dependencies(
      foo: proc { Foo.new },
      bar: proc { Bar.new }
    )

    # Use them by names
    def my_method
      foo
      bar
    end
  end

  # Overwrite them during initialization
  MyClass.new(foo: FooFoo.new)
```

Example 2. Dependencies can be safely included in a class with custom initializer:

```ruby
  class MyClass
    include Diana.dependencies(foo: proc { Foo.new })

    def initialize(arg, kwarg:)
      @arg = arg
      @kwarg = kwarg
    end
  end

  MyClass.new(arg, kwarg: kwarg, foo: FooFooFoo.new)
```

Example 3. Dependencies are inherited:

```ruby
  class MyClass
    include Diana.dependencies(foo: proc { Foo.new })
  end

  class MyChildClass < MyClass
    include Diana.dependencies(bar: proc { Bar.new })
  end

  # MyChildClass now has `#foo` and `#bar` methods
  MyChildClass.new.foo
  MyChildClass.new.bar
```

Example 4. Custom resolver:

```ruby
  # Default resolver resolves only procs, it looks like this,:
  #
  # proc do |dependency|
  #   dependency.is_a?(Proc) ? dependency.call : dependency
  # end

  # Add custom resolver in some app initialize file
  Diana.resolver = proc do |dependency|
    case dependency
    when Proc
      # Same as default for Proc
      dependency.call
    when String
      # Use DI container when string provided
      DI_CONTAINER[dependency].call
    when Class then
      # Initializes class when resolving dependency by class name
      # (unless class responds to .call)
      dependency.respond_to?(:call) ? dependency : dependency.new
    else
      # fallback to original dependency value other vice (same as default)
      dependency
    end
  end

  # in business logic
  class MyClass
    include Diana.dependencies(
      foo: proc { Foo.new } # resolves to Foo.new
      bar: 'utils.bar'      # resolves to DI_CONTAINER['utils.bar'].call
      bazz: Bazz            # resolves to Bazz or Bazz.new
      forty_two: 42         # resolves to 42
    )
  end
```

## How it works

1) We register dependencies in a class instance variable `@_diana_dependencies`
2) We add instance methods with dependencies names to access this dependencies.
3) When they accessed first time we resolve dependency using current
   dependency resolver, save value in instance variable by dependency
   name, and return this value.
4) We overwrite class `.new` method to save manually provided dependencies to
   instance variables, as custom dependencies should not be resolved.
   And we remove this arguments, so `#initialize` method is called already
   without extra arguments.

For example adding `MyClass.dependency(foo: proc { 42 })`:

- Adds `MyClass @_diana_dependencies = { foo: proc { 42 } }` class instance
  variable
- Adds `MyClass#foo` instance method
- Adds `@foo` instance variable when `#foo` method firstly invoked
- Does not propagate `:foo` keyword to `#initialize` method when calling
  `MyClass.new(foo: 123)`. Just directly assigns `123` to `@foo` before calling
  `#initialize`

## Restrictions to be safe:

- Do not add methods with same names as dependencies names,
  they are already defined.
- Do not add custom instance variables with sames names as dependencies names,
  they will be used/set when accessing dependencies.
- Do not add keyword arguments to `#initialize` method with same names as
  dependencies names. We remove such keyword arguments, so you can get
  ArgumentError (missing keyword).

## Usage in tests

Overwrite your dependencies in an initializer or stub dependencies public
methods.

```ruby
  # Overwrite dependencies
  let(:service) { described_class.new(my_cache: cache_double, my_job: job_double) }

  # Or stub dependencies public methods
  let(:service) { described_class.new }

  before do
    allow(service.my_cache).to receive(:fetch)
    allow(service.my_job).to receive(:perform_async)
  end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/agkushkov/diana.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
