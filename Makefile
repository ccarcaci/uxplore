# Variables
SHELL := /bin/bash
PODMAN_IMAGE := alpine:latest
CONTAINER_NAME := uxplore-dev
.DEFAULT_GOAL := help

# Phony targets
.PHONY: help start shell stop clean status

# Help
help: ## Show this help message
	@echo "Podman Development Environment"
	@echo "============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Podman machine management
start: ## Start podman machine
	@echo "starting podman machine"
	@podman machine start || echo "Machine already running"

stop: ## Stop podman machine
	@echo "stopping podman machine"
	@podman machine stop || echo "Machine already stopped"

status: ## Show podman machine status
	@echo "podman machine status"
	@podman machine list

# Container management
shell: start ## Start machine and open Alpine Linux shell
	@echo "opening Alpine Linux shell"
	@podman run -it --rm --name $(CONTAINER_NAME) $(PODMAN_IMAGE) sh

clean: ## Remove all containers and images
	@echo "cleaning up containers and images"
	@podman container prune -f || true
	@podman image prune -f || true

