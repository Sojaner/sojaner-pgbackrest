# Build stage
FROM ubuntu:22.04 AS builder

# Add version argument
ARG PGBACKREST_VERSION=2.55.0

# Install build dependencies
RUN apt-get update && apt-get install -y \
    rsync \
    git \
    devscripts \
    build-essential \
    valgrind \
    autoconf \
    autoconf-archive \
    libssl-dev \
    zlib1g-dev \
    libxml2-dev \
    libpq-dev \
    pkg-config \
    libxml-checker-perl \
    libyaml-perl \
    libdbd-pg-perl \
    liblz4-dev \
    liblz4-tool \
    zstd \
    libzstd-dev \
    bzip2 \
    libbz2-dev \
    libyaml-dev \
    ccache \
    python3-distutils \
    meson \
    && rm -rf /var/lib/apt/lists/*

# Clone and build pgBackRest
WORKDIR /build
RUN git clone https://github.com/pgbackrest/pgbackrest.git && \
    cd pgbackrest && \
    git checkout release/${PGBACKREST_VERSION}
WORKDIR /build/pgbackrest
RUN meson setup build
RUN meson compile -C build
RUN meson install -C build

# Production stage
FROM ubuntu:22.04

# Add version argument
ARG PGBACKREST_VERSION=2.55.0

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    zlib1g \
    libxml2 \
    libpq5 \
    liblz4-1 \
    zstd \
    bzip2 \
    libyaml-0-2 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from builder
COPY --from=builder /usr/local/bin/pgbackrest /usr/local/bin/

# Create necessary directories
RUN mkdir -p /var/log/pgbackrest /var/lib/pgbackrest

# Set environment variables
ENV PATH="/usr/local/bin:${PATH}"

# Create a non-root user
RUN useradd -r -m -U -d /var/lib/pgbackrest -s /bin/bash pgbackrest \
    && chown -R pgbackrest:pgbackrest /var/lib/pgbackrest /var/log/pgbackrest

USER pgbackrest

# Set the working directory
WORKDIR /var/lib/pgbackrest

# Default command
CMD ["pgbackrest", "--version"]