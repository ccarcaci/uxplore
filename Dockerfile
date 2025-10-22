FROM alpine:latest AS base

# Install git and neovim
RUN apk update; apk add --no-cache curl

RUN addgroup -g 1001 uxploregroup && \
  adduser -u 1001 -G uxploregroup -s /bin/sh -D uxploreuser
USER uxploreuser

FROM base AS dbg

# Set working directory to the volume
WORKDIR /kernel

# Create volume for Linux kernel source code
VOLUME /kernel
