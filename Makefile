SHELL := /bin/bash
.DEFAULT_GOAL := help

MEDIASERVER_ROOT := /home/pi/mediaserver
FLAKE            := .#pi

.PHONY: init
init: ## Full bootstrap (system + network + nix)
	@./init.sh

.PHONY: init-system
init-system: ## Dirs, sysctl, hosts, firewall, apt
	@./scripts/init-system.sh

.PHONY: init-nix
init-nix: ## Install Nix and apply home-manager config
	@./scripts/init-nix.sh

.PHONY: init-network
init-network: ## Set static IP via NetworkManager
	@./scripts/init-network.sh

.PHONY: init-warp
init-warp: ## Register Cloudflare WARP (one-time)
	@nix shell nixpkgs#wgcf -c bash scripts/init-warp.sh

.PHONY: build
build: ## Build and activate home-manager config
	nix run home-manager -- switch --flake '$(FLAKE)'

.PHONY: build-system
build-system: ## Apply system services config via home-manager
	nix run home-manager -- switch --flake '$(FLAKE)'

.PHONY: build-dry
build-dry: ## Dry-run build (no activation)
	nix run home-manager -- build --flake '$(FLAKE)'

.PHONY: build-trace
build-trace: ## Build with --show-trace for debugging
	nix run home-manager -- switch --flake '$(FLAKE)' --show-trace

.PHONY: status
status: ## Show status of all services
	@systemctl --user status angie sonarr radarr prowlarr bazarr seerr qbittorrent wireproxy 2>&1 || true
	@systemctl --user status jellyfin jellarr 2>&1 || true

.PHONY: logs
logs: ## Tail all service logs (Ctrl-C to stop)
	@journalctl --user -f

.PHONY: restart
restart: ## Restart all services
	systemctl --user restart angie sonarr radarr prowlarr bazarr seerr qbittorrent wireproxy
	systemctl restart jellyfin jellarr

.PHONY: check-updates
check-updates: ## Check for upstream package updates
	@./.github/scripts/auto-update-pkgs.sh

.PHONY: activate
activate: ## Pull latest lock from git and activate home-manager config
	git pull --ff-only || true
	nix run home-manager -- switch --flake '$(FLAKE)'

.PHONY: update-flake
update-flake: ## Update flake.lock inputs (CI-only; do not run on Pi)
	nix flake update

.PHONY: gc
gc: ## Deep Nix cleanup: remove old generations, GC store, dedup
	@echo "=== Removing old nix-env generations ==="
	nix-env --delete-generations old
	@echo ""
	@echo "=== Removing old home-manager generations ==="
	home-manager expire-generations "-1 days" 2>/dev/null || true
	@echo ""
	@echo "=== Nix garbage collection ==="
	nix-collect-garbage -d
	@echo ""
	@echo "=== Optimising Nix store (dedup) ==="
	nix store optimise
	@echo ""
	@echo "=== Disk usage ==="
	@du -sh /nix/store
	@df -h /

.PHONY: gc-light
gc-light: ## Light GC: collect garbage without removing generations
	nix-collect-garbage
	@du -sh /nix/store
	@df -h /

.PHONY: disk
disk: ## Show disk usage summary
	@echo "=== Nix store ==="
	@du -sh /nix/store
	@echo ""
	@echo "=== Mediaserver ==="
	@du -sh $(MEDIASERVER_ROOT)/config $(MEDIASERVER_ROOT)/data 2>/dev/null || true
	@echo ""
	@echo "=== Filesystem ==="
	@df -h /

.PHONY: warp-status
warp-status: ## Check WARP connectivity
	@curl -s --socks5 127.0.0.1:1080 https://cloudflare.com/cdn-cgi/trace | grep warp
	@echo "External IP via WARP:"
	@curl -s --socks5 127.0.0.1:1080 https://ifconfig.me && echo

.PHONY: ports
ports: ## Show listening ports
	@ss -tlnp

.PHONY: temps
temps: ## Show CPU temperature
	@vcgencmd measure_temp 2>/dev/null || echo "vcgencmd not available"

.PHONY: init-hdd
init-hdd: ## Safe HDD setup: fstab + mount + dirs (idempotent, no format)
	@bash scripts/init-hdd.sh setup

.PHONY: hdd-format
hdd-format: ## ONE-TIME ONLY: Format HDD — DESTROYS ALL DATA (usage: make hdd-format DEV=/dev/sdX)
	@bash scripts/init-hdd.sh format $(DEV)

.PHONY: hdd-uas
hdd-uas: ## Check USB HDD uses UAS driver
	@bash scripts/init-hdd.sh uas

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
