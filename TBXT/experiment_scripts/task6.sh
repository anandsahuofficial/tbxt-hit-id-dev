#!/usr/bin/env bash
# task6 — Selectivity dock vs T-box paralogs (TBR1/TBX2/TBX21).
# Production: top 20 picks × 3 paralogs (~5 GPU-h)
# Test:       3 picks × 1 paralog (TBR1) at exh 1 (~2 min)
#
# This task uses the existing data/selectivity/ structure.
# The paralog receptor PDBQTs need to be prepped first; if missing, this
# script produces a PARTIAL status and explains what to do.
set -euo pipefail

TASK_ID="task6"
TASK_NAME="Selectivity dock vs T-box paralogs (TBR1, TBX2, TBX21)"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

PARALOG_DIR="$TBXT_ROOT/data/selectivity/receptors/prepped"
TBXT_RECEPTOR="$TBXT_ROOT/data/dock/receptor/6F59_apo.pdbqt"
SELECTIVITY_MATRIX="$TBXT_ROOT/data/selectivity/site_F_residue_matrix.csv"

# Sequence-aware selectivity scoring uses the precomputed paralog residue
# matrix (data/selectivity/site_F_residue_matrix.csv) — no paralog receptor
# PDBQTs needed. The structural-docking variant is a strict superset; if
# paralog PDBQTs are present, scripts/team/dock_selectivity.py prefers them.
if [ ! -f "$SELECTIVITY_MATRIX" ]; then
    log_warn "Selectivity matrix missing at $SELECTIVITY_MATRIX"
    EXTRAS="$DATA_DIR/_extras.json"
    python -c "import json; json.dump({'status_detail': 'selectivity_matrix_missing'}, open('$EXTRAS','w'), indent=2)"
    _end PARTIAL "$EXTRAS"
    exit 0
fi

if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -4 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    EXHAUSTIVENESS=1
    log_info "TEST MODE: 3 compounds × paralogs at exh 1"
else
    INPUT_CSV="$DATA_DIR/_top20_input.csv"
    if [ -f "$TBXT_ROOT/data/tier_a/tier_a_candidates.csv" ]; then
        head -21 "$TBXT_ROOT/data/tier_a/tier_a_candidates.csv" > "$INPUT_CSV"
    else
        head -21 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    fi
    EXHAUSTIVENESS=8
    log_info "PRODUCTION: top 20 × paralogs at exh 8"
fi

SCRIPT="$TBXT_ROOT/scripts/team/dock_selectivity.py"
OUT_DIR="$DATA_DIR/dock_results"
mkdir -p "$OUT_DIR"
run_python "$SCRIPT" \
    --smiles-csv "$INPUT_CSV" \
    --paralog-receptor-dir "$PARALOG_DIR" \
    --tbxt-receptor "$TBXT_RECEPTOR" \
    --out-csv "$OUT_DIR/dock_offtarget.csv" \
    --exhaustiveness "$EXHAUSTIVENESS" || { _end FAIL; exit 1; }

EXTRAS="$DATA_DIR/_extras.json"
RESULTS_CSV="$OUT_DIR/dock_offtarget.csv"
python - "$EXTRAS" "$RESULTS_CSV" "$INPUT_CSV" <<'PYEOF'
import csv, json, sys, os
out, csv_path, input_csv = sys.argv[1:]
NUMERIC = {"n_total_contacts", "n_site_F_contacts", "selectivity_score",
           "selectivity_TBX5", "selectivity_TBX21", "selectivity_kcal_min"}
rows = []
n_input = sum(1 for _ in open(input_csv)) - 1
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        out_row = {}
        for k, v in r.items():
            if k in NUMERIC and v not in ("", None):
                try: out_row[k] = float(v)
                except ValueError: out_row[k] = v
            else:
                out_row[k] = v
        rows.append(out_row)
data = {
    "n_input": n_input,
    "processed": {"n_ok": len(rows)},
    "all_results": rows,
    "top_50_ids": [r["id"] for r in sorted(rows, key=lambda r: -float(r.get("selectivity_score", 0) or 0))[:50]],
    "summary_stats": {
        "n_highly_selective": sum(1 for r in rows if (r.get("selectivity_score") or 0) >= 0.5),
        "mean_selectivity":   round(sum(float(r.get("selectivity_score") or 0) for r in rows) / len(rows), 3) if rows else 0,
    } if rows else {},
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
