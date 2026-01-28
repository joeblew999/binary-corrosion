# ADR-001: Windows Support for Corrosion

## Status

**Implemented** - Windows AMD64 working in fork (joeblew999/corrosion). ARM64 remains blocked by ring crate.

## Context

Corrosion is built for Unix systems (Linux, macOS). Windows support would enable additional use cases such as local development on Windows machines and edge deployments on Windows servers.

The upstream project (superfly/corrosion) does not currently support Windows.

## Decision Drivers

- Developer experience on Windows workstations
- Edge deployment flexibility
- Maintenance burden of maintaining a fork
- Upstream acceptance likelihood

## Analysis

### Blockers Identified

| Category | Issue | Crates Affected | Complexity | Status |
|----------|-------|-----------------|------------|--------|
| **Signal Handling** | `tokio::signal::unix` API | tripwire | High | ✅ Fixed |
| **Signal Constants** | SIGTERM/SIGINT don't exist | tripwire, spawn | High | ✅ Fixed |
| **Unix File APIs** | `AsRawFd`, `FileExt`, `fcntl`, `flock` | sqlite3-restore | Medium | ✅ Fixed |
| **nix Crate** | Unix system calls library | sqlite3-restore | Medium | ✅ Fixed |
| **Systemd** | Linux-only service integration | corrosion | Low (already conditional) | ✅ N/A |
| **ring 0.16.x** | C code doesn't compile for ARM64 | TLS/crypto | N/A | ❌ Blocks ARM64 |
| **jemalloc** | Doesn't compile on Windows | corrosion | Low | ✅ Fixed (made Unix-only) |
| **cr-sqlite** | No Windows DLL included | corro-types | Medium | ✅ Fixed (added DLL) |
| **libgit2-sys** | Missing Windows library links | build-info | High | ✅ Fixed (added advapi32, crypt32, winhttp, rpcrt4, ole32, secur32) |
| **Unix Sockets** | UnixListener/UnixStream not available | corro-admin | High | ✅ Fixed (TCP on Windows, Unix sockets on Unix) |
| **defmt** | Embedded logging doesn't work on Windows | uhlc | Low | ✅ Fixed (removed defmt feature) |

### Detailed Breakdown

#### 1. Tripwire Crate (Critical Path)

The tripwire crate provides graceful shutdown signaling throughout Corrosion.

**Current code** (`.src/crates/tripwire/src/tripwire.rs`):
```rust
use tokio::signal::unix::{signal, SignalKind};

pub fn new_signals() -> (Self, TripwireWorker<...>) {
    let sigterms = SignalStream::new(signal(SignalKind::terminate()).unwrap());
    let sigints = SignalStream::new(signal(SignalKind::interrupt()).unwrap());
    Self::new(select(sigterms, sigints))
}
```

**Required change**: Abstract with `#[cfg(unix)]` / `#[cfg(windows)]`:
```rust
#[cfg(unix)]
pub fn new_signals() -> (Self, TripwireWorker<...>) {
    use tokio::signal::unix::{signal, SignalKind};
    let sigterms = SignalStream::new(signal(SignalKind::terminate()).unwrap());
    let sigints = SignalStream::new(signal(SignalKind::interrupt()).unwrap());
    Self::new(select(sigterms, sigints))
}

#[cfg(windows)]
pub fn new_signals() -> (Self, TripwireWorker<impl Stream<Item = ()>>) {
    use tokio::signal::windows;
    // Windows uses Ctrl-C and Ctrl-Break instead of SIGTERM/SIGINT
    let ctrl_c = CtrlCStream::new(windows::ctrl_c().unwrap());
    let ctrl_break = CtrlBreakStream::new(windows::ctrl_break().unwrap());
    Self::new(select(ctrl_c, ctrl_break))
}
```

#### 2. SignalStream Wrapper

**Current code** (`.src/crates/tripwire/src/signalstream.rs`):
```rust
use tokio::signal::unix::Signal;

pub struct SignalStream {
    inner: Signal,
}
```

**Required change**: Platform-specific stream types or a trait abstraction.

#### 3. Sqlite3-restore Crate (File Locking)

**Current code** (`.src/crates/sqlite3-restore/src/lib.rs`):
```rust
use std::os::{fd::AsRawFd, unix::prelude::FileExt};
use nix::{fcntl::{fcntl, FcntlArg}, libc::{flock, SEEK_SET}};
```

**Required change**: Use `fs2` crate or Windows-specific file locking APIs:
```rust
#[cfg(unix)]
use std::os::unix::prelude::FileExt;

#[cfg(windows)]
use std::os::windows::prelude::FileExt;

// For locking, use cross-platform crate like fs2
use fs2::FileExt as LockExt;
```

#### 4. Spawn Crate (Debug Signals)

Already conditionally compiled with `#[cfg(all(unix, debug_assertions))]`. Would need equivalent Windows debug handling or skip entirely on Windows.

## Options

### Option A: Fork and Maintain Patches

**Approach**: Create and maintain patches in this repository.

**Pros**:
- Full control over implementation
- Can ship Windows binaries immediately after patches work
- No dependency on upstream timeline

**Cons**:
- Ongoing maintenance burden
- Patches may break on upstream updates
- Divergence from upstream

**Effort**: ~40-60 hours initial, ongoing maintenance

### Option B: Upstream PR

**Approach**: Submit cross-platform patches to superfly/corrosion.

**Pros**:
- No fork maintenance
- Benefits entire community
- Upstream testing and review

**Cons**:
- Dependent on upstream interest and review timeline
- May require negotiation on implementation approach
- Fly.io may not prioritize Windows (server-focused)

**Effort**: ~40-60 hours initial + review cycles

### Option C: WSL2 Workaround

**Approach**: Document using Linux binaries under WSL2.

**Pros**:
- Works today with no code changes
- Zero maintenance
- Full compatibility

**Cons**:
- Requires WSL2 setup on Windows
- Not a native Windows experience
- May have networking complexity

**Effort**: ~2-4 hours documentation

### Option D: Hybrid Approach

**Approach**:
1. Document WSL2 as immediate solution
2. Create patches locally for testing
3. Submit upstream PR
4. Fall back to maintained fork if upstream declines

**Pros**:
- Immediate solution available
- Best long-term outcome if upstream accepts
- Fallback if they don't

**Cons**:
- Most effort upfront
- May duplicate work

## Recommendation

**Option D (Hybrid)** is recommended:

1. **Immediate**: Create `docs/WINDOWS.md` with WSL2 instructions
2. **Short-term**: Develop Windows patches in `patches/` directory
3. **Medium-term**: Submit upstream PR to superfly/corrosion
4. **Fallback**: Maintain fork if upstream declines

## Implementation Plan

### Phase 1: WSL2 Documentation (1-2 hours)
- Create `docs/WINDOWS.md` with WSL2 setup guide
- Update README to mention Windows/WSL2 option

### Phase 2: Patch Development (40-60 hours)
- [ ] Create `patches/windows-signal-handling.patch` for tripwire crate
- [ ] Create `patches/windows-file-locking.patch` for sqlite3-restore crate
- [ ] Add Windows cross-compilation to Taskfile
- [ ] Test on Windows (native or CI)

### Phase 3: Upstream Contribution
- [ ] Open issue on superfly/corrosion discussing Windows support
- [ ] Submit PR with cross-platform changes
- [ ] Iterate based on feedback

### Phase 4: CI/CD (if maintaining fork)
- [ ] Add Windows to GitHub Actions matrix
- [ ] Add Windows binaries to releases

## Files Requiring Changes

| File | Change Type | Priority |
|------|-------------|----------|
| `.src/crates/tripwire/src/tripwire.rs` | Signal handling abstraction | Critical |
| `.src/crates/tripwire/src/signalstream.rs` | Stream type abstraction | Critical |
| `.src/crates/tripwire/Cargo.toml` | Add Windows signal deps | Critical |
| `.src/crates/sqlite3-restore/src/lib.rs` | File locking abstraction | High |
| `.src/crates/sqlite3-restore/Cargo.toml` | Add fs2 or Windows deps | High |
| `.src/crates/spawn/src/lib.rs` | Windows debug handling | Low |
| `.src/crates/corro-types/src/sqlite.rs` | Add Windows SQLite binary | Medium |

## Consequences

### If Accepted
- Windows developers can run Corrosion natively
- Increased maintenance if upstream doesn't accept
- Need Windows CI infrastructure

### If Rejected
- WSL2 remains the Windows solution
- No additional maintenance burden
- Some users may be disappointed

## References

- [tokio::signal::windows](https://docs.rs/tokio/latest/tokio/signal/windows/index.html)
- [fs2 crate](https://docs.rs/fs2/latest/fs2/) - Cross-platform file locking
- [Upstream Corrosion](https://github.com/superfly/corrosion)
