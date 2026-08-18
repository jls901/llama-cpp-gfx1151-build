#!/bin/sh
set -e

# Setup LunarG Vulkan SDK repo (Ubuntu noble)
curl -fsSL https://packages.lunarg.com/lunarg-signing-key-pub.asc | gpg --dearmor -o /usr/share/keyrings/lunarg-vulkan.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lunarg-vulkan.gpg] https://packages.lunarg.com/vulkan noble main" > /etc/apt/sources.list.d/lunarg-vulkan.list

# Vulkan SDK (loader, headers, glslc) + OpenBLAS for CPU-side BLAS
apt-get update
apt-get install -y --no-install-recommends \
    vulkan-sdk \
    libopenblas-dev

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
