# ADR-002: Raspberry Pi Support for Corrosion

## Status

**Supported** - Raspberry Pi Zero 2 W and newer ARM64 models can run Corrosion using the existing `linux-arm64` target.

## Context

Users want to deploy Corrosion on Raspberry Pi devices for edge computing, IoT, and local development scenarios. The Raspberry Pi Zero 2 W is of particular interest due to its small form factor and low power consumption.

## Decision Drivers

- Edge deployment on low-power ARM devices
- IoT and embedded use cases
- Cost-effective distributed SQLite nodes
- Developer experience for local testing

## Analysis

### Raspberry Pi Model Compatibility

| Model | CPU | Architecture | 64-bit OS | Status |
|-------|-----|--------------|-----------|--------|
| Pi Zero 2 W | Cortex-A53 (BCM2710A1) | ARMv8 | ✅ Yes | ✅ **Supported** |
| Pi 3 Model B/B+ | Cortex-A53 | ARMv8 | ✅ Yes | ✅ **Supported** |
| Pi 4 Model B | Cortex-A72 | ARMv8 | ✅ Yes | ✅ **Supported** |
| Pi 5 | Cortex-A76 | ARMv8 | ✅ Yes | ✅ **Supported** |
| Pi Zero W (original) | ARM1176JZF-S | ARMv6 | ❌ No | ❌ Not Supported |
| Pi 1/2 | ARM11/Cortex-A7 | ARMv6/ARMv7 | ❌ No | ❌ Not Supported |

### Requirements

1. **64-bit Raspberry Pi OS** - Must use the 64-bit variant (not 32-bit)
2. **ARM64 target** - Uses existing `aarch64-unknown-linux-gnu` target
3. **Sufficient resources** - See hardware considerations below

### Build Target

- **Rust Target**: `aarch64-unknown-linux-gnu`
- **Binary Output**: `.bin/linux-arm64/corrosion`
- **Release Artifact**: `corrosion-linux-arm64.tar.gz`

## Decision

**Option B: Cross-compile from macOS/Linux Host** - This is the REQUIRED approach.

### Required Build Process

**Approach**: Build on a more powerful machine, deploy binary to Pi.

**Steps**:
```bash
# On host machine (macOS or Linux)
task rust:setup:cross           # One-time setup
task rust:build:linux:cross:arm64

# Copy to Pi
scp .bin/linux-arm64/corrosion pi@raspberrypi:/usr/local/bin/
```

**Why this is required**:
- Fast compilation on powerful host machine
- Can build latest source with any modifications
- Iterative development workflow
- Consistent, reproducible builds
- CI/CD uses the same cross-compilation approach

**Requirements**:
- Docker installed on host machine
- Task (taskfile.dev) installed
- One-time setup: `task rust:setup:cross`

## Alternative Options (Not Recommended)

### Option A: Download Pre-built Binary

**Approach**: Use the existing `linux-arm64` release binary.

**Steps**:
1. Download `corrosion-linux-arm64.tar.gz` from GitHub Releases
2. Extract and run on Raspberry Pi with 64-bit OS

**Why not recommended**:
- Dependent on release schedule
- Cannot include local modifications
- Less control over build configuration

### Option C: Native Build on Raspberry Pi

**Approach**: Compile directly on the Raspberry Pi.

**Why NOT supported**:
- Very slow on Pi Zero 2 W (limited CPU/RAM)
- Requires swap space configuration
- May take hours to compile
- Resource-constrained environment leads to build failures

## Hardware Considerations

### Raspberry Pi Zero 2 W Specs

| Resource | Value | Consideration |
|----------|-------|---------------|
| CPU | 4x Cortex-A53 @ 1GHz | Adequate for running Corrosion |
| RAM | 512MB | **Tight** - may need swap for heavy workloads |
| Storage | microSD | Use fast card (A2 rated) |
| Network | 2.4GHz WiFi | Consider USB Ethernet for reliability |

### Recommendations for Pi Zero 2 W

1. **Add swap space** (2GB recommended):
   ```bash
   sudo dphys-swapfile swapoff
   sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

2. **Use lightweight 64-bit OS** - Raspberry Pi OS Lite (64-bit)

3. **Monitor memory usage** - Corrosion + SQLite may consume significant RAM

4. **Consider Pi 4/5 for production** - More RAM and CPU headroom

## Implementation Plan

### Phase 1: Verify Cross-Compilation Support (Complete)

- [x] Confirm `linux-arm64` target works via cross-compilation
- [x] Verify CI builds ARM64 binaries using cross
- [x] Document Option B as required approach in ADR

### Phase 2: Testing (UTM Virtual Machine or Physical Hardware)

**Option A: UTM Virtual Machine (No Physical Pi Required)**

Use [goup-util](https://github.com/joeblew999/goup-util) UTM support to test in an ARM64 Linux VM:

```bash
# Install UTM and download Debian ARM64 ISO (smallest - 700MB)
cd /path/to/goup-util
go run . utm install                 # Install UTM.app
go run . utm install debian-13-arm   # Download ISO

# Check paths
go run . utm paths
# App:   ~/goup-util-sdks/utm/UTM.app
# VMs:   ~/goup-util-sdks/utm/vms
# ISO:   ~/goup-util-sdks/utm/iso
# Share: ~/goup-util-sdks/utm/share

# Create VM in UTM UI
open ~/goup-util-sdks/utm/UTM.app
# 1. Click + → Virtualize → Linux
# 2. Select ~/goup-util-sdks/utm/iso/debian-13-arm64.iso
# 3. RAM: 2048 MB, CPU: 2, Disk: 20GB
# 4. Enable shared directory: ~/goup-util-sdks/utm/share/debian-13-arm

# Copy binary to VM's share folder
mkdir -p ~/goup-util-sdks/utm/share/debian-13-arm
cp /path/to/binary-corrosion/.bin/linux-arm64/corrosion ~/goup-util-sdks/utm/share/debian-13-arm/

# In the Debian VM, test the binary
/mnt/share/corrosion --help
```

**Option B: Physical Raspberry Pi**

- [ ] Cross-compile and deploy to Raspberry Pi Zero 2 W
- [ ] Verify binary runs on 64-bit Raspberry Pi OS
- [ ] Measure memory usage and performance
- [ ] Document any Pi-specific configuration needed

### Phase 3: Documentation

- [ ] Add Raspberry Pi section to README
- [ ] Create `docs/RASPBERRY_PI.md` deployment guide (cross-compile workflow)
- [ ] Add example systemd service file for Pi

### Phase 4: Optimization (If Needed)

- [ ] Profile memory usage on constrained devices
- [ ] Consider `musl` static build for smaller binary
- [ ] Evaluate `jemalloc` vs system allocator on ARM

## Deployment Example

### Cross-compile and Deploy (Required Method)

```bash
# On host machine (macOS or Linux)
task rust:setup:cross                # One-time setup
task rust:build:linux:cross:arm64    # Build for ARM64

# Deploy to Pi
scp .bin/linux-arm64/corrosion pi@raspberrypi:/usr/local/bin/

# On Raspberry Pi - verify
ssh pi@raspberrypi '/usr/local/bin/corrosion --help'
```

### Systemd Service (Optional)

```ini
# /etc/systemd/system/corrosion.service
[Unit]
Description=Corrosion - Distributed SQLite
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/corrosion agent
Restart=on-failure
User=corrosion

[Install]
WantedBy=multi-user.target
```

## Consequences

### Benefits

- Enables edge deployment on low-cost ARM devices
- Distributed SQLite at the edge becomes feasible
- Cross-compilation provides fast, reproducible builds
- Same toolchain as CI/CD ensures consistency

### Limitations

- 32-bit Raspberry Pi models not supported
- Pi Zero 2 W has limited resources (512MB RAM)
- Native compilation on Pi is NOT supported
- Requires Docker on host machine for cross-compilation
- UTM testing requires macOS with Apple Silicon or Intel (for ARM64 emulation)

### Trade-offs

- ARM64 requirement excludes older Pi models
- Cross-compilation requires initial setup overhead
- May need to tune for memory-constrained environments

## References

- [Raspberry Pi Zero 2 W Specifications](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)
- [Raspberry Pi OS 64-bit](https://www.raspberrypi.com/software/operating-systems/)
- [Rust cross-compilation](https://rust-lang.github.io/rustup/cross-compilation.html)
- [Cross tool](https://github.com/cross-rs/cross)
- [goup-util UTM support](https://github.com/joeblew999/goup-util) - ARM64 Linux VM testing without physical hardware
- [UTM - Virtual machines for Mac](https://mac.getutm.app/)
