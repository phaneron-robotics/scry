# Contributing to Scry

Thanks for your interest in contributing. Scry is an open-source project
maintained by Phaneron Robotics, Inc.

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md) based on
the Contributor Covenant. By participating, you agree to uphold it.

## How to contribute

### Reporting bugs

Open an issue with:
- What you expected to happen
- What actually happened
- Steps to reproduce (minimum reproducer if possible)
- Your environment: ROS distro, OS, Scry version (`scry-connect --version`
  or app's About screen), AI provider

### Suggesting features

Open an issue tagged `enhancement` describing:
- The problem you're trying to solve
- Your proposed solution (or "I don't know yet, let's discuss")
- Alternatives you've considered

### Submitting changes

1. **Fork** the repository
2. **Create a branch** from `main`: `git checkout -b feat/your-feature`
3. **Make your changes** following the conventions below
4. **Test** locally: see each repo's README for test commands
5. **Commit** with a clear message (see commit-message style below)
6. **Push** to your fork
7. **Open a Pull Request** against `main`

PRs need to:
- Pass CI (lint + tests)
- Reference an issue if non-trivial
- Update docs if behaviour changes

### Commit message style

Use Conventional Commits:

```
feat: add fleet-query phone tool
fix: classify SSE timeout as retryable
docs: clarify ROS_DOMAIN_ID handling
refactor: split McpClient transport from RPC
test: cover the writes-skill drift detector
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`.

## Development setup

Each repo has its own README with setup instructions:

- [`scry-connect`](https://github.com/phaneron-robotics/scry-connect) —
  Python MCP server (runs on robots)
- [`scry-android`](https://github.com/phaneron-robotics/scry-android) —
  Kotlin/Compose Android app
- [`scry`](https://github.com/phaneron-robotics/scry) — umbrella project
  with architecture docs

## Licensing

By submitting a PR, you agree that your contributions will be licensed
under the [Apache License, Version 2.0](LICENSE), and that you have the
right to submit them.

## Maintainers

- **Deep Kotadiya** (@deep-zspace) — founder, primary maintainer

Issues + PRs are reviewed in the order they're received. Bear with us if
something takes a few days during release weeks.

## Questions

Open an issue tagged `question`, or email
[info@phaneronrobotics.com](mailto:info@phaneronrobotics.com).
