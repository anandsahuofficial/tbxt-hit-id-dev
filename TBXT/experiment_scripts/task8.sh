#!/usr/bin/env bash
# task8 — FEP on top 8 picks (alchemical relative ΔΔG vs Z795991852 reference).
# Production: 8 perturbation pairs × 12 λ windows × 5 ns each (~40 GPU-h)
# Test:       1 perturbation × 4 λ × 100 ps (~5 min)
#
# scripts/team/run_fep.py is the expected entry point; if absent, this task
# reports PARTIAL and explains the framework setup needed.
set -euo pipefail

TASK_ID="task8"
TASK_NAME="FEP on top 8 picks (alchemical relative ΔΔG)"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

# Ensure OpenFE is available
if ! python -c "import openfe" 2>/dev/null; then
    log_warn "openfe not installed. Installing into env..."
    conda install -y --override-channels -c conda-forge openfe || true
fi

SCRIPT="$TBXT_ROOT/scripts/team/run_fep.py"
if [ ! -f "$SCRIPT" ]; then
    log_warn "scripts/team/run_fep.py not yet implemented by Task 8 owner."
    log_warn "  Expected interface: --candidates <csv> --reference <id> --receptor-pdb <path>"
    log_warn "  --pose-dir <dir> --out-dir <dir> --n-lambda <int> --md-ns <float>"
    log_warn "  See dashboard/08_fep_top_picks.md for the full algorithm outline."
    EXTRAS="$DATA_DIR/_extras.json"
    python -c "import json; json.dump({'status_detail': 'fep_script_not_implemented'}, open('$EXTRAS','w'), indent=2)"
    _end PARTIAL "$EXTRAS"
    exit 0
fi

if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -3 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    N_LAMBDA=4
    MD_NS=0.1
    log_info "TEST MODE: 1 perturbation × 4 λ windows × 100 ps"
else
    # Production: prefer the top-4 + reference set staged by the lead from
    # report/final_4_picks.csv. Falls back to top 8 from tier_a if missing.
    INPUT_CSV="$DATA_DIR/_top4_input.csv"
    if [ ! -f "$INPUT_CSV" ]; then
        INPUT_CSV="$DATA_DIR/_top8_input.csv"
        head -9 "$TBXT_ROOT/data/tier_a/tier_a_candidates.csv" > "$INPUT_CSV"
        log_info "PRODUCTION: top 8 × 12 λ × 5 ns"
    else
        log_info "PRODUCTION: final 4 + reference from final_4_picks.csv (~10 min on GPU)"
    fi
    N_LAMBDA=12
    MD_NS=5
fi

OUT_DIR="$DATA_DIR/fep_runs"
mkdir -p "$OUT_DIR"

run_python "$SCRIPT" \
    --candidates "$INPUT_CSV" \
    --reference Z795991852 \
    --receptor-pdb "$TBXT_ROOT/data/dock/receptor/6F59_apo.pdb" \
    --pose-dir "$TBXT_ROOT/data/full_pool_gnina_F/poses" \
    --out-dir "$OUT_DIR" \
    --n-lambda "$N_LAMBDA" \
    --md-ns "$MD_NS" || { _end FAIL; exit 1; }

EXTRAS="$DATA_DIR/_extras.json"
RESULTS_CSV="$OUT_DIR/relative_dg_table.csv"
python - "$EXTRAS" "$RESULTS_CSV" "$N_LAMBDA" "$MD_NS" <<'PYEOF'
import csv, json, sys, os, statistics
out, csv_path, n_lambda, md_ns = sys.argv[1:]
rows = []
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        try:
            rows.append({
                "pair": r.get("Pair") or r.get("pair"),
                "delta_dg_kcal": float(r.get("ΔΔG_FEP") or r.get("delta_dg_kcal") or 0),
                "error_kcal": float(r.get("error_kcal", 0)),
                "n_lambda": int(r.get("n_lambda", n_lambda)),
            })
        except Exception: pass
data = {
    "config": {"n_lambda": int(n_lambda), "md_ns": float(md_ns)},
    "n_pairs": len(rows),
    "all_results": rows,
    "summary_stats": {
        "mean_error_kcal": round(statistics.mean(r["error_kcal"] for r in rows), 3) if rows else None,
        "max_error_kcal":  max((r["error_kcal"] for r in rows), default=None),
    } if rows else {},
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
