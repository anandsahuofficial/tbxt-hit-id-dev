#!/usr/bin/env bash
# Variant 3: GNINA on full 570 pool against MULTI-RECEPTOR ENSEMBLE.
#
# Why: rigid-receptor docking is induced-fit-blind. Re-docking against multiple
# receptor conformations (apo, holo+DNA, AlphaFold2 if present) and taking
# min-vina + mean-CNN consensus catches binders that need pocket plasticity.
#
# Receptors used (preference order; uses what's available in
# data/dock/receptor/ensemble/):
#   - 6F59_apo.pdbqt              (G177D apo, primary)
#   - 6F58.pdbqt                  (WT + DNA, alternative conformation)
#   - any other *.pdbqt in the ensemble dir
#
# Compute on L40S: ~10-15 GPU-h (570 cmpds × 2-3 receptors × exh 8).
#
# Output: report/variants/<VARIANT_NAME>/ensemble_consensus.csv
#
# Usage:
#   bash variant3_receptor_ensemble.sh
#
# qsub example (PBS):
#   qsub -l ngpus=1 -l walltime=18:00:00 -- bash <full-path>/variant3_receptor_ensemble.sh

set -euo pipefail
VARIANT_NAME="variant3_receptor_ensemble"
source "$(dirname "${BASH_SOURCE[0]}")/_variant_common.sh"
variant_setup

ENSEMBLE_DIR="$TBXT_ROOT/data/dock/receptor/ensemble"
INPUT_CSV="$TBXT_ROOT/data/full_pool_input.csv"

# Discover receptors. Always include the primary 6F59_apo.
RECEPTORS=("$TBXT_ROOT/data/dock/receptor/6F59_apo.pdbqt")
if [ -d "$ENSEMBLE_DIR" ]; then
    while IFS= read -r r; do
        # Skip the primary if it shows up again
        [ "$(basename "$r")" = "6F59_apo.pdbqt" ] && continue
        RECEPTORS+=("$r")
    done < <(find "$ENSEMBLE_DIR" -maxdepth 1 -name "*.pdbqt" | head -3)
fi

variant_log "Docking against ${#RECEPTORS[@]} receptor conformation(s):"
for r in "${RECEPTORS[@]}"; do variant_log "  $(basename "$r")"; done

# Dock against each receptor in series.  scripts/dock_ensemble.py supports a
# directory of receptors but to keep this variant self-contained we drive
# scripts/dock_gnina.py per receptor and aggregate ourselves.
ALL_RESULTS=()
for receptor in "${RECEPTORS[@]}"; do
    name="$(basename "$receptor" .pdbqt)"
    out_dir="$VARIANT_DATA_DIR/dock_$name"
    mkdir -p "$out_dir"
    variant_log "  -> docking against $name (this is the slow step)"
    python "$TBXT_ROOT/scripts/dock_gnina.py" \
        --smiles-csv "$INPUT_CSV" \
        --site F \
        --out-dir "$out_dir" \
        --exhaustiveness 8 \
        --receptor-pdbqt "$receptor" 2>&1 | tail -10 \
        || variant_log "  WARN: dock against $name had failures; continuing"
    ALL_RESULTS+=("$out_dir/dock_results_gnina.csv:$name")
done

# Aggregate: min-vina + mean-CNN-pose + mean-CNN-pKd across receptors
variant_log "Aggregating ensemble consensus"
python - <<PYEOF
import csv, json, os, statistics
csvs = [s.split(":") for s in """$(IFS=$'\n'; echo "${ALL_RESULTS[*]}")""".strip().split("\n") if s.strip()]
print(f"Aggregating {len(csvs)} per-receptor result CSVs")

per_compound = {}  # cid -> list of dicts (one per receptor)
for csv_path, receptor_name in csvs:
    if not os.path.exists(csv_path): continue
    for r in csv.DictReader(open(csv_path)):
        if r.get("status") != "ok": continue
        cid = r["id"]
        per_compound.setdefault(cid, []).append({
            "receptor": receptor_name,
            "smiles":   r["smiles"],
            "vina":     float(r["best_vina_kcal"]),
            "cnn_pose": float(r["best_cnn_pose_score"]),
            "cnn_pkd":  float(r["best_cnn_affinity_pkd"]),
        })

rows = []
for cid, recs in per_compound.items():
    rows.append({
        "id": cid,
        "smiles": recs[0]["smiles"],
        "n_receptors": len(recs),
        "vina_min":      round(min(r["vina"] for r in recs), 3),
        "vina_mean":     round(statistics.mean(r["vina"] for r in recs), 3),
        "cnn_pose_mean": round(statistics.mean(r["cnn_pose"] for r in recs), 4),
        "cnn_pose_max":  round(max(r["cnn_pose"] for r in recs), 4),
        "cnn_pkd_mean":  round(statistics.mean(r["cnn_pkd"] for r in recs), 3),
        "cnn_pkd_max":   round(max(r["cnn_pkd"] for r in recs), 3),
    })

# Composite using ENSEMBLE-AGGREGATED scores (min-vina, mean-CNN)
def composite(r):
    return r["cnn_pose_mean"] * 4.0 + r["cnn_pkd_mean"] * 0.3 - r["vina_min"] * 0.2
rows.sort(key=composite, reverse=True)

n_input = sum(1 for _ in open("$INPUT_CSV")) - 1
n_tier_a = sum(1 for r in rows if r["cnn_pose_mean"] >= 0.5 and r["cnn_pkd_mean"] >= 4.5 and r["vina_min"] <= -6.0)
out_csv = "$VARIANT_DATA_DIR/ensemble_consensus.csv"
cols = ["id","smiles","n_receptors","vina_min","vina_mean",
        "cnn_pose_mean","cnn_pose_max","cnn_pkd_mean","cnn_pkd_max"]
with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=cols); w.writeheader(); w.writerows(rows)
print(f"Wrote {out_csv}")

# JSON report
out_json = "$VARIANT_REPORT_DIR/ensemble_consensus.json"
data = {
    "variant_name": "$VARIANT_NAME",
    "task_id": "task2_ensemble",
    "status": "OK" if rows else "FAIL",
    "metrics": {
        "config": {"n_receptors": len(csvs), "exhaustiveness": 8},
        "input": {"n": n_input},
        "processed": {"n_ok": len(rows)},
        "summary_stats": {"n_tier_a_ensemble": n_tier_a},
        "top_50_ids": [r["id"] for r in rows[:50]],
        "top_50_results": rows[:50],
    }
}
os.makedirs(os.path.dirname(out_json), exist_ok=True)
json.dump(data, open(out_json, "w"), indent=2)
print(f"Wrote {out_json} (n_tier_a={n_tier_a}, n_ok={len(rows)})")
PYEOF

variant_done OK
