#!/bin/bash
set -e

# ------------------
# CONFIGURATION
# ------------------
ROOTFS_DIR="./rootfs"

CONFIG_FILE="./config.sh"
if [ -f "$CONFIG_FILE" ]; then
    echo "Configuring from "$CONFIG_FILE""
    source "$CONFIG_FILE"
else
    echo "Missing config file: $CONFIG_FILE"
    exit 1
fi

# Set CVMFS configuration
echo "Configuring $CVMFS_REPOSITORY"
cat <<EOF > "$ROOTFS_DIR"/etc/cvmfs/default.local
CVMFS_REPOSITORIES=$CVMFS_REPOSITORY
CVMFS_CLIENT_PROFILE="single"
CVMFS_QUOTA_LIMIT=10000
EOF

cat <<EOF > "$ROOTFS_DIR"/etc/cvmfs/config.d/"$CVMFS_REPOSITORY".conf
CVMFS_KEYS_DIR=/etc/cvmfs/keys/$CVMFS_REPOSITORY
CVMFS_REPOSITORIES=$CVMFS_REPOSITORY
CVMFS_HTTP_PROXY="DIRECT"
CVMFS_SERVER_URL=http://$CVMFS_SERVER_IP/cvmfs/@fqrn@
CVMFS_PUBLIC_KEYS=$CVMFS_REPOSITORY.pub
EOF

mkdir -p "$ROOTFS_DIR"/etc/cvmfs/keys/"$CVMFS_REPOSITORY"
cat <<EOF > "$ROOTFS_DIR"/etc/cvmfs/keys/"$CVMFS_REPOSITORY"/"$CVMFS_REPOSITORY".pub
$CVMFS_SERVER_PUB_KEY
EOF

cvmfs_config probe
