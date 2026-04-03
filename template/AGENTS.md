# AGENTS.md

This file provides guidance to coding agents working in this repository.

See @README.md for a project overview.

## Quick Reference

```
cargo build        # Build
cargo test         # Run tests
cargo clippy       # Lint
cargo fmt --check  # Check formatting
cargo run -- --version
```

## Conventions

- All dependencies are pinned to exact versions. Dependabot handles upgrades.
- Run `cargo fmt` and `cargo clippy --fix` before committing.
- Prefer `anyhow::Result` for error handling with `.context()` for human-readable messages.
- Do not bump the version unless directly instructed.
