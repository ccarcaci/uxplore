FROM debian:stable-slim

# Kernel build toolchain, see https://docs.kernel.org/process/changes.html
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates curl git \
    build-essential binutils bc bison flex gawk \
    libssl-dev openssl libelf-dev dwarves \
    perl python3 kmod cpio rsync \
    tar gzip xz-utils zstd bzip2 lz4 \
    libncurses-dev busybox-static && \
  rm -rf /var/lib/apt/lists/*

# Helix editor, see https://github.com/helix-editor/helix/releases
ARG HX_VER=25.07.1
RUN mkdir -p /opt/helix && \
  curl -fsSL "https://github.com/helix-editor/helix/releases/download/${HX_VER}/helix-${HX_VER}-$(uname -m)-linux.tar.xz" | \
    tar -xJ -C /opt/helix --strip-components=1 && \
  ln -s /opt/helix/hx /usr/local/bin/hx
ENV HELIX_RUNTIME=/opt/helix/runtime
ENV COLORTERM=truecolor

RUN groupadd -g 1001 uxploregroup && \
  useradd -u 1001 -g uxploregroup -s /bin/sh -m uxploreuser && \
  mkdir -p /home/uxploreuser/git/linux /home/uxploreuser/.config && \
  chown -R uxploreuser:uxploregroup /home/uxploreuser/git /home/uxploreuser/.config

COPY --chmod=755 build_initram.sh /home/uxploreuser/

USER uxploreuser

WORKDIR /home/uxploreuser/git/linux
