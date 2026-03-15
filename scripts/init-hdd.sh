#!/usr/bin/env bash
# Format external HDD and configure fstab for NVMe/HDD split layout.
#
# Layout: HDD at /mnt/hdd contains:
#   downloads/{complete,incomplete}  — qBittorrent (Arr hardlink source)
#   media/{movies,tv}               — Sonarr/Radarr/Jellyfin
#   immich/library                  — Immich originals
#
# Both downloads and media on same FS = atomic hardlinks.
#
# Usage:
#   ./scripts/init-hdd.sh format /dev/sdX   # Format (DESTROYS ALL DATA)
#   ./scripts/init-hdd.sh fstab             # Add fstab entry
#   ./scripts/init-hdd.sh mount             # Mount now
#
# Prerequisites: HDD connected. For format: identify device with lsblk.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
load_env || true

MEDIASERVER_ROOT="${MEDIASERVER_ROOT:-/home/pi/mediaserver}"
MOUNT_PATH="${HDD_MOUNT_PATH:-/mnt/hdd}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# fstab options: noatime,nodiratime reduce metadata writes; commit=60 batches writes
FSTAB_OPTS="defaults,nofail,nosuid,noatime,nodiratime,commit=60,x-systemd.device-timeout=10"

# --- format ---
format_drive() {
  local dev="$1"
  [[ -b "$dev" ]] || error "Not a block device: $dev"
  [[ "$dev" =~ ^/dev/sd[a-z]$ ]] || [[ "$dev" =~ ^/dev/nvme[0-9]+n[0-9]+$ ]] || error "Use whole disk (e.g. /dev/sda), not a partition"

  warn "DESTROYS ALL DATA on $dev. Type YES to confirm:"
  read -r confirm
  [[ "$confirm" == "YES" ]] || error "Aborted."

  info "Creating GPT partition table and single ext4 partition..."
  sudo parted -s "$dev" mklabel gpt
  sudo parted -s "$dev" mkpart primary ext4 0% 100%
  sleep 2
  if [[ "$dev" =~ nvme ]]; then part="${dev}p1"; else part="${dev}1"; fi
  [[ -b "$part" ]] || error "Partition $part not found. Try: lsblk $dev"

  info "Formatting $part as ext4..."
  sudo mkfs.ext4 -L media -F "$part"

  info "Format complete. UUID: $(sudo blkid -s UUID -o value "$part")"
  info "Run: ./scripts/init-hdd.sh fstab"
}

# --- fstab ---
add_fstab() {
  local part_uuid part_dev
  part_dev=$(sudo blkid -L media 2>/dev/null || true)
  [[ -z "$part_dev" ]] && part_dev=$(findmnt -n -o SOURCE "${MOUNT_PATH}" 2>/dev/null || true)
  [[ -z "$part_dev" ]] && error "Could not find media partition (label=media). Run format first."

  part_uuid=$(sudo blkid -s UUID -o value "$part_dev")
  [[ -z "$part_uuid" ]] && error "No UUID for $part_dev"

  if grep -q "UUID=${part_uuid}" /etc/fstab 2>/dev/null; then
    info "fstab already has entry for UUID=$part_uuid"
    return 0
  fi

  sudo mkdir -p "${MOUNT_PATH}"
  echo "UUID=${part_uuid}  ${MOUNT_PATH}  ext4  ${FSTAB_OPTS}  0  2" | sudo tee -a /etc/fstab
  info "Added fstab entry. Mount point: ${MOUNT_PATH}"
  info "Run: sudo mount -a"
}

# --- UAS check: USB3 HDD should use UAS (not usb-storage) for better throughput ---
check_uas() {
  info "USB device tree (look for Driver=uas on HDD):"
  lsusb -t 2>/dev/null || true
  echo ""
  if lsusb -t 2>/dev/null | grep -q "Driver=usb-storage"; then
    warn "Some USB storage uses usb-storage. UAS reduces CPU and improves concurrency."
    echo "  To enable UAS: remove quirks in /etc/modprobe.d/ or kernel cmdline."
    echo "  See: https://wiki.ubuntu.com/Kernel/Reference/USB"
  else
    info "USB storage appears to use UAS — good"
  fi
}

# --- Spin-down: prevent aggressive spin-down (constant spin-up ruins UX) ---
# -S 0 = never; -S 240 = 20 min (240 * 5 sec)
get_disk_from_partition() {
  local part="$1"
  local pkname
  pkname=$(lsblk -no PKNAME "$part" 2>/dev/null | head -1)
  if [[ -n "$pkname" ]]; then
    echo "/dev/$pkname"
  elif [[ "$part" =~ nvme ]]; then
    echo "${part%p[0-9]*}"
  else
    echo "${part%%[0-9]}"
  fi
}

set_spindown() {
  local dev="${1:-}"
  local timeout="${2:-0}"
  if [[ -z "$dev" ]]; then
    part_dev=$(sudo blkid -L media 2>/dev/null || true)
    [[ -z "$part_dev" ]] && part_dev=$(findmnt -n -o SOURCE "${MOUNT_PATH}" 2>/dev/null || true)
    [[ -z "$part_dev" ]] && error "HDD not found. Specify: init-hdd.sh spindown /dev/sda [0|240]"
    dev=$(get_disk_from_partition "$part_dev")
  fi
  [[ -b "$dev" ]] || error "Not a block device: $dev"
  command -v hdparm &>/dev/null || error "hdparm not installed. Run: sudo apt install hdparm"
  sudo hdparm -S "$timeout" "$dev"
  info "Spin-down set: $dev (0=never, 240≈20min)"
}

# --- Install systemd service to persist spin-down on boot ---
install_spindown_service() {
  local timeout="${1:-0}"
  part_dev=$(sudo blkid -L media 2>/dev/null || true)
  [[ -z "$part_dev" ]] && error "HDD not found. Run init-hdd.sh fstab and mount first."
  dev=$(get_disk_from_partition "$part_dev")
  [[ -b "$dev" ]] || error "Block device $dev not found"
  SVC="/etc/systemd/system/mediaserver-hdd-spindown.service"
  sudo tee "$SVC" <<EOF
[Unit]
Description=Disable HDD spin-down (mediaserver)
After=local-fs.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/sbin/hdparm -S ${timeout} ${dev}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable mediaserver-hdd-spindown.service
  info "Installed $SVC (timeout=${timeout}). Reboot or: sudo systemctl start mediaserver-hdd-spindown"
}

# --- mount and ensure dirs (Arr hardlink layout) ---
do_mount() {
  sudo mount -a
  sudo mkdir -p "${MOUNT_PATH}"/downloads/{complete,incomplete}
  sudo mkdir -p "${MOUNT_PATH}"/media/{movies,tv}
  sudo mkdir -p "${MOUNT_PATH}"/immich/library
  sudo chown -R "${PUID}:${PGID}" "${MOUNT_PATH}"
  info "Mounted at ${MOUNT_PATH}. Layout: downloads/{complete,incomplete}, media/{movies,tv}, immich/library"
}

# --- main ---
case "${1:-}" in
  format) format_drive "${2:?Usage: init-hdd.sh format /dev/sdX}" ;;
  fstab) add_fstab ;;
  mount) do_mount ;;
  uas) check_uas ;;
  spindown) set_spindown "${2:-}" "${3:-0}" ;;
  spindown-service) install_spindown_service "${2:-0}" ;;
  *) error "Usage: init-hdd.sh {format|fstab|mount|uas|spindown|spindown-service} [args]" ;;
esac
