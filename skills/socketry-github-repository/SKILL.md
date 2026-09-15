---
name: socketry-github-repository
description: Create and maintain Socketry GitHub repositories using the project conventions.
---

# Socketry GitHub Repository

Use this skill when creating or maintaining GitHub repositories for Socketry projects.

## Repository Metadata

Repository metadata should be concise, accurate, and consistent with the project purpose.

- Use the canonical GitHub organization and repository name for the project.
- Set a clear repository description that explains what the project provides.
- Set the homepage to the project documentation site when one exists.
- Add relevant topics that help discovery without duplicating words already present in the repository name.
- Prefer existing Socketry naming conventions over inventing new phrasing.

## Repository Setup

When creating a new repository, configure the repository so it is immediately useful to contributors and automation.

- Ensure the default branch is `main`.
- Enable `Issues`.
- Enable `Sponsorships`.
- Enable `Preserve this repository`.
- Enable `Discussions`.
- Enable `Pull Requests`.
- Disable `Projects`.
- Disable `Wiki`.

### Pull Requests

- Disable `Allow merge commits`.
- Enable `Allow squash merging`.
- Enable `Allow rebase merging`.
- Enable `Always suggest updating pull request branches`.
- Enable `Allow auto-merge`.
- Enable `Automatically delete head branches`.

### Commits

- Enable `Require contributors to sign off on web-based commits`.
- Enable `Allow comments on individual commits`.

## Issue Types

Use GitHub issue types to classify work:

- Use `Bug` for defect fixes and regressions.
- Use `Feature` for new user-facing capabilities.
- Use `Task` for maintenance, refactoring, documentation, tests, release work, and internal improvements.

Do not duplicate issue type information in issue or pull request body sections when GitHub metadata is available.

## Labels

Prefer existing repository and organization labels. Use labels for workflow and review state rather than repeating information already captured by issue type.

Do not create new labels unless the repository genuinely needs a reusable classification that is not already represented by existing labels or issue types.

## Branches and Protection

Repository protection should ensure changes to `main` are reviewed without blocking administrative maintenance.

- Protect the `main` branch.
- Require a pull request before merging into `main`.
- Require one approval before merging into `main`.
- Allow administrators to bypass the branch protection rules.
- Configure required status checks selectively so auto-merge works for normal pull requests.
- Require only stable status checks needed for safe auto-merge.
- Do not require experimental or informational checks.
- Do not require coverage checks unless the repository already reliably passes them.

## Maintenance

When maintaining an existing repository, make the smallest safe metadata or settings change needed.

- Inspect the current repository settings before changing them.
- Preserve deliberate project-specific settings.
- Do not rename, archive, transfer, or delete a repository without explicit user approval.
- Do not disable issues, pull requests, or required checks without explicit user approval.

## GitHub CLI

Use the GitHub CLI when making repository changes. Prefer explicit commands which show the target repository.

Before changing repository settings, confirm the target repository with:

```bash
gh repo view OWNER/REPOSITORY
```

When a command changes repository settings, use the full `OWNER/REPOSITORY` name rather than relying on the current directory.
