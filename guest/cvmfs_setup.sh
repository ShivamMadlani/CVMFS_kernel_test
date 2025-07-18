#!/bin/bash

set -eu

# ------------------
# IMPORT LOGGER
# ------------------
LOGGING="../utils/logging.sh"
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

function setup_guest_net() {
  log "Enabling eth0"
  ip link set eth0 up
  dhclient eth0
  success "eth0 enabled"
}

function setup_guest_disk() {
  log "Mounting disk"
  mount /dev/vda "${EXT_MOUNT}"
  success "Disk mounted"
}

function setup_cvmfs() {
  log "Installing CVMFS client"
  dnf install cvmfs -y > /dev/null
  log "Creating directories"
  mkdir -p "${LOWERDIR}"
  log "Mounting cvmfs"
  mount -t cvmfs big.file.test "${LOWERDIR}"
  success "Mounted cvmfs"
}

setup_guest_net
setup_guest_disk
setup_cvmfs
