#!/bin/bash
#
# Corrosion entrypoint script for Fly.io
#
# ============================================================================
# PURPOSE
# ============================================================================
#
# This script runs before corrosion starts to inject Fly.io-specific
# configuration that can't be known until runtime:
#
#   1. FLY_PRIVATE_IP - The node's private IPv6 address
#   2. FLY_APP_NAME - Used to construct bootstrap DNS for cluster discovery
#
# ============================================================================
# HOW CLUSTER DISCOVERY WORKS
# ============================================================================
#
# When you deploy multiple corrosion nodes on Fly.io:
#
#   1. Each node gets a unique FLY_PRIVATE_IP (e.g., fdaa:0:...)
#   2. Fly.io DNS resolves ${APP_NAME}.internal to ALL node IPs
#   3. On startup, each node queries bootstrap DNS
#   4. Gossip protocol (SWIM) handles membership and state sync
#   5. New nodes automatically receive full database state
#
# Example: If app is "corrosion-demo" and you scale to 3 nodes:
#   - corrosion-demo.internal resolves to all 3 IPv6 addresses
#   - Each node bootstraps by connecting to any available peer
#   - CRDT-based replication keeps all nodes in sync
#
# ============================================================================

set -e

# Inject Fly.io-specific gossip configuration
if [ -n "$FLY_PRIVATE_IP" ] && [ -n "$FLY_APP_NAME" ]; then
    echo "Configuring gossip for Fly.io..."
    echo "  Node IP: $FLY_PRIVATE_IP"
    echo "  Bootstrap DNS: ${FLY_APP_NAME}.internal:8787"

    # Insert gossip addr and bootstrap after [gossip] section header
    # sed finds [gossip] and appends the two config lines after it
    sed -i 's/\[gossip\]/&\naddr = "['${FLY_PRIVATE_IP}']:8787"\nbootstrap = ["'${FLY_APP_NAME}'.internal:8787"]/' /etc/corrosion/config.toml
else
    echo "Warning: FLY_PRIVATE_IP or FLY_APP_NAME not set"
    echo "  This is normal for local Docker testing"
    echo "  On Fly.io, these are set automatically"
fi

# Ensure data directory exists and has correct ownership
# (Fly volume is mounted here, but may be empty on first deploy)
mkdir -p /var/lib/corrosion
chown -R corrosion:corrosion /var/lib/corrosion /app

# Drop privileges and run corrosion as non-root user
# exec replaces this shell process with corrosion
exec su -s /bin/bash corrosion -c "exec $*"
