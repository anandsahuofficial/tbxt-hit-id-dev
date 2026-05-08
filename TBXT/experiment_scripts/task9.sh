#!/usr/bin/env bash
# task9 — Pose renders + slide assets.
# Production: top 8 picks (4 final + 4 backups) × 2D + 3D
# Test:       1 pick × 2D only
set -euo pipefail

TASK_ID="task9"
TASK_NAME="Pose renders (PyMOL 3D + RDKit 2D) for slide deck"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

# pymol-open-source is needed
if ! python -c "import pymol" 2>/dev/null; then
    log_warn "pymol-open-source not installed; installing..."
    conda install -y --override-channels -c conda-forge pymol-open-source || true
fi

if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -2 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    MAX_PICKS=1
    log_info "TEST MODE: 1 pick"
else
    INPUT_CSV="$TBXT_ROOT/data/tier_a/tier_a_candidates.csv"
    [ -f "$INPUT_CSV" ] || INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"
    MAX_PICKS=8
    log_info "PRODUCTION: top 8 picks"
fi

OUT_DIR="$DATA_DIR/renders"
mkdir -p "$OUT_DIR"

run_python "$TBXT_ROOT/scripts/team/render_poses.py" \
    --top-4 "$INPUT_CSV" \
    --pose-dir "$TBXT_ROOT/data/full_pool_gnina_F/poses" \
    --receptor "$TBXT_ROOT/data/dock/receptor/6F59_apo.pdb" \
    --out-dir "$OUT_DIR" \
    --max-picks "$MAX_PICKS" || { _end FAIL; exit 1; }

EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$OUT_DIR" "$INPUT_CSV" <<'PYEOF'
import csv, json, sys, os
out, render_dir, input_csv = sys.argv[1:]
renders = sorted(os.listdir(render_dir)) if os.path.isdir(render_dir) else []
n_3d = sum(1 for f in renders if f.endswith("_pose_3d.png"))
n_2d = sum(1 for f in renders if f.endswith("_2d.png"))
n_input_picks = sum(1 for _ in open(input_csv)) - 1
data = {
    "input": {"n_picks": n_input_picks, "source": input_csv},
    "rendered": {"n_2d": n_2d, "n_3d": n_3d, "files": renders},
    "render_dir": render_dir,
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
