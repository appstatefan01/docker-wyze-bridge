# ================================
# Dockerfile for Wyze Bridge + QSV
# ================================

# Build arguments
ARG BUILD
ARG BUILD_DATE
ARG GITHUB_SHA
ARG QSV=""

# Base image
FROM amd64/python:3.13-slim-bookworm AS base

# ==================================================
# Builder stage (compile ffmpeg, deps, and app code)
# ==================================================
FROM base AS builder
ARG BUILD_DATE
ARG QSV=""

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        gcc \
        git \
        yasm \
        nasm \
        pkg-config \
        libx264-dev \
        libx265-dev \
        libvpx-dev \
        libmp3lame-dev \
        libopus-dev \
        libdrm-dev \
        libva-dev \
        tar \
        xz-utils \
        libffi-dev; \
    if [ -n "${QSV:-}" ]; then \
        apt-get install -y \
            i965-va-driver \
            intel-media-va-driver \
            libmfx1 \
            libva-drm2; \
    fi; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://github.com/appstatefan01/docker-wyze-bridge.git /app

# =====================================
# Runtime stage (lightweight final img)
# =====================================
FROM base AS runtime
COPY --from=builder /usr /usr
COPY --from=builder /app /app

WORKDIR /app

# ✅ Fixed path to requirements.txt
RUN pip install --no-cache-dir -r docker/requirements.txt

# Environment defaults
ENV WYZE_EMAIL="your@email.com" \
    WYZE_PASSWORD="yourpassword" \
    NET_MODE="LAN" \
    RECORD_ALL="false"

# Start Wyze Bridge
CMD ["python", "wyze_bridge.py"]
