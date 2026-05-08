#!/usr/bin/env bash
# task5 — Fix MMGBSA energy decomposition + run on top 50 picks.
# Production: top 50 compounds (~3 GPU-h)
# Test:       1 compound (~5 min)
#
# NOTE: scripts/run_mmgbsa.py has a documented bug in its energy decomposition
# (data/mmgbsa/MMGBSA_STATUS.md). The Task 5 owner is expected to fix it
# (build 3 separate systems instead of zeroing nonbonded on ghost atoms).
# This script runs the existing scaffold; ΔE values are NOT trustworthy until
# the fix lands. Status reports as "PARTIAL" instead of "OK" if the fix
# marker file is absent.
set -euo pipefail

TASK_ID="task5"
TASK_NAME="MMGBSA fix + run on top 50 picks"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

if [ "$TEST_MODE" = "true" ]; then
    INPUT_CSV="$DATA_DIR/_test_input.csv"
    head -2 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    log_info "TEST MODE: 1 compound (validates toolchain only — energies still bugged)"
else
    INPUT_CSV="$DATA_DIR/_top30_input.csv"
    if [ -f "$TBXT_ROOT/data/task2/trial1/top30_input.csv" ]; then
        cp "$TBXT_ROOT/data/task2/trial1/top30_input.csv" "$INPUT_CSV"
        log_info "PRODUCTION: top 30 picks from task2 consensus (data/task2/trial1/top30_input.csv)"
    elif [ -f "$TBXT_ROOT/data/tier_a/tier_a_candidates.csv" ]; then
        head -31 "$TBXT_ROOT/data/tier_a/tier_a_candidates.csv" > "$INPUT_CSV"
        log_info "PRODUCTION: top 30 picks from tier_a_candidates.csv"
    else
        log_warn "no top-N input found; using full_pool_input.csv head"
        head -31 "$TBXT_ROOT/data/full_pool_input.csv" > "$INPUT_CSV"
    fi
fi

# Fix marker — Task 5 owner creates this when they fix the energy decomp
FIX_MARKER="$TBXT_ROOT/scripts/team/run_mmgbsa_fixed.py"
if [ -f "$FIX_MARKER" ]; then
    SCRIPT="$FIX_MARKER"
    STATUS_AFTER="OK"
    log_info "Using fixed MMGBSA: $SCRIPT"
else
    SCRIPT="$TBXT_ROOT/scripts/run_mmgbsa.py"
    STATUS_AFTER="PARTIAL"
    log_warn "Using original (BUGGED) MMGBSA scaffold: $SCRIPT"
    log_warn "  Energies will be physically meaningless until energy decomp is fixed."
    log_warn "  See data/mmgbsa/MMGBSA_STATUS.md for the fix description."
fi

# pose-dir prefers full_pool_gnina_F (has 570 docked poses); falls back to validation
POSE_DIR="$TBXT_ROOT/data/full_pool_gnina_F/poses"
[ -d "$POSE_DIR" ] || POSE_DIR="$TBXT_ROOT/data/dock/validation_F_gnina/poses"

run_python "$SCRIPT" \
    --smiles-csv "$INPUT_CSV" \
    --pose-dir "$POSE_DIR" \
    || { _end FAIL; exit 1; }

# Try to find the output csv (legacy script writes to data/mmgbsa/mmgbsa_summary.csv)
SUMMARY_CSV="$TBXT_ROOT/data/mmgbsa/mmgbsa_summary.csv"
[ -f "$SUMMARY_CSV" ] && cp "$SUMMARY_CSV" "$DATA_DIR/mmgbsa_summary.csv" && SUMMARY_CSV="$DATA_DIR/mmgbsa_summary.csv"

EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$SUMMARY_CSV" "$INPUT_CSV" "$STATUS_AFTER" <<'PYEOF'
import csv, json, sys, os, statistics
out, csv_path, input_csv, status_after = sys.argv[1:]
rows = []
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        if r.get("status") == "ok":
            try:
                rows.append({
                    "id": r["cid"],
                    "smiles": r.get("smiles", ""),
                    "delta_e_kcal": float(r["delta_e_kcal"]),
                })
            except (ValueError, KeyError): pass
n_input = sum(1 for _ in open(input_csv)) - 1
data = {
    "fix_status": status_after,
    "n_input": n_input,
    "processed": {"n_ok": len(rows)},
    "all_results": rows,
    "warnings_about_energies":
        "Values NOT physically meaningful until energy decomposition is fixed. "
        "See data/mmgbsa/MMGBSA_STATUS.md." if status_after == "PARTIAL" else None,
}
if rows:
    es = [r["delta_e_kcal"] for r in rows]
    data["summary_stats"] = {
        "mean_delta_e": round(statistics.mean(es), 2),
        "min_delta_e": min(es),
        "max_delta_e": max(es),
    }
    data["top_50_results"] = sorted(rows, key=lambda r: r["delta_e_kcal"])[:50]
    data["top_50_ids"] = [r["id"] for r in data["top_50_results"]]
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end "$STATUS_AFTER" "$EXTRAS"
