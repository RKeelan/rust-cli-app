# rust-cli-app

[![Template Tests](https://github.com/RKeelan/rust-cli-app/actions/workflows/template-ci.yml/badge.svg)](https://github.com/RKeelan/rust-cli-app/actions/workflows/template-ci.yml)

A [cargo-generate](https://github.com/cargo-generate/cargo-generate) template for Rust CLI applications.

## Usage

```bash
cargo install cargo-generate
cargo generate gh:rkeelan/rust-cli-app template
```

## What you get

- `clap` (derive) for argument parsing, `anyhow` for error handling
- CI: `cargo fmt`, `clippy`, `build`, `test`, and `cargo-deny`
- Claude Code workflow (Sonnet + Opus)
- Dependabot (monthly, cargo + github-actions)
- MIT licence (optional)
- crates.io publishing workflow (optional)

## Prompts

- Project name (built-in)
- Description
- GitHub username (default: RKeelan)
- Open source / MIT licence? (default: true)
- Publish to crates.io? (default: false)

## Development

Run the template tests (requires `cargo-generate`):

```bash
./tests/test_template.sh
```
