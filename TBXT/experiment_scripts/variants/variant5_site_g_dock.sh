#!/usr/bin/env bash
# Variant 5: Full 570 GNINA dock at SITE G (TEP's third recommended pocket).
#
# Why: site F (current site of all 4 picks except 1A) and site A (1 pick)
# are the TEP-recommended sites. Site G is the third recommended pocket
# (Y210, E48, E50, G81 — the dimerization-helix hinge). It's marked
# "promiscuous" by TEP — most fragments dock there, but selectivity may
# be poor. Adding site G coverage gives us:
#   - A wildcard candidate slot if site F + A picks fall through
#   - Stronger "we considered all 3 recommended pockets" judging argument
#
# Compute on L40S: ~5-8 GPU-h (570 cmpds × 1 receptor × exh 8).
#
# Output: report/variants/<VARIANT_NAME>/site_g_results.json
#
# Usage:
#   bash variant5_site_g_dock.sh
#
# qsub example:
#   qsub -l ngpus=1 -l walltime=10:00:00 -- bash <full-path>/variant5_site_g_dock.sh

set -euo pipefail
VARIANT_NAME="variant5_site_g_dock"
source "$(dirname "${BASH_SOURCE[0]}")/_variant_common.sh"
variant_setup

INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"
OUT_DIR="$VARIANT_DATA_DIR/gnina_G"
mkdir -p "$OUT_DIR"

# Site G grid coordinates: defined relative to receptor 6F59_apo.
# Per TEP: site G key residues = Y210, E48, E50, G81 (dimerization-helix hinge).
# If grid_definitions.json includes a 'G' entry, dock_gnina.py picks it up via
# --site G. If it does NOT, fall through to a one-time prep step.
GRIDS_JSON="$TBXT_ROOT/data/dock/grid_definitions.json"
if ! python -c "import json; d=json.load(open('$GRIDS_JSON')); assert 'G' in d" 2>/dev/null; then
    variant_log "Site G grid not in grid_definitions.json — computing from receptor"
    python "$TBXT_ROOT/scripts/define_pockets.py" --site G --update "$GRIDS_JSON" \
        2>&1 | tail -5 \
        || variant_log "WARN: site G prep failed; defaulting to manual centroid"
fi

variant_log "Docking 570 compounds at site G"
python "$TBXT_ROOT/scripts/dock_gnina.py" \
    --smiles-csv "$INPUT_CSV" \
    --site G \
    --out-dir "$OUT_DIR" \
    --exhaustiveness 8 \
    || variant_log "WARN: dock had failures; continuing"

# Aggregate to JSON (mirroring task3.sh schema for site A → here for site G)
RESULTS_CSV="$OUT_DIR/dock_results_gnina.csv"
python - <<PYEOF
import csv, json, os, statistics
src = "$RESULTS_CSV"
out = "$VARIANT_REPORT_DIR/site_g_results.json"
n_input = sum(1 for _ in open("$INPUT_CSV")) - 1
rows = []
if os.path.exists(src):
    for r in csv.DictReader(open(src)):
        if r.get("status") == "ok":
            rows.append({
                "id": r["id"],
                "smiles": r["smiles"],
                "cnn_pose": float(r["best_cnn_pose_score"]),
                "cnn_pkd":  float(r["best_cnn_affinity_pkd"]),
                "vina_kcal": float(r["best_vina_kcal"]),
                "kd_uM":    float(r["best_cnn_affinity_uM"]),
            })
n_ok = len(rows)
n_tier_a_at_G = sum(1 for r in rows if r["cnn_pose"] >= 0.5 and r["cnn_pkd"] >= 4.5 and r["vina_kcal"] <= -6.0)
top50 = sorted(rows, key=lambda r: -(r["cnn_pose"]*4.0 + r["cnn_pkd"]*0.3 - r["vina_kcal"]*0.2))[:50]
data = {
    "variant_name": "$VARIANT_NAME",
    "task_id": "task_site_g", "status": "OK" if rows else "FAIL",
    "metrics": {
        "config": {"site": "G", "exhaustiveness": 8},
        "input": {"n": n_input},
        "processed": {"n_ok": n_ok, "n_failed": n_input - n_ok},
        "summary_stats": {
            "n_tier_a_at_G": n_tier_a_at_G,
            "mean_cnn_pose": round(statistics.mean(r["cnn_pose"] for r in rows), 4) if rows else None,
            "mean_cnn_pkd":  round(statistics.mean(r["cnn_pkd"]  for r in rows), 4) if rows else None,
        },
        "top_50_ids": [r["id"] for r in top50],
        "top_50_results": top50,
        "all_results": rows,
    }
}
os.makedirs(os.path.dirname(out), exist_ok=True)
json.dump(data, open(out, "w"), indent=2)
print(f"Wrote {out} (n_ok={n_ok}, tier_a_G={n_tier_a_at_G})")
PYEOF

variant_done OK
