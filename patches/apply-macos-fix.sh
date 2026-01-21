#!/bin/bash
#
# Patch: Make libsystemd Linux-only
#
# libsystemd is a Linux-only dependency. On macOS builds, this causes
# compilation failures. This patch moves it to a target-specific dependency
# so it's only included on Linux.
#
# Usage: ./patches/apply-macos-fix.sh
# Or use: task src:patch

set -e

CARGO_TOML=".src/crates/corrosion/Cargo.toml"

if [ ! -f "$CARGO_TOML" ]; then
    echo "Error: $CARGO_TOML not found. Run 'task src:clone' first."
    exit 1
fi

# Check if already patched
if grep -q "target.'cfg(target_os = \"linux\")'\.dependencies" "$CARGO_TOML"; then
    echo "Already patched."
    exit 0
fi

echo "Patching $CARGO_TOML for macOS compatibility..."

# Comment out the global libsystemd dependency
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/^libsystemd = "0.7.0"$/# libsystemd = "0.7.0"  # Moved to Linux-specific deps/' "$CARGO_TOML"
else
    sed -i 's/^libsystemd = "0.7.0"$/# libsystemd = "0.7.0"  # Moved to Linux-specific deps/' "$CARGO_TOML"
fi

# Add Linux-specific dependency section
cat >> "$CARGO_TOML" << 'EOF'

# Linux-only dependencies (added by patches/apply-macos-fix.sh)
[target.'cfg(target_os = "linux")'.dependencies]
libsystemd = "0.7.0"
EOF

echo "Patch applied successfully."
