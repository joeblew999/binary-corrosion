# Corrosion Build Wrapper

Build automation for [Corrosion](https://github.com/superfly/corrosion) - a distributed SQLite replication system from Fly.io.

corrosion uses SQLite under the hood with CRDTs (cr-sqlite) for replication.

## Prerequisites

- [Task](https://taskfile.dev)
- [Rust](https://rustup.rs) (1.88+)
- Docker (for cross-compilation)

## Quick Start

```bash
# Build for current platform
task build

# Run locally
task run

# List all tasks
task --list
```

## Cross-Compilation (from macOS)

```bash
# Install cross tool
task rust:setup:cross

# Build for Linux
task rust:build:linux:cross
```

Outputs to `.bin/linux-amd64/` and `.bin/linux-arm64/`.

Note: Windows builds are unsupported (upstream uses Unix-only signal handling).

## Links

- Upstream: https://github.com/superfly/corrosion
- Docs: https://superfly.github.io/corrosion/
- Blog: https://fly.io/blog/corrosion/
