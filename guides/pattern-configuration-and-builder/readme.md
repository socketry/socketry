# Pattern: Configuration & Builder

This guide explains how to implement Ruby configuration DSLs with a mutable `Configuration` and a separate `Builder`, including file loading and explicit freezing.

## Design

Create the configuration first. Pass it to a builder, which applies the DSL to that same object. Return the configuration after evaluation, keeping it mutable.

- `Configuration` owns the configuration state, defaults, readers, and mutation methods. It can be configured directly through its public API.
- `Builder` provides the DSL and file-loading context. It changes the configuration through its public API. Use `Builder` as the standard name for this role, including when it loads files.
- `Configuration.build` evaluates a block through a builder and returns the configuration.
- `Configuration.load` loads files in order into one configuration and returns it.
- `Configuration#freeze` finalises the configuration when the caller chooses. `.build` and `.load` do not call it automatically.

The builder does not keep a second set of configuration values to transfer later. There is no final `Builder#build` step, `new(builder.attributes)` conversion, snapshot copying, or automatic freezing. Configuration readers belong on `Configuration`; the builder only needs its configuration reference and any DSL context such as a root directory.

Keep domain invariants in configuration mutation methods so they also apply to direct callers. The builder can translate convenient DSL arguments into those operations. Use ordinary writers for simple values and methods such as `add` for collections. A DSL method can have the same name as a configuration reader because they are on different objects.

## Example

The classes below share a project namespace. In a gem, they can live in separate `configuration.rb` and `builder.rb` files. `entry` and `concurrency` illustrate a collection and a scalar setting; use the project's own domain operations and defaults.

```ruby
# frozen_string_literal: true

module Example
	class Builder
		def initialize(configuration, root = Dir.pwd)
			@configuration = configuration
			@root = File.expand_path(root)
		end
		
		attr :root
		
		def entry(name, value)
			@configuration.add(name, value)
		end
		
		def concurrency(value)
			@configuration.concurrency = value
		end
		
		def self.load_file(configuration, path)
			path = File.realpath(path)
			builder = self.new(configuration, File.dirname(path))
			builder.instance_eval(File.read(path), path, 1)
		end
		
		def load_file(path)
			self.class.load_file(@configuration, File.expand_path(path, @root))
		end
	end
	
	class Configuration
		def self.build(root: Dir.pwd, &block)
			configuration = self.new
			builder = Builder.new(configuration, root)
			
			if block
				if block.arity.zero?
					builder.instance_eval(&block)
				else
					block.call(builder)
				end
			end
			
			return configuration
		end
		
		def self.load(paths)
			configuration = self.new
			Array(paths).each{|path| configuration.load_file(path)}
			return configuration
		end
		
		def initialize
			@entries = {}
			@concurrency = 1
		end
		
		attr :entries
		attr_accessor :concurrency
		
		def add(name, value)
			@entries[name.to_sym] = value
		end
		
		def load_file(path)
			Builder.load_file(self, path)
			return self
		end
		
		def freeze
			return self if frozen?
			
			@entries.freeze
			
			super
		end
	end
end
```

The DSL and direct API operate on the same mutable state:

```ruby
configuration = Example::Configuration.build do
	entry :primary, "https://example.com"
	concurrency 2
end

configuration.add(:secondary, "https://secondary.example.com")
configuration.concurrency = 4

Example::Configuration.build do |builder|
	builder.entry(:primary, "https://example.com")
end
```

The example allows an omitted block to return defaults. With a zero-arity block, `self` is the builder; with an explicit block argument, the caller's `self` is preserved. Both factories return the configuration regardless of the block's or file's last expression.

## Explicit Freezing

Implement `Configuration#freeze` to freeze the state owned by the configuration, then call `super` to freeze the configuration itself. Return `self` immediately when already frozen so repeated calls do not repeat finalisation. The same configuration object is returned; freezing does not construct a replacement.

The example owns the `entries` hash and freezes it in place. Its registered values are application-supplied objects retained by reference, so they remain untouched. Freeze owned nested configuration data as appropriate to its schema, but do not recursively freeze arbitrary handlers, policies, or other application objects. Freezing the outer object alone would still allow `add` to modify an unfrozen hash.

The caller decides when configuration is complete:

```ruby
configuration.freeze
```

After this call, `concurrency=` and `add` raise `FrozenError`, including when called through a builder attached to the configuration. References previously obtained from `configuration.entries` refer to the same frozen hash. Registered objects keep their own lifecycle and mutability.

If finalisation prepares derived state, do that before calling `super`. Runtime methods must not depend on assigning new instance variables after the configuration has been frozen.

## File Loading

Each file is evaluated by a new builder attached to the shared configuration. Its root is that file's directory. A nested `load_file "other.rb"` resolves against the calling builder's root and creates another builder for the referenced file. The original builder keeps its root throughout; no temporary root assignment or restoration is needed.

Resolve the file path before creating the builder, and pass the filename and starting line to `instance_eval` for useful source locations. Configuration files execute trusted application Ruby.

Multiple top-level files share one configuration. The example applies them in order, with later entries replacing earlier entries of the same name. Preserve the domain's duplicate and override rules when adapting the pattern. Evaluation errors propagate; mutations made before an error remain on an existing configuration. Loading is not transactional.

## Applying the Standard

Use this design for new configuration DSLs and when standardising existing ones. Preserve existing public names and entry points as compatibility wrappers where needed; an existing `Loader` can retain its name while the implementation moves to `Builder`. Keep runtime query methods and domain validation on the configuration.

Verify that block and file factories return the configured object, that it can still be changed through the direct API, and that builders for multiple files update that same object. Explicit freezing should return that object, tolerate repeated calls, and prevent changes to its owned state through writers, collection readers, or attached builders, while leaving application objects untouched. For nested files, check relative resolution, stable builder roots, and exception source locations.

## Established Examples

This design follows [Falcon's configuration/loader separation from June 2019](https://github.com/socketry/falcon/commit/438e04eb295400f0481d72b610a2f9c9ea062746), carried into [Async::Service in February 2024](https://github.com/socketry/async-service/commit/d2d717b7605d364df3a853e8a810aeab2bc36078). Async::Service's [configuration](https://github.com/socketry/async-service/blob/f32af00e5c7a54c936023b96f180710e811d410e/lib/async/service/configuration.rb) and [loader](https://github.com/socketry/async-service/blob/f32af00e5c7a54c936023b96f180710e811d410e/lib/async/service/loader.rb) illustrate the mutable state and per-file loading scopes. This standard uses the name `Builder` for that DSL role.
