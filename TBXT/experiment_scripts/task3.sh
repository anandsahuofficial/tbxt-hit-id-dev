#!/usr/bin/env bash
# task3 — Site-A GNINA pool dock.
# Production: 570 compounds at site A, exhaustiveness 8 (~50 min A100)
# Test:        5 compounds, exhaustiveness 1 (~30 sec)
set -euo pipefail

TASK_ID="task3"
TASK_NAME="GNINA dock on full 570 pool at site A (diversification)"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -6 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    EXHAUSTIVENESS=1
    log_info "TEST MODE: 5 compounds, exh 1"
else
    INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"
    EXHAUSTIVENESS=8
    log_info "PRODUCTION: $(wc -l < "$INPUT_CSV") compounds, exh 8"
fi

OUT_DIR="$DATA_DIR/gnina_A"
mkdir -p "$OUT_DIR"

run_python "$TBXT_ROOT/scripts/dock_gnina.py" \
    --smiles-csv "$INPUT_CSV" \
    --site A \
    --out-dir "$OUT_DIR" \
    --exhaustiveness "$EXHAUSTIVENESS" || { _end FAIL; exit 1; }

RESULTS_CSV="$OUT_DIR/dock_results_gnina.csv"
EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$RESULTS_CSV" "$EXHAUSTIVENESS" "$INPUT_CSV" <<'PYEOF'
import csv, json, sys, statistics, os
out, csv_path, exh, input_csv = sys.argv[1:]
rows = []
n_input = sum(1 for _ in open(input_csv)) - 1
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        if r.get("status") == "ok":
            rows.append({
                "id": r["id"],
                "smiles": r["smiles"],
                "cnn_pose": float(r["best_cnn_pose_score"]),
                "cnn_pkd": float(r["best_cnn_affinity_pkd"]),
                "vina_kcal": float(r["best_vina_kcal"]),
                "kd_uM": float(r["best_cnn_affinity_uM"]),
            })
n_ok = len(rows)
n_tier_a_at_A = sum(1 for r in rows
                    if r["cnn_pose"] >= 0.5 and r["cnn_pkd"] >= 4.5 and r["vina_kcal"] <= -6.0)
top50 = sorted(rows, key=lambda r: -(r["cnn_pose"]*4.0 + r["cnn_pkd"]*0.3 - r["vina_kcal"]*0.2))[:50]
data = {
    "config": {"exhaustiveness": int(exh), "site": "A"},
    "input": {"n": n_input, "source": input_csv},
    "processed": {"n_ok": n_ok, "n_failed": n_input - n_ok},
    "summary_stats": {
        "mean_cnn_pose":  round(statistics.mean(r["cnn_pose"]  for r in rows), 4) if rows else None,
        "mean_cnn_pkd":   round(statistics.mean(r["cnn_pkd"]   for r in rows), 4) if rows else None,
        "mean_vina":      round(statistics.mean(r["vina_kcal"] for r in rows), 4) if rows else None,
        "n_tier_a_at_A":  n_tier_a_at_A,
    },
    "top_50_ids": [r["id"] for r in top50],
    "top_50_results": top50,
    "all_results": rows,
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
