#!/usr/bin/env bash
set -euo pipefail

[[ "${DEBUG:-}" == "1" ]] && set -x

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <yaml-file>" >&2
  exit 1
fi

INPUT_PATH="$1"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

NORMALIZER="$REPO_ROOT/codegen_validation/normalize_yaml_fragment.py"

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Error: file not found: $INPUT_PATH" >&2
  exit 1
fi

if [[ ! -x "$NORMALIZER" ]]; then
  echo "Error: normalizer script not executable" >&2
  exit 1
fi

TMP_FILE="$(mktemp "${INPUT_PATH}.XXXXXX")"
trap 'rm -f "$TMP_FILE"' EXIT

"$NORMALIZER" < "$INPUT_PATH" > "$TMP_FILE"

mv -- "$TMP_FILE" "$INPUT_PATH"
trap - EXIT
