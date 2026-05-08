#!/usr/bin/env bash
# task4 — Boltz-2 co-fold on full 570 pool.
# Production: 570 compounds (~10 GPU-h on A100)
# Test:       1 compound (~3 min on A100, 12 min on RTX 5050)
set -euo pipefail

TASK_ID="task4"
TASK_NAME="Boltz-2 co-folding on full 570 pool with TBXT G177D"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

# Boltz-specific env vars (some GPU stacks need these)
export CC="${CC:-${CONDA_PREFIX}/bin/gcc}"
export CXX="${CXX:-${CONDA_PREFIX}/bin/g++}"
NVRTC_LIB="$CONDA_PREFIX/lib/python3.12/site-packages/nvidia/cu13/lib"
[ -d "$NVRTC_LIB" ] && export LD_LIBRARY_PATH="$NVRTC_LIB:$LD_LIBRARY_PATH"

FAST_FLAG=""
if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -2 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    FAST_FLAG="--fast"
    log_info "TEST MODE: 1 compound, --fast (1 sample × 25 steps)"
else
    INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"
    log_info "PRODUCTION: $(wc -l < "$INPUT_CSV") compounds"
fi

OUT_DIR="$DATA_DIR/boltz_runs"
mkdir -p "$OUT_DIR"

run_python "$TBXT_ROOT/scripts/run_boltz.py" \
    --smiles-csv "$INPUT_CSV" \
    --out-dir "$OUT_DIR" $FAST_FLAG || { _end FAIL; exit 1; }

# Boltz writes its summary to data/boltz/boltz_summary.csv (legacy path);
# move/copy into our trial dir for shareable JSON
SUMMARY_CSV="$TBXT_ROOT/data/boltz/boltz_summary.csv"
[ -f "$SUMMARY_CSV" ] && cp "$SUMMARY_CSV" "$DATA_DIR/boltz_summary.csv" && SUMMARY_CSV="$DATA_DIR/boltz_summary.csv"

EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$SUMMARY_CSV" "$INPUT_CSV" <<'PYEOF'
import csv, json, sys, os, statistics
out, csv_path, input_csv = sys.argv[1:]
rows = []
n_input = sum(1 for _ in open(input_csv)) - 1
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        if r.get("status") == "ok":
            rows.append({
                "id": r["cid"],
                "smiles": r.get("smiles", ""),
                "pLDDT":   float(r.get("pLDDT", 0)) if r.get("pLDDT") else None,
                "ipTM":    float(r.get("ipTM", 0)) if r.get("ipTM") else None,
                "affinity_kd_uM": float(r.get("affinity_kd_uM", 0)) if r.get("affinity_kd_uM") else None,
                "affinity_pkd":   float(r.get("affinity_pkd", 0)) if r.get("affinity_pkd") else None,
                "prob_binder":    float(r.get("affinity_prob_binder", 0)) if r.get("affinity_prob_binder") else None,
            })
n_ok = len(rows)
binders = [r for r in rows if r["prob_binder"] is not None and r["prob_binder"] >= 0.5]
ipTMs = [r["ipTM"] for r in rows if r["ipTM"] is not None]
top50 = sorted(rows, key=lambda r: -(r["affinity_pkd"] or 0))[:50]
data = {
    "input": {"n": n_input, "source": input_csv},
    "processed": {"n_ok": n_ok, "n_failed": n_input - n_ok},
    "summary_stats": {
        "n_predicted_binders":  len(binders),
        "mean_ipTM": round(statistics.mean(ipTMs), 4) if ipTMs else None,
        "mean_pkd":  round(statistics.mean(r["affinity_pkd"] for r in rows if r["affinity_pkd"] is not None), 4) if rows else None,
    },
    "top_50_ids": [r["id"] for r in top50],
    "top_50_results": top50,
    "all_results": rows,
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

# Determine final status from extras: if 0 compounds processed, the Boltz run failed silently
N_OK=$(python -c "import json; d=json.load(open('$EXTRAS')); print(d.get('processed', {}).get('n_ok', 0))")
if [ "$N_OK" = "0" ]; then
    log_warn "Boltz produced 0 successful results — check log for import/CUDA errors"
    _end FAIL "$EXTRAS"
else
    _end OK "$EXTRAS"
fi
