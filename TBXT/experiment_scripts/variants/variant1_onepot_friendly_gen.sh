#!/usr/bin/env bash
# Variant 1: Onepot-friendly compound generation.
#
# Why: per arXiv:2601.12603, onepot CORE = enumerate(7 reactions × ~320K BBs)
# + ML feasibility filter. Our existing pool was generated via BRICS recombination
# and analog enumeration — likely OFF-distribution from CORE. This variant
# generates NEW compounds that are GUARANTEED reachable via the 7 onepot reactions
# from a small public BB set, then scores them with our existing pipeline.
#
# Approach (CPU-light, GPU for scoring):
#   1. Pull a curated BB sample (~200-500 BBs) — public Enamine BB sample
#      sufficient for ~50K enumerated products
#   2. For each BB pair × each of 7 reactions: compute the product SMILES
#      (RDKit reaction SMARTS, forward direction)
#   3. Filter products: drug-like (MW 300-600, LogP 1-5, HBD<6, HBA<12, ring<5,
#      no PAINS), Tanimoto < 0.85 to all 2274 known TBXT compounds
#   4. Dock the surviving products with GNINA at site F (production exh 8)
#   5. Output: report/variants/<VARIANT_NAME>/onepot_friendly_top50.csv
#
# Compute on L40S: ~10-15 GPU-h (depends on # of survivors after filter)
#
# Usage:
#   bash variant1_onepot_friendly_gen.sh [--n-bbs 200] [--top-n-dock 1000]
#
# qsub example (PBS):
#   qsub -l ngpus=1 -l walltime=15:00:00 -- bash <full-path>/variant1_onepot_friendly_gen.sh

set -euo pipefail
VARIANT_NAME="variant1_onepot_friendly_gen"
source "$(dirname "${BASH_SOURCE[0]}")/_variant_common.sh"
variant_setup

# ---- Args (low-touch defaults for HPC submission) ----
N_BBS=200
TOP_N_DOCK=1000
while [ $# -gt 0 ]; do
    case "$1" in
        --n-bbs) N_BBS="$2"; shift 2 ;;
        --top-n-dock) TOP_N_DOCK="$2"; shift 2 ;;
        *) shift ;;
    esac
done

variant_log "config: n_bbs=$N_BBS  top_n_dock=$TOP_N_DOCK"

# ---- Step 1: BB sample ----
# We bundle a curated 250-BB sample in TBXT/data/onepot_bbs_sample.csv
# (committed to repo). If missing, this step downloads a public Enamine
# advanced-collection sample as a fallback.
BB_FILE="$TBXT_ROOT/data/onepot_bbs_sample.csv"
if [ ! -f "$BB_FILE" ]; then
    variant_log "BB sample missing — pulling 250 Enamine BBs (public listing)"
    mkdir -p "$VARIANT_DATA_DIR/bbs"
    python "$TBXT_ROOT/scripts/team/pull_enamine_bbs.py" \
        --n "$N_BBS" --out "$BB_FILE" || {
        variant_log "WARN: BB pull failed; using a tiny seed set"
        echo "smiles,id" > "$BB_FILE"
        # Minimal fallback: 20 well-known BBs spanning amine/acid/halide/boronic/isocyanate
        cat <<'BBEOF' >> "$BB_FILE"
Nc1ccccc1,bb_aniline
Nc1cccc(Br)c1,bb_3-bromoaniline
NC1CC1,bb_cyclopropylamine
NCc1ccncc1,bb_4-pyridylmethanamine
NC1CCN(C)CC1,bb_methylpiperidine
OC(=O)c1ccc(Cl)cc1,bb_4-chlorobenzoic_acid
OC(=O)C1Cc2ccccc2O1,bb_chromene-2-carboxylic_acid
OC(=O)CC1CCNCC1,bb_piperidine-acetic_acid
Brc1ccc(F)cc1,bb_4-fluorobromobenzene
Brc1cccc(C(F)(F)F)c1,bb_3-CF3-bromobenzene
COc1cc(Br)ccc1,bb_3-Br-4-OMe
OB(O)c1ccccc1,bb_phenylboronic_acid
OB(O)c1cccc(N)c1,bb_3-amino-phenylboronic_acid
OB(O)c1ccc(F)cc1,bb_4-F-phenylboronic_acid
ClC(C)c1ccccc1,bb_1-chloroethylbenzene
ClCc1ccc(F)cc1,bb_4-F-benzylchloride
Oc1ccc(C2Cc3ccccc3O2)c1,bb_chromene-OH
NS(=O)(=O)c1ccccc1,bb_phenylsulfonamide_NH2
NC(=O)c1ccccc1,bb_benzamide_NH2
ClS(=O)(=O)c1ccc(C)cc1,bb_tosyl_chloride
BBEOF
    }
fi

# ---- Step 2: enumerate products via 7 reactions ----
PRODUCTS_CSV="$VARIANT_DATA_DIR/enumerated_products.csv"
variant_log "Enumerating products via 7 onepot reactions"
python "$TBXT_ROOT/scripts/team/enumerate_onepot_products.py" \
    --bbs "$BB_FILE" \
    --out "$PRODUCTS_CSV" \
    --max-products 50000

# ---- Step 3: drug-likeness + novelty filter ----
FILTERED_CSV="$VARIANT_DATA_DIR/onepot_filtered_for_dock.csv"
variant_log "Filtering products: drug-like + Tanimoto<0.85 to 2274 known"
python "$TBXT_ROOT/scripts/team/filter_onepot_candidates.py" \
    --input "$PRODUCTS_CSV" \
    --known "$TBXT_ROOT/data/prior_art_canonical.csv" \
    --out "$FILTERED_CSV" \
    --max-out "$TOP_N_DOCK"

# ---- Step 4: dock at site F with GNINA (single seed, exh 8) ----
DOCK_OUT="$VARIANT_DATA_DIR/gnina_F"
mkdir -p "$DOCK_OUT"
variant_log "Docking $(wc -l < "$FILTERED_CSV") candidates at site F"
python "$TBXT_ROOT/scripts/dock_gnina.py" \
    --smiles-csv "$FILTERED_CSV" \
    --site F \
    --out-dir "$DOCK_OUT" \
    --exhaustiveness 8

# ---- Step 5: pick top-50 onepot-friendly site-F binders ----
TOP50_CSV="$VARIANT_REPORT_DIR/onepot_friendly_top50.csv"
variant_log "Selecting top 50 by Tier-A composite"
python - <<PYEOF
import csv, os
src = "$DOCK_OUT/dock_results_gnina.csv"
out = "$TOP50_CSV"
rows = [r for r in csv.DictReader(open(src)) if r.get("status") == "ok"]
def composite(r):
    try:
        return (float(r["best_cnn_pose_score"]) * 4.0
              + float(r["best_cnn_affinity_pkd"]) * 0.3
              - float(r["best_vina_kcal"]) * 0.2)
    except (KeyError, ValueError):
        return -999
rows.sort(key=composite, reverse=True)
top = rows[:50]
os.makedirs(os.path.dirname(out), exist_ok=True)
keep = ["id","smiles","best_vina_kcal","best_cnn_pose_score","best_cnn_affinity_pkd","best_cnn_affinity_uM"]
with open(out, "w", newline="") as f:
    w = csv.writer(f); w.writerow(keep)
    for r in top:
        w.writerow([r.get(k, "") for k in keep])
print(f"Wrote {out}  ({len(top)} rows)")
PYEOF

# ---- Done ----
variant_done OK
