#!/usr/bin/env bash
# task7 — Generative chemistry (BRICS recombination + QSAR scoring).
# Production: 30 000 raw → ~200 novel proposals after filtering
# Test:       1 000 raw → smaller count after filters
set -euo pipefail

TASK_ID="task7"
TASK_NAME="Generative chemistry: BRICS-recombination + QSAR scoring"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

if [ "$TEST_MODE" = "true" ]; then
    export MAX_GENERATE=1000
    export TOP_N=20
    log_info "TEST MODE: MAX_GENERATE=1000, TOP_N=20"
else
    export MAX_GENERATE=30000
    export TOP_N=200
    log_info "PRODUCTION: MAX_GENERATE=30000, TOP_N=200"
fi

# scripts/generate_proposals.py reads MAX_GENERATE / TOP_N from its own constants;
# we use env-var override-aware version. Falling back: just call it.
run_python "$TBXT_ROOT/scripts/generate_proposals.py" || { _end FAIL; exit 1; }

# Move/copy proposals into trial dir
PROPOSALS_CSV="$TBXT_ROOT/data/generative/generative_proposals.csv"
[ -f "$PROPOSALS_CSV" ] && cp "$PROPOSALS_CSV" "$DATA_DIR/proposals.csv"
RESULTS_CSV="$DATA_DIR/proposals.csv"

EXTRAS="$DATA_DIR/_extras.json"
python - "$EXTRAS" "$RESULTS_CSV" <<'PYEOF'
import csv, json, sys, os, statistics
out, csv_path = sys.argv[1:]
rows = []
if os.path.exists(csv_path):
    for r in csv.DictReader(open(csv_path)):
        rows.append({
            "id": r.get("id"),
            "smiles": r.get("smiles"),
            "qsar_pkd_ens": float(r["qsar_pkd_ens"]) if r.get("qsar_pkd_ens") else None,
            "qsar_kd_uM": float(r["qsar_kd_uM"]) if r.get("qsar_kd_uM") else None,
            "max_tanimoto_to_known": float(r["max_tanimoto_to_known"]) if r.get("max_tanimoto_to_known") else None,
            "ha": int(r["ha"]) if r.get("ha") else None,
            "rings": int(r["rings"]) if r.get("rings") else None,
        })
n_ok = len(rows)
top50 = sorted(rows, key=lambda r: -(r.get("qsar_pkd_ens") or 0))[:50]
pkds = [r["qsar_pkd_ens"] for r in rows if r.get("qsar_pkd_ens") is not None]
data = {
    "processed": {"n_ok": n_ok},
    "summary_stats": {
        "mean_qsar_pkd": round(statistics.mean(pkds), 4) if pkds else None,
        "min_t_to_known": min((r["max_tanimoto_to_known"] for r in rows if r.get("max_tanimoto_to_known") is not None), default=None),
        "max_t_to_known": max((r["max_tanimoto_to_known"] for r in rows if r.get("max_tanimoto_to_known") is not None), default=None),
    },
    "top_50_ids": [r["id"] for r in top50],
    "top_50_results": top50,
    "all_results": rows,
}
json.dump(data, open(out, "w"), indent=2)
PYEOF

_end OK "$EXTRAS"
