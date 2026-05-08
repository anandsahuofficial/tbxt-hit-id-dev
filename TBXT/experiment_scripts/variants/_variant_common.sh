#!/usr/bin/env bash
# Shared helpers for overnight variant scripts.
# Each variant<N>.sh sources this and the main _common.sh, then sets
# VARIANT_NAME early so all output paths route to a variant-isolated dir.
#
# Output isolation:
#   data:    $TBXT_ROOT/data/variants/<VARIANT_NAME>/
#   logs:    $TBXT_ROOT/data/logs/variants/<VARIANT_NAME>.log
#   report:  $TBXT_ROOT/report/variants/<VARIANT_NAME>/

set -euo pipefail

# Resolve TBXT root from the variant script location:
#   experiment_scripts/variants/_variant_common.sh -> TBXT/
_VARIANT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT_ROOT="${TBXT_ROOT:-$(cd "$_VARIANT_DIR/../.." && pwd)}"

# Activate the conda env via direct `source $CONDA_DIR/bin/activate $ENV_NAME`
# (no `conda activate <name>` — simpler, faster, no conda-hook dependency).
# Works for both `conda create`d envs (no env-local bin/activate) and
# conda-pack'd envs.
# Honors $CONDA_DIR if set (HPC submissions install conda at project
# space /projectnb/.../Hackathon/miniconda3 because /usr3/graduate is
# quota-limited). Falls back to $HOME/miniconda3 for laptop installs.
_VARIANT_CONDA_DIR="${CONDA_DIR:-$HOME/miniconda3}"
_VARIANT_ENV_NAME="${ENV_NAME:-tbxt}"
_VARIANT_ENV_DIR="$_VARIANT_CONDA_DIR/envs/$_VARIANT_ENV_NAME"
if [ -d "$_VARIANT_ENV_DIR" ] && [ -x "$_VARIANT_CONDA_DIR/bin/activate" ]; then
    set +u
    source "$_VARIANT_CONDA_DIR/bin/activate" "$_VARIANT_ENV_NAME"
    export LD_LIBRARY_PATH="$_VARIANT_ENV_DIR/lib:${LD_LIBRARY_PATH:-}"
    set -u
elif [ -f "$_VARIANT_ENV_DIR/bin/activate" ]; then
    set +u
    source "$_VARIANT_ENV_DIR/bin/activate"
    export LD_LIBRARY_PATH="$_VARIANT_ENV_DIR/lib:${LD_LIBRARY_PATH:-}"
    set -u
fi

variant_log() {
    printf "[\033[36mvariant %s\033[0m %s] %s\n" \
        "${VARIANT_NAME:-?}" "$(date +%H:%M:%S)" "$*"
}

variant_setup() {
    [ -n "${VARIANT_NAME:-}" ] || { echo "VARIANT_NAME unset"; exit 1; }
    VARIANT_DATA_DIR="$TBXT_ROOT/data/variants/$VARIANT_NAME"
    VARIANT_REPORT_DIR="$TBXT_ROOT/report/variants/$VARIANT_NAME"
    VARIANT_LOG_DIR="$TBXT_ROOT/data/logs/variants"
    mkdir -p "$VARIANT_DATA_DIR" "$VARIANT_REPORT_DIR" "$VARIANT_LOG_DIR"
    VARIANT_LOG="$VARIANT_LOG_DIR/$VARIANT_NAME.log"
    # Tee everything to the log as well as stdout
    exec > >(tee -a "$VARIANT_LOG") 2>&1
    variant_log "BEGIN  output_dir=$VARIANT_DATA_DIR"
}

variant_done() {
    local status="${1:-OK}"
    variant_log "END    status=$status  output_dir=$VARIANT_DATA_DIR  report=$VARIANT_REPORT_DIR"
}
