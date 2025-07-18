#!/bin/bash
set -eu

REPO="big.file.test"
FILE="/mnt/test/overlayfs-test/merged/big_file.img"

echo "1. Read big_file.img from cvmfs_server"
./read_test "$FILE"
