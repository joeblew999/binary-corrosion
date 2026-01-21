# Corrosion Build Wrapper

Build automation for [Corrosion](https://github.com/superfly/corrosion) - a distributed SQLite replication system from Fly.io.

Corrosion uses SQLite under the hood with CRDTs (cr-sqlite) for replication.

## Releases

Pre-built binaries available at [GitHub Releases](https://github.com/joeblew999/binary-corrosion/releases).

| Platform | Download |
|----------|----------|
| Linux AMD64 | [corrosion-linux-amd64.tar.gz](https://github.com/joeblew999/binary-corrosion/releases/latest/download/corrosion-linux-amd64.tar.gz) |
| Linux ARM64 | [corrosion-linux-arm64.tar.gz](https://github.com/joeblew999/binary-corrosion/releases/latest/download/corrosion-linux-arm64.tar.gz) |
| macOS ARM64 | [corrosion-darwin-arm64.tar.gz](https://github.com/joeblew999/binary-corrosion/releases/latest/download/corrosion-darwin-arm64.tar.gz) |
| macOS AMD64 | [corrosion-darwin-amd64.tar.gz](https://github.com/joeblew999/binary-corrosion/releases/latest/download/corrosion-darwin-amd64.tar.gz) |

## Development

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
