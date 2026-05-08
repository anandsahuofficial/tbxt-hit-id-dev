#!/usr/bin/env bash
# task2 — Multi-seed GNINA on full 570 pool at site F.
# Production: 570 compounds × 10 seeds × exh 8 (~8 GPU-h on A100)
# Test:        5 compounds ×  2 seeds × exh 1 (~30 sec)
set -euo pipefail

TASK_ID="task2"
TASK_NAME="Multi-seed GNINA on full 570 pool at site F"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

# Production vs test parameters
if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -6 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    SEEDS=2
    EXHAUSTIVENESS=1
    SITE="F"
    log_info "TEST MODE: 5 compounds × 2 seeds × exh 1"
else
    INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"
    SEEDS=10
    EXHAUSTIVENESS=8
    SITE="F"
    log_info "PRODUCTION: $(wc -l < "$INPUT_CSV") compounds × 10 seeds × exh 8"
fi

OUT_DIR="$DATA_DIR/gnina_results"
mkdir -p "$OUT_DIR"

# Run multi-seed GNINA. The Python script supports per-compound checkpointing
# via the existence of pose files in the output dir.
run_python "$TBXT_ROOT/scripts/team/dock_gnina_multiseed.py" \
    --smiles-csv "$INPUT_CSV" \
    --site "$SITE" \
    --out-dir "$OUT_DIR" \
    --seeds "$SEEDS" \
    --exhaustiveness "$EXHAUSTIVENESS" || { _end FAIL; exit 1; }

# Build extras JSON: per-compound results + summary stats + top-50
RESULTS_CSV="$OUT_DIR/dock_results_multiseed.csv"
EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$RESULTS_CSV" "$SEEDS" "$EXHAUSTIVENESS" "$SITE" "$INPUT_CSV" <<'PYEOF'
import csv, json, sys, statistics
out, csv_path, seeds, exh, site, input_csv = sys.argv[1:]
rows = []
n_input = sum(1 for _ in open(input_csv)) - 1
if not __import__("os").path.exists(csv_path):
    json.dump({"status_detail": "no_results_csv", "n_input": n_input}, open(out, "w"), indent=2)
    sys.exit(0)
for r in csv.DictReader(open(csv_path)):
    if r.get("status") == "ok":
        rows.append({
            "id": r["id"],
            "smiles": r["smiles"],
            "cnn_pose_mean": float(r["cnn_pose_mean"]),
            "cnn_pose_stdev": float(r["cnn_pose_stdev"]),
            "cnn_pkd_mean":  float(r["cnn_pkd_mean"]),
            "vina_kcal_mean": float(r["vina_kcal_mean"]),
            "kd_uM_from_cnn_mean": float(r["kd_uM_from_cnn_mean"]),
            "n_seeds": int(r["n_seeds"]),
        })
n_ok = len(rows)
n_failed = n_input - n_ok
poses = [r["cnn_pose_mean"] for r in rows]
pkds = [r["cnn_pkd_mean"] for r in rows]
vinas = [r["vina_kcal_mean"] for r in rows]
n_tier_a = sum(1 for r in rows
               if r["cnn_pose_mean"] >= 0.5 and r["cnn_pkd_mean"] >= 4.5 and r["vina_kcal_mean"] <= -6.0)
def composite(r):
    return r["cnn_pose_mean"] * 4.0 + r["cnn_pkd_mean"] * 0.3 - r["vina_kcal_mean"] * 0.2
top50 = sorted(rows, key=composite, reverse=True)[:50]
data = {
    "config": {"seeds": int(seeds), "exhaustiveness": int(exh), "site": site},
    "input": {"n": n_input, "source": input_csv},
    "processed": {"n_ok": n_ok, "n_failed": n_failed},
    "summary_stats": {
        "mean_cnn_pose": round(statistics.mean(poses), 4) if poses else None,
        "stdev_cnn_pose": round(statistics.stdev(poses), 4) if len(poses) > 1 else None,
        "mean_cnn_pkd":  round(statistics.mean(pkds), 4) if pkds else None,
        "mean_vina":     round(statistics.mean(vinas), 4) if vinas else None,
        "n_tier_a": n_tier_a,
    },
    "top_50_ids": [r["id"] for r in top50],
    "top_50_results": top50,
    "all_results": rows,  # full per-compound table (small)
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
