.SILENT:

# Variables
SHELL := /bin/bash
IMAGE_NAME := uxplore
CONTAINER_NAME := uxplore
HELIX_LOCAL_CONFIGS := $(HOME)/.config/helix
UXPLOREUSER_HOME := /home/uxploreuser
KERNEL_SOURCE_DIR := $(UXPLOREUSER_HOME)/git/linux
KERNEL_SOURCE_VOLUME := kernel_src
KERNEL_REPO := https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
HELIX_UXPLORE_CONFIGS := $(UXPLOREUSER_HOME)/.config/helix
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help build launch shell stop clone_kernel update_kernel after_compilation_launch

# Help
help: ## Show this help message
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Build
build: ## Build uxplore image and volume
	echo "building uxplore image and volume"
	docker volume create $(KERNEL_SOURCE_VOLUME)
	docker build --tag $(IMAGE_NAME) .

launch: build
	echo "launching uxplore container"
	docker run --rm \
		--volume $(KERNEL_SOURCE_VOLUME):$(KERNEL_SOURCE_DIR) \
		--volume $(HELIX_LOCAL_CONFIGS):$(HELIX_UXPLORE_CONFIGS) \
		--name $(CONTAINER_NAME) \
		$(IMAGE_NAME) sleep infinity > /dev/null &

# Container management
shell:
	echo "opening bash shell"
	docker exec --interactive --tty \
		$(CONTAINER_NAME) bash

stop:
	docker stop $(CONTAINER_NAME)

# Kernel source management
clone_kernel: build ## Clone Linux kernel source into the kernel volume
	docker run --interactive --tty --rm \
		--volume $(KERNEL_SOURCE_VOLUME):$(KERNEL_SOURCE_DIR) $(IMAGE_NAME) \
		bash -c ' \
			set -e; \
			echo "Cloning Linux kernel source code..."; \
			git clone --depth 1 $(KERNEL_REPO) $(KERNEL_SOURCE_DIR); \
			echo "Linux kernel source cloned to $(KERNEL_SOURCE_DIR)"'

update_kernel: build ## Update kernel source to latest master commit
	docker run --interactive --tty --rm \
		--volume $(KERNEL_SOURCE_VOLUME):$(KERNEL_SOURCE_DIR) $(IMAGE_NAME) \
		bash -c ' \
			set -e; \
			echo "Updating Linux kernel source to latest master..."; \
			cd $(KERNEL_SOURCE_DIR); \
			git fetch --depth 1 origin master; \
			git reset --hard FETCH_HEAD; \
			git clean -fd; \
			echo "Linux kernel source updated to latest master commit"'

after_compilation_launch: ## Build initramfs, copy it and bzImage out, boot them in QEMU
	docker exec $(CONTAINER_NAME) $(UXPLOREUSER_HOME)/build_initram.sh
	docker cp $(CONTAINER_NAME):$(KERNEL_SOURCE_DIR)/arch/x86/boot/bzImage .
	docker cp $(CONTAINER_NAME):$(UXPLOREUSER_HOME)/initramfs.cpio.gz .
	qemu-system-x86_64 -accel hvf -cpu host -m 1G -nographic \
		-kernel bzImage -initrd initramfs.cpio.gz -append "console=ttyS0"
