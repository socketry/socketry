---
name: socketry-pull-request
description: Prepare Socketry pull request titles, commits, and descriptions using the project conventions.
---

# Socketry Pull Request

Use this skill when preparing commits or pull requests for Socketry projects.

## Titles and Commits

- Pull request titles must use Markdown and end with a full stop.
- Pull request titles must be complete sentences.
- Commit messages must use Markdown and end with a full stop.
- Commit messages must not include agent links, attribution footers, generated-by annotations, or similar metadata.

## Pull Request Description

The pull request description should lead directly into a brief summary, followed by a detailed description of the problem and solution.

Do not add a `Types of Changes` section to the pull request description. Use GitHub issue type metadata for classification instead.

Use this structure, replacing the placeholder text with project-specific content:

```markdown
Briefly summarize the change in 1-3 sentences.

Describe the problem, context, and solution. Include implementation details that help reviewers understand the change. Link relevant issues if applicable. Include screenshots for aesthetic changes.
```

## Testing

Changes should include suitable test coverage. Aim for complete coverage of the behavior being changed or introduced.

Do not list passing test commands or verification steps in the pull request description unless they explain an unusual risk, limitation, or manual validation requirement.

### External Tests

If downstream dependencies are directly affected by the change, add them as external tests when useful. See the `bake-test-external` gem for details.

## Release Notes

If the change is user visible, add an `## Unreleased` release note which briefly describes the change.

## Issue Type

Set the GitHub issue type correctly when creating or updating a pull request:

- Use `Bug` for defect fixes and regressions.
- Use `Feature` for new user-facing capabilities.
- Use `Task` for maintenance, refactoring, documentation, tests, release work, and internal improvements.
