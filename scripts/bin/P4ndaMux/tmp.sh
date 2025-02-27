#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
LIB_DIR="$BASE_DIR/lib"

echo $SCRIPT_DIR
echo $LIB_DIR

P4_USE_COLORS=1
echo $"[ -n "${NO_COLOR}" ]"
if [ -n "${NO_COLOR}" ] || [ -n "${P4_NO_COLOR}" ] || [ ! -t 1 ]; then
  P4_USE_COLORS=0
fi

echo $P4_USE_COLORS
