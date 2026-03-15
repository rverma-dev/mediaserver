SHELL := /bin/bash
.DEFAULT_GOAL := help

MEDIASERVER_ROOT := /home/pi/mediaserver
FLAKE            := .#pi

# --- Init -------------------------------------------------------------------

.PHONY: init
init: ## Full bootstrap (dirs, nix, configs, network, security)
	@./init.sh

.PHONY: init-dirs
init-dirs: ## Create data and config directories
	@./scripts/init-dirs.sh

.PHONY: init-nix
init-nix: ## Install Nix and apply home-manager config
	@./scripts/init-nix.sh

.PHONY: init-config
init-config: ## Seed service configs (now handled automatically by home-manager activation)
	@echo "Config seeding is now handled by 'make switch' (home-manager activation)"

.PHONY: init-warp
init-warp: ## Register Cloudflare WARP (one-time, needs wgcf)
	@nix shell nixpkgs#wgcf -c bash scripts/init-warp.sh

.PHONY: init-network
init-network: ## Set static IP via NetworkManager
	@./scripts/init-network.sh

.PHONY: init-security
init-security: ## Configure UFW and Fail2ban
	@./scripts/init-security.sh

.PHONY: init-apt-maintenance
init-apt-maintenance: ## Enable unattended-upgrades and periodic apt clean
	@sudo ./scripts/init-apt-maintenance.sh

# --- Build / Deploy ----------------------------------------------------------

NIX_SYS := $(shell uname -m | sed 's/x86_64/x86_64-linux/;s/aarch64\|arm64/aarch64-linux/')

.PHONY: build
build: ## Build and activate home-manager config
	nix run home-manager -- switch --flake '$(FLAKE)' -b backup
	$(MAKE) setcap-caddy

.PHONY: setcap-caddy
setcap-caddy: ## Grant Caddy permission to bind to port 443 (needs sudo)
	@CADDY_BIN="$$(nix path-info .#packages.$(NIX_SYS).caddy-duckdns 2>/dev/null)/bin/caddy"; \
	if [[ -f "$$CADDY_BIN" ]]; then \
	  echo "Setting CAP_NET_BIND_SERVICE on Caddy..."; \
	  sudo setcap 'cap_net_bind_service=+ep' "$$CADDY_BIN" 2>/dev/null && echo "Done." || echo "Run: sudo setcap cap_net_bind_service=+ep $$CADDY_BIN"; \
	else \
	  echo "Could not find Caddy binary. Skipping setcap."; \
	fi

.PHONY: build-dry
build-dry: ## Dry-run build (no activation)
	nix run home-manager -- build --flake '$(FLAKE)'

.PHONY: build-trace
build-trace: ## Build with --show-trace for debugging
	nix run home-manager -- switch --flake '$(FLAKE)' -b backup --show-trace

# --- Services ----------------------------------------------------------------

.PHONY: status
status: ## Show status of all services
	@systemctl --user status caddy sonarr radarr prowlarr bazarr jellyfin seerr qbittorrent wireproxy camera-mock 2>&1 || true

.PHONY: logs
logs: ## Tail all service logs (Ctrl-C to stop)
	@journalctl --user -f

.PHONY: restart
restart: ## Restart all services
	systemctl --user restart caddy sonarr radarr prowlarr bazarr jellyfin seerr qbittorrent wireproxy camera-mock

.PHONY: camera-mock-start
camera-mock-start: ## Start camera-mock RTSP service
	systemctl --user start camera-mock

.PHONY: camera-mock-stop
camera-mock-stop: ## Stop camera-mock RTSP service
	systemctl --user stop camera-mock

.PHONY: camera-mock-restart
camera-mock-restart: ## Restart camera-mock RTSP service
	systemctl --user restart camera-mock

.PHONY: camera-mock-logs
camera-mock-logs: ## Tail camera-mock logs (Ctrl-C to stop)
	@journalctl --user -u camera-mock -f

.PHONY: camera-mock-status
camera-mock-status: ## Show camera-mock service status
	@systemctl --user status camera-mock --no-pager

# --- Updates -----------------------------------------------------------------

.PHONY: check-updates
check-updates: ## Check for upstream package updates
	@./scripts/check-updates.sh

.PHONY: update-flake
update-flake: ## Update flake.lock inputs
	nix flake update

# --- Garbage Collection ------------------------------------------------------

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

# --- Info / Diagnostics ------------------------------------------------------

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

.PHONY: hdd-uas
hdd-uas: ## Check USB HDD uses UAS driver
	@bash scripts/init-hdd.sh uas

# --- Help --------------------------------------------------------------------

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
