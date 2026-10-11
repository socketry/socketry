# Conventions

This guide explains how to structure Ruby code with clear responsibilities, explicit operations, and readable control flow across Socketry projects.

## Construction and Operations

Keep `#initialize` limited to assigning supplied state, creating simple owned values, and cheap normalization. Callers should be able to construct an object without discovering dependencies, reading files, parsing documents, launching processes, or changing external state.

Give preparation and execution explicit entry points. Use names such as `.load`, `.parse`, `.discover`, `.prepare`, and `#install` to describe the work. A `.load(path)` factory can read a file, pass its contents to `.parse`, and construct an object from the parsed state. A prepared update can expose `#apply` and `#restore`. Introduce those phases when they give callers a useful boundary.

Keep derived values with the object that owns their inputs. Decide whether to compute them during an explicit preparation operation or when requested, based on cost and lifecycle. Make expensive work and external effects visible in the calling code.

## Responsibility and Dependencies

Choose objects around domain concepts and ownership of state. Give each parsing rule, validation rule, and file format one owner. Consumers such as renderers and installers should use that shared interpretation.

For example, a document owns Markdown and front matter interpretation. A skill definition applies skill-specific metadata rules. An installer selects destinations and changes files. An index orders documents and renders links. Generic document parsing belongs in a shared document abstraction used by both skills and indexing.

Use the parser library's syntax tree and source locations for syntax it already supports. Keep provider metadata separate from installation ownership and command-line presentation.

Keep task and command adapters small: translate arguments, call a library operation, and present its result. Put the workflow in the library so programmatic callers and commands share the same behavior.

## Readable Control Flow

Make a multi-step method read as a sequence of meaningful actions. Introduce each logical phase with a short comment explaining the behavior it implements. Keep the related statements together under that comment, and separate phases with blank lines. A phase can contain several calculations, assignments, or branches that readers need to understand together.

Use method documentation to explain the overall operation and its contract. Within the method, comments explain what each phase accomplishes, how it contributes to the operation, and any relevant ordering constraints or reasoning. Write comments introducing the following code with a trailing colon.

For example, this simplified scheduler accounting method keeps measurement and accumulation in readable groups:

```ruby
# Record the busy and idle time for this event loop iteration.
def record_load(start_time)
	# Measure the elapsed time and the portion spent waiting for events:
	elapsed = Async::Clock.now - start_time
	idle = @selector.idle_duration
	busy = elapsed - idle
	
	# Accumulate both durations for subsequent load reporting:
	@busy_time += busy
	@idle_time += idle
end
```

A method implementing a single step can usually be explained by its method documentation. This buffered-body operation is complete with its method comment:

```ruby
# Write a chunk to the buffered body.
def write(chunk)
	@chunks << chunk
end
```

Choose comment granularity by behavior: explain the purpose of a group of statements in domain terms. Method names explain the action, and local names explain the values passed between steps. Add an internal comment to a small method when it explains a detail beyond the method's contract.

Keep a cohesive sequence together when its shared state and ordering are easiest to follow locally. Extract a private method when it separates a distinct responsibility or gives an independently meaningful operation a useful name. Expand long argument lists, nested ternaries, and compound predicates when intermediate names improve readability. Prefer a few focused methods and existing objects; add an abstraction when it has concrete callers or owns a distinct invariant.

## Effects and Failure Boundaries

Validate inputs before changing externally visible state. When replacing generated files or directories, prepare the new contents and use a small, explicit replacement operation. Keep cleanup next to the effect it protects and document the scope that is restored on failure.

Distinguish missing optional input from invalid or unreadable input. Report failures with the relevant source or destination. Add recovery machinery in proportion to the actual operation and its documented guarantees; use the simplest design that meets them.

## Alignment Across Implementations

When Ruby and Rust implement the same feature, agree on the domain model, responsibilities, data flow, and observable behavior. Maintain a short mapping between their corresponding components and document intentional differences caused by the language or package ecosystem.

Use Ruby objects, modules, and enumeration idiomatically. Align the meaning of construction, parsing, discovery, and installation across languages while allowing their signatures and error mechanisms to fit each ecosystem.

Keep portable formats and behavioral rules in a shared specification. Use common fixtures to verify the contract, including representative invalid input and failure boundaries. Byte-for-byte comparisons are useful where exact preservation is part of the contract; semantic checks suit outputs whose formatting may vary.

## Architectural Changes

Before reorganizing a substantial feature, record its current responsibilities, the problem with those boundaries, the proposed data flow, and an incremental implementation sequence in a design document. Label proposed APIs and behavior clearly, then update the document as the implementation changes.

Promote general lessons into these shared conventions. Keep package-specific decisions in that package's design and context documentation. The [Configuration & Builder pattern](https://socketry.github.io/socketry/guides/pattern-configuration-and-builder/index) gives a concrete example of assigning configuration state, DSL evaluation, file loading, and freezing to explicit operations.
