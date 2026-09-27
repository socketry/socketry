# Socketry

Socketry project metadata, agent context, and skills.

[![Development Status](https://github.com/socketry/socketry/workflows/Test/badge.svg)](https://github.com/socketry/socketry/actions?workflow=Test)

## Usage

Please see the [project documentation](https://socketry.github.io/socketry/) for more details.

  - [Getting Started](https://socketry.github.io/socketry/guides/getting-started/index) - This guide explains how to use the `socketry` gem to support Socketry development by installing shared guidance and agent skills into your local project.

  - [Pattern: Gem Structure](https://socketry.github.io/socketry/guides/pattern-gem-structure/index) - This guide explains how to organise a Socketry gem, including its dependencies, library code, tests, configuration, documentation, and files maintained by `bake modernize`.

  - [Pattern: Configuration & Builder](https://socketry.github.io/socketry/guides/pattern-configuration-and-builder/index) - This guide explains how to implement Ruby configuration DSLs with a mutable `Configuration` and a separate `Builder`, including file loading and explicit freezing.

## Agent Context

The guides are also distributed as agent context in the top-level `context/` directory.

Projects that include `socketry` and [`agent-context`](https://github.com/socketry/agent-context) can install the context and update their `agents.md` index with:

``` bash
bundle exec bake agent:context:install --gem socketry
```

## Agent Skills

This gem provides reusable agent skills in the top-level `skills/` directory. Use [`agent-skills`](https://github.com/socketry/agent-skills) to discover and install them into a project.

## Releases

Please see the [project releases](https://socketry.github.io/socketry/releases/index) for all releases.

### Unreleased

  - Document the standard Socketry gem layout and files maintained by `bake modernize` in "Pattern: Gem Structure".
  - Add a Getting Started guide for installing Socketry's development context and agent skills locally.
  - Publish "Pattern: Configuration & Builder" as a documentation guide and generate its agent context as `pattern-configuration-and-builder.md`.

### v0.6.1

  - Distribute the mutable Configuration and Builder convention through `agent-context`.
  - Prepare reviewed releases and publish through GitHub Actions using `bake-gem-github`.

## Contributing

We welcome contributions to this project.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature.'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create a new pull request.

### Running Tests

To run the test suite:

``` bash
$ bundle exec sus
```

### Updating Documentation

Edit the source guides in `guides/`, then regenerate the README and distributed agent context:

``` bash
bundle exec bake utopia:project:update
```

### Making Releases

To make a new release:

``` bash
$ bundle exec bake gem:github:release:patch # or minor or major
```

See [bake-gem-github](https://github.com/socketry/bake-gem-github) for setup and release instructions.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
