#!/usr/bin/env bash
set -euo pipefail

YAML_FILENAME="verbatim-sources/workflows-pytorch-ge-config-tests.yml"
DIFF_TOOL="meld"

# Resolve script directory safely (handles spaces, symlinks)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Go to repo root (one level above script dir)
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# Dependency checks
command -v "$DIFF_TOOL" >/dev/null 2>&1 || {
  echo "Error: '$DIFF_TOOL' is not installed or not on PATH" >&2
  exit 1
}

NORMALIZER="$REPO_ROOT/codegen_validation/normalize_yaml_fragment.py"
if [[ ! -x "$NORMALIZER" ]]; then
  echo "Error: normalize_yaml_fragment.py not found or not executable" >&2
  exit 1
fi

YAML_PATH="$REPO_ROOT/$YAML_FILENAME"
if [[ ! -f "$YAML_PATH" ]]; then
  echo "Error: YAML file not found: $YAML_PATH" >&2
  exit 1
fi

# Run diff
"$DIFF_TOOL" \
  "$YAML_PATH" \
  <("$NORMALIZER" < "$YAML_PATH")
