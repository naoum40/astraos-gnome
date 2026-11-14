#!/bin/bash
# AstraOS ISO Build Script
# Run this on a machine with Docker installed
# Usage: ./build.sh [pack]

set -e

PACK="${1:-core}"
VERSION="0.3.0"
ISO_NAME="AstraOS-${VERSION}-x86_64.iso"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "  AstraOS ISO Builder"
echo "  Pack: $PACK"
echo "  Version: $VERSION"
echo "========================================="
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker not installed."
    echo "Install: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker daemon
if ! docker info &>/dev/null; then
    echo "ERROR: Docker daemon not running."
    echo "Start: sudo systemctl start docker"
    exit 1
fi

cd "$SCRIPT_DIR"

echo "[1/3] Building Docker image..."
docker build -t astraos-builder -f docker/Dockerfile.build .

echo ""
echo "[2/3] Building ISO (this takes 20-40 minutes)..."
mkdir -p out work

docker run --rm --privileged \
    -v "$(pwd)/kickstart:/kickstart:ro" \
    -v "$(pwd)/out:/results" \
    -v "$(pwd)/work:/tmp/lmc" \
    astraos-builder

echo ""
echo "[3/3] Done!"
echo ""
echo "ISO location: out/$ISO_NAME"
ls -lh out/*.iso 2>/dev/null

echo ""
echo "To test in QEMU:"
echo "  qemu-system-x86_64 -m 4096 -smp 2 -cdrom out/$ISO_NAME -boot d -vnc :0"
echo ""
echo "To test in VirtualBox:"
echo "  1. Create VM (Linux 64-bit, 4GB RAM, 30GB disk)"
echo "  2. Mount out/$ISO_NAME as CD"
echo "  3. Boot"
