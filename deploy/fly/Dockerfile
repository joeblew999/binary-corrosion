# Corrosion Fly.io Deployment Dockerfile
#
# ============================================================================
# PRE-REQUISITES
# ============================================================================
#
# Build the Linux binary before deploying:
#   task rust:build:linux:cross:amd64
#
# This will create .bin/linux-amd64/corrosion
#
# ============================================================================
# WHY THESE CHOICES
# ============================================================================
#
# - debian:bookworm-slim: Minimal runtime, ~80MB
# - sqlite3: Debugging (fly ssh console -> sqlite3 /var/lib/corrosion/state.db)
# - Non-root user: Security best practice
# - Pre-built binary: Fast deploys, no remote compilation
#
# ============================================================================

FROM debian:bookworm-slim

# Runtime dependencies only
# - sqlite3: Debugging tool (sqlite3 /var/lib/corrosion/state.db)
# - ca-certificates: HTTPS support
RUN apt-get update && apt-get install -y \
    sqlite3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy pre-built binary from local cross-compilation
# Requires: task rust:build:linux:cross:amd64
COPY .bin/linux-amd64/corrosion /usr/local/bin/corrosion
RUN chmod +x /usr/local/bin/corrosion

# Create non-root user for security
RUN useradd -ms /bin/bash corrosion

# Create required directories
# - /var/lib/corrosion: SQLite database (mounted as Fly volume)
# - /etc/corrosion: Configuration and schemas
# - /app: Admin socket location
RUN mkdir -p /var/lib/corrosion /etc/corrosion/schemas /app && \
    chown -R corrosion:corrosion /var/lib/corrosion /app

# Copy configuration files
COPY deploy/fly/config.toml /etc/corrosion/config.toml
COPY deploy/fly/schemas/ /etc/corrosion/schemas/
COPY deploy/fly/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Entrypoint injects Fly.io-specific config (gossip addr, bootstrap)
ENTRYPOINT ["/entrypoint.sh"]
CMD ["corrosion", "agent", "-c", "/etc/corrosion/config.toml"]
