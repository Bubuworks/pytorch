#!/usr/bin/env bash
set -eu -o pipefail
[[ "${DEBUG:-}" == "1" ]] && set -x

LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LOCAL_DIR/../.." && pwd)"
TEST_DIR="$ROOT_DIR/test"

GTEST_REPORTS_DIR="$TEST_DIR/test-reports/cpp"
PYTEST_REPORTS_DIR="$TEST_DIR/test-reports/python"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local/caffe2}"

PYTHON="$(command -v python || true)"
if [[ "${BUILD_ENVIRONMENT:-}" =~ py((2|3)\.?[0-9]?\.?[0-9]?) ]]; then
    PYTHON="$(command -v "python${BASH_REMATCH[1]}" || true)"
fi
if [[ -z "$PYTHON" ]]; then
    echo "Error: Python not found for BUILD_ENVIRONMENT=${BUILD_ENVIRONMENT:-}"
    exit 1
fi

if [[ "${BUILD_ENVIRONMENT:-}" == *rocm* ]]; then
    unset HIP_PLATFORM
    if command -v sccache >/dev/null 2>&1; then
        sccache --stop-server || true
        SCCACHE_ERROR_LOG="${SCCACHE_ERROR_LOG:-$HOME/sccache_error.log}"
        rm -f "$SCCACHE_ERROR_LOG" || true
        SCCACHE_IDLE_TIMEOUT=0 SCCACHE_ERROR_LOG="$SCCACHE_ERROR_LOG" sccache --start-server
        sccache --zero-stats
    fi
fi

mkdir -p "$GTEST_REPORTS_DIR" "$PYTEST_REPORTS_DIR" "$INSTALL_PREFIX"
