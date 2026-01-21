# Corrosion Build Wrapper

This repository provides build automation for [Corrosion](https://github.com/superfly/corrosion) - a gossip-based service discovery tool from Fly.io.

https://fly.io/blog/corrosion/




## What is Corrosion?

Corrosion is a distributed SQLite replication system that:
- Maintains a SQLite database on each node
- Gossips local changes throughout the cluster
- Uses [CR-SQLite](https://github.com/vlcn-io/cr-sqlite) for conflict resolution with CRDTs
- Uses [Foca](https://github.com/caio/foca) to manage cluster membership using a SWIM protocol

## Building

### Prerequisites

- [Task](https://taskfile.dev) - Task runner
- [Rust](https://rustup.rs) - Rust toolchain (1.88+)
- Git

### Local Build (Current Platform)

```bash
# Clone source and build
task full

# Or step by step:
task clone
task build
```

The built binary will be in `bin/corrosion`.

### Build for Specific Platforms

```bash
# macOS ARM64 (Apple Silicon)
task build:macos-arm64

# macOS AMD64 (Intel) - requires cross-compilation setup
task build:macos-amd64

# Linux builds require cross-compilation tools or use GitHub Actions
```

### All Tasks

```bash
task --list
```

## Cross-Platform Builds

Cross-platform builds are handled by GitHub Actions. See `.github/workflows/build.yml`.

Supported platforms:
- `darwin-arm64` - macOS Apple Silicon
- `darwin-amd64` - macOS Intel
- `linux-amd64` - Linux x86_64
- `linux-arm64` - Linux ARM64

## Upstream

This is a build wrapper around the upstream project:
- Repository: https://github.com/superfly/corrosion
- Documentation: https://superfly.github.io/corrosion/

## License

Corrosion is licensed under the Apache 2.0 license. See the upstream repository for details.

## useful links

### RTT

https://rtt.fly.dev

https://rtt.fly.dev/to/s3

### s3 backed volumes

https://community.fly.io/t/bottomless-s3-backed-volumes/15648


