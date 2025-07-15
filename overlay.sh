#!/bin/bash

set -e  # Exit on any command failure

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# /root/overlayfs-test/work

EXT_MOUNT="/root"
BASEDIR="${EXT_MOUNT}/overlayfs-test"
LOWERDIR="/cvmfs/big.file.test/"
UPPERDIR="${BASEDIR}/upper"
WORKDIR="${BASEDIR}/work"
MERGEDDIR="${BASEDIR}/merged"

function setup_overlay(){
    echo -e "${YELLOW}===Creating directories===${RESET}"
    mkdir -p "$UPPERDIR" "$WORKDIR" "$MERGEDDIR"

    echo -e "${YELLOW}===Mounting OverlayFS===${RESET}"
    mount -t overlay overlay -o lowerdir="$LOWERDIR",upperdir="$UPPERDIR",workdir="$WORKDIR" "$MERGEDDIR"

    echo -e "${GREEN}===OverlayFS mounted successfully===${RESET}"
    echo -e "${GREEN}===Contents of merged directory===${RESET}"
    ls -l "$MERGEDDIR"
}

function clean(){
    echo -e "${YELLOW}===Unmounting OverlayFS===${RESET}"
    if mountpoint -q "$MERGEDDIR"; then
        umount "$MERGEDDIR"
        echo "Unmounted $MERGEDDIR."
    else
        echo "$MERGEDDIR is not mounted."
    fi

    echo -e "${YELLOW}===Unmounting ext4 disk===${RESET}"
    if mountpoint -q "$EXT_MOUNT"; then
        umount "$EXT_MOUNT"
        echo "Unmounted $EXT_MOUNT."
    else
        echo "$EXT_MOUNT is not mounted."
    fi

    echo -e "${YELLOW}===Removing directories===${RESET}"
    rm -rf "$BASEDIR"

    echo -e "${GREEN}===Cleanup complete===${RESET}"
}

if [ "$1" == "clean" ]; then
    clean
    exit 0
fi

setup_overlay
