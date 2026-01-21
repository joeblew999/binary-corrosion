# Corrosion Fly.io Deployment Dockerfile
#
# ============================================================================
# BUILD OPTIONS
# ============================================================================
#
# Option 1: Build from source (default)
#   - Uses the Rust source in .src/ (from task src:clone)
#   - Slower but always up-to-date
#   - Requires: task src:clone before docker build
#
# Option 2: Use pre-built binary
#   - Faster deployment using locally cross-compiled binary
#   - Requires: task rust:build:linux:cross:amd64
#   - To use: Comment out builder stage, uncomment COPY .bin/... line
#
# ============================================================================
# WHY THESE CHOICES
# ============================================================================
#
# - rust:bookworm: Debian-based for compatibility with mold linker
# - mold linker: 2-5x faster linking than default ld
# - debian:bookworm-slim: Minimal runtime, ~80MB smaller than full
# - sqlite3: Useful for debugging (fly ssh console -> sqlite3 /var/lib/...)
# - Non-root user: Security best practice
# - --mount=type=cache: Speeds up rebuilds by caching cargo/target
#
# ============================================================================

# ==============================================================================
# Builder stage - compile from source
# ==============================================================================
FROM rust:bookworm AS builder

# Build dependencies
# - clang/llvm: Required by some Rust crates (ring, etc.)
# - gcc-x86-64-linux-gnu: Cross-compilation support
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-x86-64-linux-gnu \
    clang \
    llvm \
    && rm -rf /var/lib/apt/lists/*

# Install mold linker - significantly faster than ld
ENV MOLD_VERSION=2.4.0
RUN set -eux; \
    curl --fail --location "https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-x86_64-linux.tar.gz" --output /tmp/mold.tar.gz; \
    tar --directory "/usr/local" -xzvf "/tmp/mold.tar.gz" --strip-components 1; \
    rm /tmp/mold.tar.gz; \
    mold --version

WORKDIR /usr/src/app

# Copy source - assumes .src/ exists from: task src:clone
COPY .src/ .

# Build release binary with cargo caching
# Cache mounts speed up subsequent builds significantly
RUN --mount=type=cache,target=/usr/local/cargo,from=rust:bookworm,source=/usr/local/cargo \
    --mount=type=cache,target=target \
    cargo build --release && mv target/release/corrosion ./

# ==============================================================================
# Runtime stage - minimal production image
# ==============================================================================
FROM debian:bookworm-slim

# Runtime dependencies only
# - sqlite3: Debugging tool (sqlite3 /var/lib/corrosion/state.db)
# - ca-certificates: HTTPS support
RUN apt-get update && apt-get install -y \
    sqlite3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder stage
COPY --from=builder /usr/src/app/corrosion /usr/local/bin/corrosion

# Alternative: Use pre-built binary from local cross-compilation
# Uncomment this and comment out the builder stage above for faster deploys
# Requires: task rust:build:linux:cross:amd64
# COPY .bin/linux-amd64/corrosion /usr/local/bin/corrosion

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
