# Socketry

Socketry project metadata, agent context, and skills.

[![Development Status](https://github.com/socketry/socketry/workflows/Test/badge.svg)](https://github.com/socketry/socketry/actions?workflow=Test)

## Agent Context

This gem distributes project conventions in the top-level `context/` directory:

  - [Configuration and Builder](context/configuration.md) defines the mutable configuration and builder design for Ruby configuration DSLs.

Projects that include `socketry` and [`agent-context`](https://github.com/socketry/agent-context) can install the context and update their `agents.md` index with:

``` bash
bundle exec bake agent:context:install --gem socketry
```

## Agent Skills

This gem provides reusable agent skills in the top-level `skills/` directory. Use [`agent-skills`](https://github.com/socketry/agent-skills) to discover and install them into a project.

## Releases

Please see the [project releases](https://github.com/socketry/socketryreleases/index) for all releases.

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
