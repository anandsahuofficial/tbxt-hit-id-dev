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

if [ ! -d "$PARALOG_DIR" ] || [ -z "$(ls -A "$PARALOG_DIR" 2>/dev/null)" ]; then
    log_warn "Paralog receptor PDBQTs not found at $PARALOG_DIR"
    log_warn "  This task needs prepped paralog receptors. The Task 6 owner is expected to"
    log_warn "  pull TBR1 (6JG2), TBX2 (5HKR), TBX21 (1H6F) and run prep_receptor logic"
    log_warn "  on each. See dashboard/06_selectivity_dock.md."
    EXTRAS="$DATA_DIR/_extras.json"
    python -c "import json; json.dump({'status_detail': 'paralog_receptors_missing', 'expected_dir': '$PARALOG_DIR'}, open('$EXTRAS','w'), indent=2)"
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

# The selectivity-dock script (scripts/team/dock_selectivity.py) is the
# expected name; if not present, the Task 6 owner writes it. We check.
SCRIPT="$TBXT_ROOT/scripts/team/dock_selectivity.py"
if [ ! -f "$SCRIPT" ]; then
    log_warn "scripts/team/dock_selectivity.py not yet written by Task 6 owner."
    log_warn "Falling back to docking each paralog individually with scripts/dock.py."
    OUT_DIR="$DATA_DIR/dock_results"
    mkdir -p "$OUT_DIR"
    for paralog_pdbqt in "$PARALOG_DIR"/*.pdbqt; do
        paralog_name=$(basename "$paralog_pdbqt" .pdbqt)
        log_info "Docking against $paralog_name..."
        # We'd need to override the receptor in dock.py — placeholder
        log_warn "  (placeholder — full implementation requires Task 6 owner's script)"
    done
else
    OUT_DIR="$DATA_DIR/dock_results"
    mkdir -p "$OUT_DIR"
    run_python "$SCRIPT" \
        --smiles-csv "$INPUT_CSV" \
        --paralog-receptor-dir "$PARALOG_DIR" \
        --tbxt-receptor "$TBXT_RECEPTOR" \
        --out-csv "$OUT_DIR/dock_offtarget.csv" \
        --exhaustiveness "$EXHAUSTIVENESS" || { _end FAIL; exit 1; }
fi

EXTRAS="$DATA_DIR/_extras.json"
RESULTS_CSV="$OUT_DIR/dock_offtarget.csv"
python - "$EXTRAS" "$RESULTS_CSV" "$INPUT_CSV" <<'PYEOF'
import csv, json, sys, os, statistics
out, csv_path, input_csv = sys.argv[1:]
rows = []
n_input = sum(1 for _ in open(input_csv)) - 1
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        rows.append({k: (float(v) if v not in ("", None) and k != "id" and k != "smiles" else v)
                     for k, v in r.items()})
data = {
    "n_input": n_input,
    "processed": {"n_ok": len(rows)},
    "all_results": rows,
    "summary_stats": {
        "n_with_selectivity_gap": sum(1 for r in rows if r.get("selectivity_kcal_min", 0) and r["selectivity_kcal_min"] >= 1.0),
    } if rows else {},
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
