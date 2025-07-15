#!/bin/bash
set -e

# Change this path to point to your linux source
KERNEL_DIR="/root/linux"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="$CURRENT_DIR/test.sh"
VM_EXIT_FILE="$CURRENT_DIR/vm_exit_code.txt"

OVERLAY_SETUP="$CURRENT_DIR/overlay.sh"

# Move to kernel directory
cd "$KERNEL_DIR"

# Build kernel
echo '=====Configuring kernel====='
vng --kconfig 2>/dev/null

echo '=====Building kernel====='
vng -b
echo '=====Success====='

cd "$CURRENT_DIR"

# Build test binary
echo '=====Compiling test file====='
gcc -static -o read_test test.c
echo '=====Success====='

# Run VM with built kernel
echo '=====Starting VM====='
virtme-run \
  --kimg "$KERNEL_DIR"/arch/x86/boot/bzImage \
  --rw \
  --pwd \
  --mods auto \
  --memory 1024 \
  --script-sh "
  echo '=====Entering VM====='
  uname -a
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
    echo "Test failed inside VM, marking as bad commit."
    exit 1
  else
    echo "Test passed inside VM, marking as good commit."
    exit 0
  fi
else
  echo "VM did not return an exit code file, something went wrong!"
  exit 1
fi