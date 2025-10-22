.SILENT:

# Variables
SHELL := /bin/bash
IMAGE_NAME := uxplore
CONTAINER_NAME := uxplore
KERNEL_DIR := $(HOME)/git/linux
KERNEL_REPO := https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help build start shell stop clean status setup-kernel update-kernel

# Help
help: ## Show this help message
	echo "Podman Development Environment"
	echo "============================="
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Build
build: ## Build uxplore image
	echo "building uxplore image"
	podman build --tag $(IMAGE_NAME) .

build-debug: ## Build uxplore image at debug stage
	echo "building uxplore image for debug"
	podman build --target dbg --tag $(IMAGE_NAME):dbg .

launch-debug:
	podman run -it --rm --name $(CONTAINER_NAME)-debug $(IMAGE_NAME):dbg sh

# Podman machine management
start: ## Start podman machine
	echo "starting podman machine"
	podman machine start || echo "Machine already running"

stop: ## Stop podman machine
	echo "stopping podman machine"
	podman machine stop || echo "Machine already stopped"

status: ## Show podman machine status
	echo "podman machine status"
	podman machine list

# Container management
shell: start build ## Start machine and open Alpine Linux shell
	echo "opening Alpine Linux shell"
	podman build --tag $(IMAGE_NAME) .
	podman run -it --rm --volume $(KERNEL_DIR):/kernel --name $(CONTAINER_NAME) $(IMAGE_NAME) sh

clean: ## Remove all containers and images
	echo "cleaning up containers and images"
	podman container prune -f || true
	podman image prune -f || true

# Kernel source management
setup-kernel: ## Clone Linux kernel source to local directory
	echo "Creating kernel directory at $(KERNEL_DIR)"
	mkdir -p $(KERNEL_DIR)
	echo "Cloning Linux kernel source code..."
	git clone --depth 1 $(KERNEL_REPO) $(KERNEL_DIR)
	echo "Linux kernel source cloned to $(KERNEL_DIR)"
	echo "You can now edit the kernel source with your favorite editor"

update-kernel: ## Update kernel source to latest master commit
	echo "Updating Linux kernel source to latest master..."
	cd $(KERNEL_DIR) && git fetch origin master
	cd $(KERNEL_DIR) && git reset --hard FETCH_HEAD
	cd $(KERNEL_DIR) && git clean -fd
	echo "Linux kernel source updated to latest master commit"
