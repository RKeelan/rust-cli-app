# {{ project-name }}

[![CI](https://github.com/{{ github_username }}/{{ project-name }}/actions/workflows/ci.yml/badge.svg)](https://github.com/{{ github_username }}/{{ project-name }}/actions/workflows/ci.yml)
{%- if publish_to_crates_io %}
[![Crates.io](https://img.shields.io/crates/v/{{ project-name }})](https://crates.io/crates/{{ project-name }})
{%- endif %}

{{ description }}

## Development

```bash
cargo build        # Build
cargo test         # Run tests
cargo clippy       # Lint
cargo fmt --check  # Check formatting
cargo run -- --version
```
