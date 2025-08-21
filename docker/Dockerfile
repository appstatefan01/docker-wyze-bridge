# ================================
# Docker Wyze Bridge w/ Intel VAAPI + QSV Support
# ================================
ARG BUILD
ARG BUILD_DATE
ARG GITHUB_SHA

FROM python:3.13-slim-bookworm AS base

# ================================
# Builder Stage
# ================================
FROM base AS builder
ARG BUILD_DATE

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
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
        libfdk-aac-dev \
        libopus-dev \
        libdrm-dev \
        libva-dev \
        intel-media-va-driver-non-free \
        tar; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Copy app code into build
COPY /app/ /build/app/
RUN chmod +x /build/app/run

# Install Python requirements
RUN --mount=type=cache,target=/root/.cache/pip \
    set -eux; pip3 install --disable-pip-version-check --prefix=/build/usr/local -r /build/app/requirements.txt

# Build ffmpeg with VAAPI + QSV
RUN git clone --depth=1 https://github.com/FFmpeg/FFmpeg.git /ffmpeg && \
    cd /ffmpeg && \
    ./configure \
      --prefix=/usr/local \
      --enable-gpl \
      --enable-libx264 \
      --enable-libx265 \
      --enable-libvpx \
      --enable-libfdk-aac \
      --enable-libopus \
      --enable-vaapi \
      --enable-libmfx \
      --enable-nonfree \
      --extra-libs="-lpthread -lm" && \
    make -j$(nproc) && \
    make install && \
    rm -rf /ffmpeg

# Build MediaMTX and finalize
RUN set -eux; \
    echo "BUILDING IMAGE FOR $(uname -m)";\
    if [ "$(uname -m)" = "armv7l" ]; then \
        TARGETARCH=arm; MTX_ARCH=armv7; \
    elif [ "$(uname -m)" = "aarch64" ]; then \
        TARGETARCH=arm64; MTX_ARCH=arm64; \
    else \
        TARGETARCH=amd64; MTX_ARCH=amd64; \
    fi; \
    cd /build; \
    . app/.env; \
    curl -fsSL https://github.com/bluenviron/mediamtx/releases/download/v${MTX_TAG}/mediamtx_v${MTX_TAG}_linux_${MTX_ARCH}.tar.gz -o mediamtx.tar.gz; \
    tar tzf mediamtx.tar.gz || (echo "Invalid mediamtx tarball for ${MTX_ARCH}" && exit 1); \
    tar xzf mediamtx.tar.gz -C app; \
    rm mediamtx.tar.gz; \
    cp app/lib/lib.${TARGETARCH} usr/local/lib/libIOTCAPIs_ALL.so; \
    rm -rf app/*.txt app/lib/; \
    if [ -z "${BUILD_DATE}" ]; \
        then echo BUILD_DATE=$(date) > .build_date; \
        else echo BUILD_DATE=${BUILD_DATE} > .build_date; \
    fi;

# ================================
# Final Runtime Image
# ================================
FROM base
ARG BUILD
ARG GITHUB_SHA
ARG BUILD_DATE
ARG BUILD_VERSION

RUN set -eux; \
    rm -rf /var/log/* /var/lib/apt/lists/*

COPY --from=builder /build /
COPY --from=builder /usr/local /usr/local

ENV PYTHONUNBUFFERED=1 \
    FLASK_APP=frontend \
    BUILD=$BUILD \
    BUILD_VERSION=$BUILD_VERSION \
    BUILD_DATE=$BUILD_DATE \
    GITHUB_SHA=$GITHUB_SHA \
    FLASK_ENV=production \
    FLASK_DEBUG=0

WORKDIR /app
ENTRYPOINT [ "/app/run" ]

LABEL \
    io.hass.name="Docker Wyze Bridge (Intel QSV + VAAPI)" \
    io.hass.description="Bridges Wyze Cameras into Home Assistant with Intel VAAPI/QSV ffmpeg" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Bobby McMillan <appstatefan01@gmail.com>" \
    org.label-schema.name="Docker Wyze Bridge" \
    org.label-schema.description="Wyze Bridge w/ Intel VAAPI + QSV ffmpeg" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.schema-version="1.0" \
    org.label-schema.usage="https://github.com/appstatefan01/docker-wyze-bridge" \
    org.label-schema.vcs-ref=${GITHUB_SHA} \
    org.label-schema.vcs-url="https://github.com/appstatefan01/docker-wyze-bridge" \
    org.label-schema.vendor="Custom Build"
