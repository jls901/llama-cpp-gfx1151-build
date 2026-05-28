FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

# Base build deps + gpg/certs (remove rocm-cmake to avoid conflict with ROCm repo version)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    pkg-config \
    libssl-dev \
    liburing-dev \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Detect and install ROCm from AMD repo
COPY setup-rocm.sh /setup-rocm.sh
RUN chmod +x /setup-rocm.sh && /setup-rocm.sh

FROM base AS builder

# Clone llama.cpp (latest stable)
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git /opt/llama.cpp
WORKDIR /opt/llama.cpp

# Optimizations for Ryzen AI Max+ 395 (Zen 4 / RDNA 4)
# GFX1151 = RDNA 4 iGPU
ENV LLAMA_HIPBLAS=ON \
    AMDGPU_TARGETS=gfx1151 \
    HSA_ENABLE_SIWA=0 \
    CMAKE_BUILD_TYPE=Release

RUN cmake -B build -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DGGML_HIP=ON -DLLAMA_HIPBLAS=${LLAMA_HIPBLAS} -DCMAKE_HIP_ARCHITECTURES=gfx1151 -DAMDGPU_TARGETS=gfx1151 -DGGML_NATIVE=ON -DGGML_HIP_GRAPHS=ON -DLLAMA_BUILD=ON -DLLAMA_TESTS=OFF && cmake --build build --config Release -j$(nproc)

FROM base AS runtime

# Detect and install minimal ROCm for runtime
COPY setup-rocm-runtime.sh /setup-rocm-runtime.sh
RUN chmod +x /setup-rocm-runtime.sh && /setup-rocm-runtime.sh

# Copy built binaries
COPY --from=builder /opt/llama.cpp/build/bin/llama-server /usr/local/bin/llama-server
COPY --from=builder /opt/llama.cpp/build/bin/llama-cli /usr/local/bin/llama-cli
COPY --from=builder /opt/llama.cpp/build/bin/llama-bench /usr/local/bin/llama-bench
COPY --from=builder /opt/llama.cpp/build/bin/llama-perplexity /usr/local/bin/llama-perplexity

ENV HSA_ENABLE_SIWA=0
ENV AMDGPU_TARGETS=gfx1151

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/llama-server"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
