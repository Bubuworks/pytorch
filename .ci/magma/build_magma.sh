#!/usr/bin/env bash

set -eu -o pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

: "${PACKAGE_NAME:?PACKAGE_NAME must be set}"
: "${DESIRED_CUDA:?DESIRED_CUDA must be set}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAGMA_VERSION=2.6.1

PACKAGE_FILES="${ROOT_DIR}/magma/package_files"
PACKAGE_DIR="${ROOT_DIR}/magma/${PACKAGE_NAME}"
PACKAGE_OUTPUT="${ROOT_DIR}/magma/output"
PACKAGE_BUILD="${PACKAGE_DIR}/build"
PACKAGE_RECIPE="${PACKAGE_BUILD}/info/recipe"
PACKAGE_LICENSE="${PACKAGE_BUILD}/info/licenses"

mkdir -p "${PACKAGE_DIR}" "${PACKAGE_OUTPUT}/linux-64" "${PACKAGE_BUILD}" "${PACKAGE_RECIPE}" "${PACKAGE_LICENSE}"

pushd "${PACKAGE_DIR}" >/dev/null
MAGMA_TARBALL="magma-${MAGMA_VERSION}.tar.gz"

if [[ ! -f "${MAGMA_TARBALL}" ]]; then
    echo "Downloading MAGMA ${MAGMA_VERSION}..."
    curl -LO --retry 3 --retry-all-errors "http://icl.utk.edu/projectsfiles/magma/downloads/${MAGMA_TARBALL}"
fi

tar zxf "${MAGMA_TARBALL}"
sha256sum --check < "${PACKAGE_FILES}/magma-${MAGMA_VERSION}.sha256"
popd >/dev/null

pushd "${PACKAGE_DIR}/magma-${MAGMA_VERSION}" >/dev/null
for patchfile in CMake.patch cmakelists.patch thread_queue.patch cuda13.patch getrf_shfl.patch getrf_nbparam.patch; do
    patch_path="${PACKAGE_FILES}/${patchfile}"
    echo "Applying patch: ${patch_path}"
    if [[ "$patchfile" == "CMake.patch" || "$patchfile" == "cmakelists.patch" ]]; then
        patch < "${patch_path}"
    elif [[ "$patchfile" == "thread_queue.patch" ]]; then
        patch -p0 < "${patch_path}"
    else
        patch -p1 < "${patch_path}"
    fi
done

export INSTALL_DIR="${PACKAGE_BUILD}"
"${PACKAGE_FILES}/build.sh"
popd >/dev/null

for file in build.sh cuda13.patch thread_queue.patch cmakelists.patch getrf_shfl.patch getrf_nbparam.patch CMake.patch magma-${MAGMA_VERSION}.sha256; do
    cp "${PACKAGE_FILES}/${file}" "${PACKAGE_RECIPE}/"
done
cp "${PACKAGE_DIR}/magma-${MAGMA_VERSION}/COPYRIGHT" "${PACKAGE_LICENSE}/COPYRIGHT"

pushd "${PACKAGE_BUILD}" >/dev/null
tar cjf "${PACKAGE_OUTPUT}/linux-64/${PACKAGE_NAME}-${MAGMA_VERSION}-1.tar.bz2" include lib info
echo "Built package at ${PACKAGE_OUTPUT}/linux-64/${PACKAGE_NAME}-${MAGMA_VERSION}-1.tar.bz2"
popd >/dev/null
