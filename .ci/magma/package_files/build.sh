#!/usr/bin/env bash

set -eu -o pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

INSTALL_DIR="${INSTALL_DIR:-/usr/local/myproject}"
CUDA_ARCH_LIST="${CUDA_ARCH_LIST:-All}"
DESIRED_CUDA="${DESIRED_CUDA:-11.8}"
BUILD_DIR="${BUILD_DIR:-build}"

if ! command -v nvcc >/dev/null 2>&1; then
    echo "Error: nvcc not found. Please ensure CUDA is installed."
    exit 1
fi

CUDA_VERSION="$(nvcc --version | grep -Po 'release \K[0-9]+\.[0-9]+')"
if [[ "$CUDA_VERSION" != "$DESIRED_CUDA" ]]; then
    echo "Error: CUDA version mismatch. Desired: $DESIRED_CUDA, Found: $CUDA_VERSION"
    exit 1
fi
echo "CUDA version $CUDA_VERSION matches desired version $DESIRED_CUDA"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. \
    -DUSE_FORTRAN=OFF \
    -DGPU_TARGET="All" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCUDA_ARCH_LIST="$CUDA_ARCH_LIST"

NUM_CORES="$(getconf _NPROCESSORS_CONF 2>/dev/null || echo 1)"
make -j"$NUM_CORES"
make install

# Return to root
cd -
echo "Build completed and installed to $INSTALL_DIR"
