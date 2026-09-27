# Getting Started

This guide explains how to use the `socketry` gem to support Socketry development by installing shared guidance and agent skills into your local project.

## Purpose

The `socketry` gem distributes conventions, design patterns, and reusable agent skills for developing and maintaining Socketry projects. It gives contributors and coding agents a common set of instructions for work such as implementing configuration DSLs, preparing pull requests, and maintaining GitHub repositories.

The guides are packaged as agent context, while task-specific instructions are packaged as skills. Use [`agent-context`](https://github.com/socketry/agent-context) and [`agent-skills`](https://github.com/socketry/agent-skills) to install them from the gem into your project.

## Installation

Add these gems to the maintenance group in your project's `gems.rb` or `Gemfile`:

```ruby
group :maintenance, optional: true do
	gem "socketry"
	gem "agent-context"
	gem "agent-skills"
end
```

Enable the group and install the gems from the project root:

```bash
bundle config set --local with maintenance
bundle install
```

## Install Agent Context

Install Socketry's guides locally:

```bash
bundle exec bake agent:context:install --gem socketry
```

This copies the guides into `.context/socketry/` and updates the context index in your project's `agents.md`. Agents can follow those links to read conventions such as [Pattern: Configuration & Builder](https://socketry.github.io/socketry/guides/pattern-configuration-and-builder/index).

To inspect the available context files:

```bash
bundle exec bake agent:context:list --gem socketry
```

## Install Agent Skills

Install Socketry's reusable workflows locally:

```bash
bundle exec bake agent:skills:install --gem socketry
```

This copies the skills into `.agents/skills/`, including `socketry-pull-request` and `socketry-github-repository`. Each skill has a `SKILL.md` describing when to use it and the instructions to follow.

To inspect the available skills:

```bash
bundle exec bake agent:skills:list --gem socketry
```

Omit `--gem socketry` from either installer to install the context or skills provided by all dependencies in the bundle.

## Update Local Guidance

After updating the gem, rerun both installers to refresh the local copies:

```bash
bundle update socketry
bundle exec bake agent:context:install --gem socketry
bundle exec bake agent:skills:install --gem socketry
```

Make changes to Socketry's guides and skills in this repository; installed copies are replaced when refreshed. The generated `.context/` and `.agents/` directories can be ignored in version control and recreated during local setup.
