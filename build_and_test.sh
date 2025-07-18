#!/bin/bash
set -eu

# ------------------
# IMPORT LOGGER
# ------------------
LOGGING="utils/logging.sh"
if [ -f "$LOGGING" ]; then
  source "$LOGGING"
else
  echo "[FATAL] Cannot find logger"
  exit 1
fi

# Change this path to point to your linux source
KERNEL_DIR="/root/linux"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="${CURRENT_DIR}/test.sh"
VM_EXIT_FILE="${CURRENT_DIR}/vm_exit_code.txt"

OVERLAY_SETUP="${CURRENT_DIR}/overlay.sh"
CVMFS_GUEST_SETUP="${CURRENT_DIR}/guest/cvmfs_setup.sh"

# Move to kernel directory and Build kernel
cd "${KERNEL_DIR}"
log "Configuring and Building kernel"
vng --kconfig >/dev/null 2>&1
"${KERNEL_DIR}/scripts/config" --enable CONFIG_EXT4_FS
make olddefconfig > /dev/null
vng -b > /dev/null
success "Kernel built"

cd "${CURRENT_DIR}"

# Build test binary
log "Compiling test file"
gcc -static -o read_test test.c
success "Done"

# Erase disk
log "Formatting disk"
mkfs.ext4 -F disk.img > /dev/null

# Run VM with built kernel
log "Starting VM"
vng \
  --run "$KERNEL_DIR"/arch/x86/boot/bzImage \
  --pwd \
  --memory 1024 \
  --rodir=/mnt/utils=./utils \
  --network user \
  --disk ./disk.img \
  --exec "
    echo '=====Entering VM====='
    uname -a
    echo '=====Configure cvmfs====='
    $CVMFS_GUEST_SETUP
    echo '=====Overlaying /cvmfs====='
    $OVERLAY_SETUP
    echo '=====Running test====='
    $TEST_SCRIPT
    TEST_RESULT=\$?
    echo \"\$TEST_RESULT\" > $VM_EXIT_FILE
    echo '=====Exiting VM====='
  "

# Capture the exit code from the VM by reading the exit code file
if [ -f "$VM_EXIT_FILE" ]; then
  VM_EXIT_CODE=$(cat "$VM_EXIT_FILE")
  if [ "$VM_EXIT_CODE" -ne 0 ]; then
    error "Test failed inside VM, marking as bad commit."
    exit 1
  else
    success "Test passed inside VM, marking as good commit."
    exit 0
  fi
else
  error "VM did not return an exit code file, something went wrong!"
  exit 1
fi
