# Diana - Lazy Dependency Injection

## Features

- Lazy nature, each dependency will be lazily initialized only when accessed
- Work anywhere - custom classes, sidekiq jobs or Rails controllers
- Dependencies are injected in child classes also.
- No any new DSL to remember
- Supported ruby versions - *(2.6 .. 3.3), head, jruby-9.4, truffleruby-24*

## Installation

```bash
bundle add diana
```

## Usage

Declare your dependencies with named procs and use them:

```ruby
  class SomeClass
    # Declare your named dependencies
    include Diana.dependencies(
      foo: proc { Foo.new },
      bar: proc { Bar.new },
    )

    # Use them by names
    def some_method
      foo
      bar
    end
  end
```

Dependencies can be changed during initialization:

```ruby
  SomeClass.new(foo: FooFooFoo.new)
```

It will work if class has custom initializer:

```ruby
  class SomeClass
    include Diana.dependencies(foo: proc { Foo.new })

    def initialize(arg, kwarg:)
      @arg = arg
      @kwarg = kwarg
    end
  end

  SomeClass.new(arg, kwarg: kwarg, foo: FooFooFoo.new)
```

## Usage in tests

Just overwrite your dependencies in initializer or stub dependencies public
methods.

```ruby
  # Overwrite dependencies
  let(:service) { described_class.new(foo: other_foo, bar: other_bar) }

  # Or stub dependencies public methods
  let(:service) { described_class.new }

  before do
    allow(service.foo).to receive(:call)
    allow(service.bar).to receive(:perform)
  end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/agkushkov/diana.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
