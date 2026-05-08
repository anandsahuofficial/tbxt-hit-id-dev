#!/usr/bin/env bash
# TBXT smoke test wrapper. Run AFTER setup.sh has completed.
# Activates the conda env, sets LD_LIBRARY_PATH, runs tests/smoke_test.py.
# Exits 0 on success, non-zero on any failure.
#
# Usage:
#   bash smoke_test.sh
#
# That's it. No arguments, no env vars needed.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CONDA_DIR="${CONDA_DIR:-$HOME/miniconda3}"
ENV_NAME="${ENV_NAME:-tbxt}"

if [ ! -f "$CONDA_DIR/etc/profile.d/conda.sh" ]; then
    echo "ERROR: conda not found at $CONDA_DIR. Run setup.sh first." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"

if [ ! -d "$CONDA_PREFIX" ]; then
    echo "ERROR: conda env '$ENV_NAME' not found. Run setup.sh first." >&2
    exit 1
fi

export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"

cd "$HERE"
exec python tests/smoke_test.py
