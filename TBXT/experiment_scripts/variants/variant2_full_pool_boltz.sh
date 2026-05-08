#!/usr/bin/env bash
# Variant 2: Boltz-2 co-folding on the FULL 570 pool (currently top 30 only).
#
# Why: prob_binder is our cleanest binder/non-binder discriminator. Extending
# from top-30 to full 570 gives every compound in the pool an independent
# Boltz signal. Strengthens consensus + lets us re-rank picks with full
# Boltz coverage.
#
# Compute on L40S: ~12-16 GPU-h (570 cmpds × 3 samples × 200 sampling steps
# × 3 recycling × ~1.5-2 min/cmpd at L40S throughput).
#
# Output: report/variants/<VARIANT_NAME>/task4_full_pool.json
#
# Usage:
#   bash variant2_full_pool_boltz.sh
#
# qsub example (PBS):
#   qsub -l ngpus=1 -l walltime=20:00:00 -- bash <full-path>/variant2_full_pool_boltz.sh

set -euo pipefail
VARIANT_NAME="variant2_full_pool_boltz"
source "$(dirname "${BASH_SOURCE[0]}")/_variant_common.sh"
variant_setup

INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"
N=$(($(wc -l < "$INPUT_CSV") - 1))
variant_log "Boltz on full pool: $N compounds"

OUT_DIR="$VARIANT_DATA_DIR/boltz_runs"
mkdir -p "$OUT_DIR"

run_python_safe() {
    python "$@"
}

# Use the existing run_boltz.py with full pool. It already has --fast for
# smoke; we use production settings (no --fast).
variant_log "Running Boltz with production settings (3 samples × 200 steps × 3 recycle)"
python "$TBXT_ROOT/scripts/run_boltz.py" \
    --smiles-csv "$INPUT_CSV" \
    --out-dir "$OUT_DIR" \
    || variant_log "WARN: some Boltz runs failed; continuing"

# Aggregate the per-compound boltz outputs into a single JSON report
SUMMARY_CSV="$TBXT_ROOT/data/boltz/boltz_summary.csv"
[ -f "$SUMMARY_CSV" ] && cp "$SUMMARY_CSV" "$VARIANT_DATA_DIR/boltz_summary.csv"
SUMMARY_CSV="$VARIANT_DATA_DIR/boltz_summary.csv"

python - <<PYEOF
import csv, json, os, statistics
src = "$SUMMARY_CSV"
out = "$VARIANT_REPORT_DIR/task4_full_pool.json"
n_input = $N

rows = []
if os.path.exists(src):
    for r in csv.DictReader(open(src)):
        if r.get("status") != "ok": continue
        try:
            rows.append({
                "id": r["cid"],
                "smiles": r.get("smiles", ""),
                "pLDDT": float(r.get("pLDDT", 0) or 0) or None,
                "ipTM": float(r.get("ipTM", 0) or 0) or None,
                "affinity_kd_uM": float(r.get("affinity_kd_uM", 0) or 0) or None,
                "affinity_pkd": float(r.get("affinity_pkd", 0) or 0) or None,
                "prob_binder": float(r.get("affinity_prob_binder", 0) or 0) or None,
            })
        except Exception:
            pass

n_ok = len(rows)
binders = [r for r in rows if (r["prob_binder"] or 0) >= 0.5]
top50 = sorted(rows, key=lambda r: -(r.get("affinity_pkd") or 0))[:50]

data = {
    "variant_name": "$VARIANT_NAME",
    "task_id": "task4",
    "task_name": "Boltz-2 co-fold on full pool",
    "status": "OK" if n_ok > 0 else "FAIL",
    "metrics": {
        "config": {"samples": 3, "sampling_steps": 200, "recycling": 3},
        "input": {"n": n_input, "source": "full_pool_input.csv"},
        "processed": {"n_ok": n_ok, "n_failed": n_input - n_ok},
        "summary_stats": {
            "n_predicted_binders":  len(binders),
            "mean_prob_binder":     round(statistics.mean(r["prob_binder"] for r in rows if r["prob_binder"] is not None), 4) if rows else None,
            "mean_kd_uM":           round(statistics.mean(r["affinity_kd_uM"] for r in rows if r["affinity_kd_uM"] is not None), 3) if rows else None,
        },
        "top_50_ids": [r["id"] for r in top50],
        "top_50_results": top50,
        "all_results": rows,
    }
}
os.makedirs(os.path.dirname(out), exist_ok=True)
json.dump(data, open(out, "w"), indent=2)
print(f"Wrote {out} (n_ok={n_ok})")
PYEOF

variant_done OK
