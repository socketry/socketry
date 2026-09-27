# Pattern: Gem Structure

This guide explains how to organise a Socketry gem, including its dependencies, library code, tests, configuration, documentation, and files maintained by `bake modernize`.

## Layout

A consistent layout helps contributors find the implementation, test a change, and understand what will be shipped to users. Use this structure when creating a gem or bringing an existing project into line with Socketry conventions.

The examples use a gem named `example` with the namespace `Example`. Substitute the project's own name, metadata, and supported Ruby versions. Create additional directories as the project needs them.

```text
example/
├── example.gemspec
├── gems.rb
├── lib/
│   ├── example.rb
│   └── example/
│       └── version.rb
├── test/
│   ├── example.rb
│   └── example/
├── config/
│   └── sus.rb
├── guides/
│   ├── links.yaml
│   └── getting-started/
│       └── readme.md
├── context/
│   ├── index.yaml
│   └── getting-started.md
├── bake.rb
├── readme.md
├── releases.md
├── license.md
├── .editorconfig
├── .gitignore
├── .rubocop.yml
└── .github/
    ├── copilot-instructions.md
    └── workflows/
```

## Gemspec

The root `example.gemspec` defines the package installed by users: its name, version, metadata, supported Ruby versions, runtime dependencies, and packaged files. It reads the version from the library's version file:

```ruby
# frozen_string_literal: true

require_relative "lib/example/version"

Gem::Specification.new do |spec|
	spec.name = "example"
	spec.version = Example::VERSION
	spec.summary = "An example Socketry library."
	spec.authors = ["Your Name"]
	spec.license = "MIT"
	spec.homepage = "https://github.com/your-org/example"
	
	spec.metadata = {
		"documentation_uri" => "https://your-org.github.io/example/",
		"source_code_uri" => "https://github.com/your-org/example.git",
		"changelog_uri" => "https://github.com/your-org/example/blob/main/releases.md",
	}
	
	spec.files = Dir.glob(["{context,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	spec.required_ruby_version = ">= 3.3"
end
```

Loading just the version file allows Bundler and RubyGems to evaluate the gemspec before the library's dependencies are installed. Keep that file independent of the rest of the library.

Declare dependencies needed by the library with `spec.add_dependency`, including appropriate version requirements. Development tools belong in `gems.rb`.

Maintain `spec.files` as the list of files users need. Include `context/` when distributing agent context, `skills/` when providing agent skills, `bake/` when exporting Bake tasks, and `bin/` or `ext/` when the gem provides executables or native extensions. Executables also need `spec.executables`; native extensions need `spec.extensions`. Keep local bundles, generated sites, test output, and other working files out of the package. See the [RubyGems specification reference](https://guides.rubygems.org/specification-reference/) for these fields.

## `gems.rb`

`gems.rb` is the Bundler manifest for working on the project. The `gemspec` directive includes the local gem and its runtime dependencies. Follow the layout used by `bake-modernize`: put the optional maintenance group before the test group, and separate related sets of tools with blank lines:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem-github"
	gem "bake-releases"
	
	gem "socketry"
	gem "agent-context"
	gem "agent-skills"
	
	gem "decode"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "bake-test"
end
```

Enable maintenance tools locally when needed:

```bash
bundle config set --local with maintenance
bundle install
```

Bundler writes the resolved dependencies to `gems.locked`. The standard `bake modernize` ignore rules leave this lockfile untracked for gem development. Runtime compatibility is expressed in the gemspec's dependency requirements; the local lockfile records the versions used in that checkout.

`bake modernize:gemfile` renames `Gemfile` to `gems.rb` and `Gemfile.lock` to `gems.locked`. Maintain one manifest. The [Getting Started guide](https://socketry.github.io/socketry/guides/getting-started/index) explains how to install the shared Socketry context and skills after installing these tools.

## Library Code and Version

Put library code under `lib/`, following the Ruby namespace. For example, `async-service` uses `lib/async/service.rb`, `lib/async/service/`, and the namespace `Async::Service`. Keep each file's required dependencies explicit so supported entry points can be loaded directly.

Define the version once in `lib/example/version.rb`. Start a new gem at `0.0.0` so the first version bump reflects the initial implementation:

```ruby
# frozen_string_literal: true

# @namespace
module Example
	VERSION = "0.0.0"
end
```

The public entry point, `lib/example.rb`, loads the version and the public components needed by callers:

```ruby
# frozen_string_literal: true

require_relative "example/version"
```

As the library grows, add its implementation files under `lib/example/` and require the appropriate files from the entry point. Consumers load the library with `require "example"`. The gemspec and callers both use the same `Example::VERSION` constant.

## Tests and Configuration

Place Sus tests under `test/`, mirroring the library paths. For example, tests for `lib/example/connection.rb` belong in `test/example/connection.rb`. Shared test data and contexts can live in `fixtures/`, which Sus adds to the load path.

A small `test/example.rb` checks that the public entry point loads and exposes a version:

```ruby
# frozen_string_literal: true

require "example"

describe Example do
	it "has a version number" do
		expect(Example::VERSION).to be =~ /\A\d+\.\d+\.\d+\z/
	end
end
```

Add tests for the library's behaviour alongside this initial check.

Use `config/` for project tooling configuration. `config/sus.rb` is loaded by Sus and can enable coverage:

```ruby
# frozen_string_literal: true

require "covered/sus"
include Covered::Sus
```

Other tools use their own files here when needed: `config/external.yaml` selects downstream projects for `bake-test-external`, and `config/release.yaml` records the GitHub release policy for `bake-gem-github`. These files configure development and maintenance workflows; the library's configuration API belongs with its code under `lib/`.

Run the suite and style checks from the project root:

```bash
bundle exec sus
bundle exec rubocop
```

`bundle exec bake test` runs the project's tests through `bake-test`, as used by the standard CI workflows.

## README and Guides

`readme.md` introduces the project with a short description, its purpose, and a path to useful documentation. Include usage, contributing, test, and release instructions. Socketry uses lowercase names for root Markdown files; `bake modernize` normalises these names and updates standard README sections and the test badge.

Write detailed documentation in `guides/<guide-name>/readme.md`, with ordering in `guides/links.yaml`. Set `documentation_uri` in the gemspec to the documentation site's base URL, including its trailing slash, so generated links resolve correctly.

Regenerate documentation metadata after editing guides:

```bash
bundle exec bake utopia:project:update
```

This updates the README's existing `Usage` and `Releases` sections and exports the guides into `context/` with an `index.yaml`. Commit those generated context files so the gem can distribute them. The `.context/` directory contains guidance installed from dependencies for local use.

Keep release notes in `releases.md`, adding changes under `## Unreleased`. `license.md` records the project's license and copyright information.

## Bake Tasks and Releases

`bake.rb` contains tasks and hooks for maintaining this project. For a gem using `bake-releases` and `utopia-project`, the release hook keeps notes and generated documentation aligned with the version:

```ruby
# frozen_string_literal: true

def after_gem_release_version_increment(version)
	context["releases:update"].call(version)
	context["utopia:project:update"].call
end
```

Tasks intended for other projects belong in namespaced files under `bake/` and must be included in `spec.files`. For example, `bake/example.rb` can provide `example:setup`. The root `bake.rb` is specific to the gem's own checkout.

Projects using `bake-gem-github` also have `config/release.yaml`, `.github/release-rules/`, and release preparation, validation, and publishing workflows. Its setup tasks generate those files separately from the default modernization. Follow the [bake-gem-github setup guide](https://socketry.github.io/bake-gem-github/guides/getting-started/index) to configure publishing and apply the GitHub rules.

## Files Maintained by `bake modernize`

`bake modernize` updates an existing gem's conventions. Start with the gemspec, version file, library entry point, and tests described above. Its tasks maintain these supporting files:

| File | Purpose |
| --- | --- |
| `.editorconfig` | Shared editor settings, including indentation and line endings. |
| `.gitignore` | Excludes local Bundler state, `gems.locked`, packaged gems, coverage data, installed skills, and other generated working files. |
| `.rubocop.yml` | Ruby and Markdown code style using `rubocop-socketry` and `rubocop-md`. |
| `.github/workflows/test.yaml` | Runs tests across the supported Ruby matrix. |
| `.github/workflows/rubocop.yaml` | Checks code style. |
| `.github/workflows/test-coverage.yaml` | Measures test coverage. |
| `.github/workflows/documentation-coverage.yaml` | Checks source documentation coverage with Decode. |
| `.github/workflows/documentation.yaml` | Builds and publishes the Utopia documentation site. |
| `.github/workflows/test-external.yaml` | Runs downstream tests when `config/external.yaml` exists. |
| `.github/copilot-instructions.md` | Provides repository instructions for GitHub Copilot. |
| `license.md` and source headers | Maintain licensing and contributor copyright information. |
| `releases.md`, `bake.rb`, and `readme.md` | Maintain release notes, release hooks, and contributor instructions. |
| `release.cert` | Public gem-signing certificate, copied when `~/.gem/release.cert` exists. The matching private key stays outside the repository. |

Modernization also rewrites the gemspec and updates tool dependencies. Review changes to the supported Ruby version, packaged files, dependency requirements, and existing customisations.

From a clean checkout with maintenance dependencies installed, list the tasks and review the generated changes:

```bash
bundle exec bake list modernize
bundle exec bake modernize
git diff
```

Some tasks install dependencies, inspect GitHub metadata, or merge existing files using a local Ollama service. Consult the [bake-modernize guide](https://socketry.github.io/bake-modernize/guides/getting-started/index) for setup and individual tasks. Run the project's tests and review the diff before committing.

GitHub releases are an explicit opt-in through `bake modernize:releases:github` and the subsequent `bake-gem-github` setup. When that dependency is already present, modernization maintains the corresponding release hooks and README instructions.
