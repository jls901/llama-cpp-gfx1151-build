#!/bin/sh
set -e

# Detect ROCm version from AMD apt repo (filter nginx version out)
ROCM_LATEST=$(curl -s https://repo.radeon.com/rocm/apt/ | \
    grep -oE '<a href="[0-9]+\.[0-9]+/"' | \
    grep -oE '[0-9]+\.[0-9]+' | \
    sort -V -r | \
    grep -vE '^0\.' | \
    grep -vE '^1\.[0-9]+$' | \
    head -1)
if [ -z "$ROCM_LATEST" ]; then
    ROCM_LATEST=7.2
fi
ROCM_VERSION=$ROCM_LATEST

echo "Using ROCm version: $ROCM_VERSION"

# Setup ROCm repo
rm -f /usr/share/keyrings/rocm.gpg
mkdir -p /usr/share/keyrings
curl -fsSL https://repo.radeon.com/rocm/rocm.gpg.key | gpg --batch --no-tty --dearmor -o /usr/share/keyrings/rocm.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/$ROCM_VERSION noble main" > /etc/apt/sources.list.d/rocm.list

# Install ROCm runtime libs only
apt-get update
apt-get install -y --no-install-recommends \
    rocm-libs \
    hip-runtime-amd \
    rocblas \
    miopen-hip

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
