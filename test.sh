#!/bin/sh
set -e

REPO="big.file.test"
FILE="/cvmfs/$REPO/big_file.img"

echo "1. Read big_file.img from cvmfs_server"
./read_test "$FILE"
