FROM debian:stable-slim AS base

# Kernel build toolchain, see https://docs.kernel.org/process/changes.html
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates curl git \
    build-essential binutils bc bison flex gawk \
    libssl-dev openssl libelf-dev dwarves \
    perl python3 kmod cpio rsync \
    tar gzip xz-utils zstd bzip2 lz4 \
    libncurses-dev && \
  rm -rf /var/lib/apt/lists/*

# Helix editor, latest release, see https://docs.helix-editor.com/package-managers.html
RUN HX_VER=$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/helix-editor/helix/releases/latest | sed 's|.*/||') && \
  mkdir -p /opt/helix && \
  curl -fsSL "https://github.com/helix-editor/helix/releases/download/${HX_VER}/helix-${HX_VER}-$(uname -m)-linux.tar.xz" | \
    tar -xJ -C /opt/helix --strip-components=1 && \
  ln -s /opt/helix/hx /usr/local/bin/hx
ENV HELIX_RUNTIME=/opt/helix/runtime

RUN groupadd -g 1001 uxploregroup && \
  useradd -u 1001 -g uxploregroup -s /bin/sh -m uxploreuser && \
  mkdir -p /home/git/linux && \
  chown uxploreuser:uxploregroup /home/git/linux
USER uxploreuser

WORKDIR /home/uxploreuser/git/linux
