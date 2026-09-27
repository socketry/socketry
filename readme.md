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

Releases use [`bake-gem-github`](https://github.com/socketry/bake-gem-github). With Ruby 3.3 or later, install maintenance dependencies before preparing a release:

``` bash
bundle config set --local with maintenance
bundle install
```

Add release notes under `Unreleased` in `releases.md`. From a clean, up-to-date `main`, prepare a release pull request:

``` bash
bundle exec bake gem:github:release:patch # or minor or major
```

The release hook versions the notes. GitHub validates the release changes, then publishes the merged release to RubyGems using Trusted Publishing.

Publishing uses the `rubygems` GitHub environment, restricted to `main`. For initial activation, register a RubyGems Trusted Publisher for `socketry/socketry`, workflow `release-publish.yaml`, environment `rubygems`. After merging the setup and confirming the `Gem build` and `Release validation` checks run, review and apply the repository policy:

``` bash
bundle exec bake gem:github:setup:plan
bundle exec bake gem:github:setup:apply
```

The policy requires two PR approvals with administrator bypass. See the [release setup guide](https://socketry.github.io/bake-gem-github/guides/getting-started/index) for configuration and recovery.
