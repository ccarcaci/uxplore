FROM alpine:latest AS base

# Install git and neovim
RUN apk update; apk add --no-cache curl git neovim openssh-client

RUN addgroup -g 1001 uxploregroup && \
  adduser -u 1001 -G uxploregroup -s /bin/sh -D uxploreuser
USER uxploreuser

FROM base AS dbg

# Set working directory to the volume
WORKDIR /linux-kernel

# Clone repository using SSH agent forwarding
RUN mkdir -p -m 700 ~/.ssh && \
  ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN echo $SSH_AUTH_SOCK

RUN --mount=type=ssh,uid=1001 \
  ssh -T git@github.com 2>&1

FROM dbg AS final

RUN git clone git@github.com:torvalds/linux.git

# Create volume for Linux kernel source code
VOLUME /linux-kernel

# Create volume for neovim settings
VOLUME /.config/nvim

