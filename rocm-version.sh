#!/bin/sh
# Detect latest ROCm version from AMD repo page
ROCM_LATEST=$(curl -s https://repo.radeon.com/rocm/deb/ | \
    grep -oE '[0-9]+\.[0-9]+/' | \
    sed 's|/$||' | \
    sort -V -r | \
    head -1)
if [ -z "$ROCM_LATEST" ]; then
    ROCM_LATEST=7.2
fi
echo "$ROCM_LATEST"
