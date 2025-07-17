#!/bin/bash
set -eu

# ------------------
# CLEANUP ON ERROR
# ------------------
cleanup() {
  error "An error occurred. Exiting."
}
trap cleanup ERR

# ------------------
# IMPORT LOGGER
# ------------------
LOGGING="./utils/logging.sh"
if [ -f "$LOGGING" ]; then
  source "$LOGGING"
else
  echo "[FATAL] Cannot find logger"
  exit 1
fi

# ------------------
# IMPORT CONFIGURATION
# ------------------
ROOTFS_DIR=""

CONFIG_FILE="./configs/config.sh"
if [ -f "$CONFIG_FILE" ]; then
  log "Importing configuration from "$CONFIG_FILE""
  source "$CONFIG_FILE"
else
  error "Missing config file: $CONFIG_FILE"
  exit 1
fi


warn "This script will overwrite files or directories"
warn "  - "$ROOTFS_DIR"/etc/cvmfs/default.local"
warn "  - "$ROOTFS_DIR"/etc/cvmfs/config.d/"$CVMFS_REPOSITORY".conf"
warn "  - "$ROOTFS_DIR"/etc/cvmfs/keys/"$CVMFS_REPOSITORY"/"$CVMFS_REPOSITORY".pub"
warn "Please back up any important data before continuing."

read -rp "Do you want to continue? [y/N]: " confirm
confirm=${confirm,,}

if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
  warn "Aborted by user."
  exit 1
fi

# Set CVMFS configuration
configure_host() {
  log "Configuring $CVMFS_REPOSITORY"

  mkdir -p "$ROOTFS_DIR"/etc/cvmfs/config.d
  mkdir -p "$ROOTFS_DIR"/etc/cvmfs/keys/"$CVMFS_REPOSITORY"
  
  cat <<EOF >"$ROOTFS_DIR"/etc/cvmfs/default.local
CVMFS_REPOSITORIES=$CVMFS_REPOSITORY
CVMFS_CLIENT_PROFILE="single"
CVMFS_QUOTA_LIMIT=10000
EOF

  cat <<EOF >"$ROOTFS_DIR"/etc/cvmfs/config.d/"$CVMFS_REPOSITORY".conf
CVMFS_KEYS_DIR=/etc/cvmfs/keys/$CVMFS_REPOSITORY
CVMFS_REPOSITORIES=$CVMFS_REPOSITORY
CVMFS_HTTP_PROXY="DIRECT"
CVMFS_SERVER_URL=http://$CVMFS_SERVER_IP/cvmfs/@fqrn@
CVMFS_PUBLIC_KEYS=$CVMFS_REPOSITORY.pub
EOF

  cat <<EOF >"$ROOTFS_DIR"/etc/cvmfs/keys/"$CVMFS_REPOSITORY"/"$CVMFS_REPOSITORY".pub
$CVMFS_SERVER_PUB_KEY
EOF

  log "Creating directory for disk mount"
  mkdir -p /mnt/test
  
  success "CVMFS configuration completed"
}

# Create a disk
create_disk() {
  local disk_path="${DISK_PATH:-./disk.img}"
  local disk_size="${DISK_SIZE:-8192}"

  if [[ -f "$disk_path" ]]; then
    log "Disk already exists at $disk_path. Skipping creation."
    return 0
  fi

  log "Creating disk image: $disk_path (${disk_size}MB)"
  dd if=/dev/zero of="$disk_path" bs=1M count="$disk_size" status=none
  success "Disk created successfully"
}

configure_host
create_disk
