#!/bin/bash

set -eu

# ------------------
# IMPORT LOGGER
# ------------------
LOGGING="/mnt/utils/logging.sh"
if [ -f "$LOGGING" ]; then
  source "$LOGGING"
else
  echo "[FATAL] Cannot find logger"
  exit 1
fi

EXT_MOUNT="/mnt/test"
BASEDIR="${EXT_MOUNT}/overlayfs-test"
LOWERDIR="${EXT_MOUNT}/cvmfs/big.file.test"
UPPERDIR="${BASEDIR}/upper"
WORKDIR="${BASEDIR}/work"
MERGEDDIR="${BASEDIR}/merged"

function setup_overlay() {
  log "Creating directories"
  mkdir -p "$UPPERDIR" "$WORKDIR" "$MERGEDDIR"

  log "Mounting OverlayFS"
  mount -t overlay overlay -o lowerdir="$LOWERDIR",upperdir="$UPPERDIR",workdir="$WORKDIR" "$MERGEDDIR"

  success "OverlayFS mounted"
}

function clean() {
  log "Unmounting OverlayFS"
  if mountpoint -q "$MERGEDDIR"; then
    umount "$MERGEDDIR"

  log "Unmounting ext4 disk"
  if mountpoint -q "$EXT_MOUNT"; then
    umount "$EXT_MOUNT"

  log "Removing directories"
  rm -rf "$BASEDIR"

  success "Cleanup complete"
}

if [ "$1" == "clean" ]; then
  clean
  exit 0
fi

setup_overlay
