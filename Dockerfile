FROM python:3.12-slim

# Build arguments
ARG EXECUTION_MODE=web
ARG USE_IPFS=false
ARG USE_SUMO=true

# Environment variables
ENV EXECUTION_MODE=${EXECUTION_MODE}
ENV USE_IPFS=${USE_IPFS}
ENV USE_SUMO=${USE_SUMO}
ENV SUMO_HOME=/usr/share/sumo
ENV PYTHONUNBUFFERED=1
ENV PATH="/root/.local/bin:$PATH"
ENV UV_LINK_MODE=copy

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install --no-cache-dir uv

# Install SUMO if needed
RUN if [ "$USE_SUMO" = "true" ]; then \
    apt-get update && apt-get install -y \
    sumo \
    sumo-tools \
    sumo-doc \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install IPFS (Kubo) if needed - but don't initialize here
# IPFS will be provided by separate container or use external daemon
RUN if [ "$USE_IPFS" = "true" ]; then \
    wget -q https://dist.ipfs.tech/kubo/v0.35.0/kubo_v0.35.0_linux-amd64.tar.gz && \
    tar -xzf kubo_v0.35.0_linux-amd64.tar.gz && \
    mv kubo/ipfs /usr/local/bin/ipfs && \
    chmod +x /usr/local/bin/ipfs && \
    rm -rf kubo*; \
    fi

# Working directory will be set per service
WORKDIR /app

# Install Python dependencies with uv (will be done per service)
# Note: Each service mounts its directory, so we install dependencies at runtime

# Expose port
EXPOSE 8000 8001 8002 8003

# Healthcheck (will be overridden per service)
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${SERVICE_PORT:-8000}/healthcheck || exit 1

# Copy entrypoint and wait-for-it
COPY entrypoint.sh /entrypoint.sh
COPY wait-for-it.sh /wait-for-it.sh
RUN chmod +x /entrypoint.sh /wait-for-it.sh

# Install netcat for wait-for-it
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Default command
ENTRYPOINT ["/entrypoint.sh"]

