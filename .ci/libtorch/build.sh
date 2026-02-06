#!/usr/bin/env bash
# Dedicated libtorch-only build script
# Skips Python wheel packaging, builds C++ library only
# Supports optional DESIRED_PYTHON and extra build arguments

set -eu -o pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ROOT_DIR="$(cd "$SCRIPTPATH/../.." && pwd)"  # assume repo root is two levels up

BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build_libtorch}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local/libtorch}"
DESIRED_PYTHON="${DESIRED_PYTHON:-3.10}"

EXTRA_CMAKE_ARGS="${EXTRA_CMAKE_ARGS:-}"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Building libtorch in $BUILD_DIR"
echo "Install prefix: $INSTALL_PREFIX"
echo "Python version (optional, for build tools): $DESIRED_PYTHON"

cmake "$ROOT_DIR" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_PYTHON=OFF \
    -DBUILD_TEST=ON \
    -DBUILD_BINARY=ON \
    -DUSE_CUDA=${USE_CUDA:-ON} \
    -DUSE_NVSHMEM=${USE_NVSHMEM:-OFF} \
    -DUSE_CUSPARSELT=${USE_CUSPARSELT:-OFF} \
    $EXTRA_CMAKE_ARGS

cmake --build . --target install -- -j"$(nproc)"

echo "libtorch build and installation completed at $INSTALL_PREFIX"
