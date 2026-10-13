# uxplore

A Docker environment for building the Linux kernel and booting it with QEMU on macOS.

The default target architecture is **x86_64**.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [QEMU](https://www.qemu.org/download/)

## How it works

- The kernel source is cloned with git into the Docker volume `kernel_src`, which is mounted at `/home/uxploreuser/git/linux`. The source and the build output live in the volume, so they survive container restarts.
- The build image includes the [Helix](https://helix-editor.com/) editor (`hx`) for browsing and editing the source. Your local `~/.config/helix` is mounted into the container.
- `build_initram.sh` builds a minimal BusyBox initramfs, so the kernel boots into a shell without needing a root disk.

## Compile the kernel

On the host:

```sh
make clone_kernel   # first time only: clone the kernel source into the volume
make launch         # build the image and start the container
make shell          # open a shell inside the container
```

Inside the container:

```sh
make menuconfig     # choose build options, writes .config
make -j"$(nproc)"   # compile the kernel
```

`make defconfig` gives a working default config if you don't want to pick options by hand.

## Launch the kernel

Once the kernel is compiled, run this on the host:

```sh
make after_compilation_launch
```

This builds the initramfs inside the container, copies `bzImage` and `initramfs.cpio.gz` to the current directory, and boots them with QEMU.

### Exit QEMU

Type `exit`, then press `CTRL+A` followed by `X`.

Note: `exit` ends the shell, which is PID 1, so the kernel panics with `Attempted to kill init!`. That's harmless, but `CTRL+A X` alone is enough to quit.

## Cross-compile for another architecture (not tested yet)

Example for arm64. The other architectures follow the same pattern with a different `ARCH`, toolchain, and QEMU binary.

1. Add the cross toolchain to the `apt-get install` list in the `Dockerfile`, then rebuild with `make stop && make launch`:

   ```
   gcc-aarch64-linux-gnu
   ```

2. Inside the container, build into a separate output directory so the x86_64 build is left untouched:

   ```sh
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build-arm64 defconfig
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- O=build-arm64 -j"$(nproc)"
   ```

   - `ARCH` is the directory name under `arch/`.
   - `CROSS_COMPILE` is the toolchain prefix (see [kbuild docs](https://docs.kernel.org/kbuild/kbuild.html)).
   - The resulting image is `build-arm64/arch/arm64/boot/Image`.

3. The initramfs needs an arm64 BusyBox. `build_initram.sh` copies the container's x86_64 one, which won't run on arm64. Fetching the arm64 package needs root and fresh apt lists, so add it to the `Dockerfile` (before `USER`):

   ```dockerfile
   RUN dpkg --add-architecture arm64 && apt-get update && \
     cd /tmp && apt-get download busybox-static:arm64 && \
     dpkg -x busybox-static_*_arm64.deb /opt/busybox-arm64 && \
     rm -rf /tmp/*.deb /var/lib/apt/lists/*
   ```

   Then use `/opt/busybox-arm64/usr/bin/busybox` in place of `/bin/busybox` when building the initramfs.

4. Copy both files to the host with `docker cp` and boot them with the [`virt`](https://www.qemu.org/docs/master/system/arm/virt.html) machine:

   ```sh
   qemu-system-aarch64 -M virt -cpu cortex-a57 -m 1G -nographic \
     -kernel Image -initrd initramfs.cpio.gz -append "console=ttyAMA0"
   ```

   On Apple Silicon, `-accel hvf -cpu host` gives native speed.
