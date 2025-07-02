#!/bin/bash
set -e

# ------------------
# CONFIGURATION
# ------------------
ROOTFS_DIR="./rootfs"
DEBIAN_SUITE="bookworm"
ARCH="amd64"
MIRROR="http://deb.debian.org/debian"

# Remove any old rootfs
if [ -d "$ROOTFS_DIR" ]; then
    echo "Removing existing rootfs"
    sudo rm -rf "$ROOTFS_DIR"
fi

CONFIG_FILE="./config.sh"
if [ -f "$CONFIG_FILE" ]; then
    echo "Configuring from "$CONFIG_FILE""
    source "$CONFIG_FILE"
else
    echo "Missing config file: $CONFIG_FILE"
    exit 1
fi

# Ensure debootstrap is installed
if ! command -v debootstrap >/dev/null; then
    echo "Please install debootstrap: sudo apt install debootstrap"
    exit 1
fi

# ------------------
# BOOTSTRAP DEBIAN
# ------------------
echo "Creating rootfs"
sudo debootstrap --arch="$ARCH" "$DEBIAN_SUITE" "$ROOTFS_DIR" "$MIRROR"

# ------------------
# CONFIGURE THE ROOTFS
# ------------------

# Mount required filesystems for chroot setup
echo "Mounting directories"
sudo mount --bind /dev "$ROOTFS_DIR/dev"
sudo mount --bind /proc "$ROOTFS_DIR/proc"
sudo mount --bind /sys "$ROOTFS_DIR/sys"

# Chroot and configure
echo "Entering chroot"
sudo chroot "$ROOTFS_DIR" /bin/bash -eux <<'EOF'

apt-get -y install wget
wget https://cvmrepo.s3.cern.ch/cvmrepo/apt/cvmfs-release-latest_all.deb
dpkg -i cvmfs-release-latest_all.deb
rm -f cvmfs-release-latest_all.deb
apt-get -y update
apt-get -y install cvmfs

cvmfs_config setup
EOF

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

# cvmfs_config probe

# Unmount filesystems
echo "Unmounting"
sudo umount "$ROOTFS_DIR/dev"
sudo umount "$ROOTFS_DIR/proc"
sudo umount "$ROOTFS_DIR/sys"

# Done
echo "Rootfs created in $ROOTFS_DIR"
