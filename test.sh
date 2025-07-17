#!/bin/bash
set -eu

REPO="big.file.test"
FILE="/mnt/test/cvmfs/$REPO/big_file.img"

echo "1. Read big_file.img from cvmfs_server"
./read_test "$FILE"
