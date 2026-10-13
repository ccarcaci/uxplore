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
.PHONY: help build start shell stop clean status clone_kernel update_kernel

# Help
help: ## Show this help message
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Build
build: ## Build uxplore image and volume
	echo "building uxplore image and volume"
	docker volume create $(KERNEL_SOURCE_VOLUME)
	docker build --tag $(IMAGE_NAME) .

# Container management
shell: build ## Build and open bash pointing to kernel directory
	echo "opening bash shell"
	docker run --interactive --tty --rm \
		--volume $(KERNEL_SOURCE_VOLUME):$(KERNEL_SOURCE_DIR) \
		--volume $(HELIX_LOCAL_CONFIGS):$(HELIX_UXPLORE_CONFIGS) \
		--name $(CONTAINER_NAME) $(IMAGE_NAME) \
		bash

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
