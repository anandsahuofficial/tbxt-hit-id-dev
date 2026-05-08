#!/usr/bin/env bash
# task10 — Coordinator-only consensus aggregation.
# Reads ALL report/task<N>_trial<T>.json files in $TBXT_ROOT/report/, merges
# signals into a composite-ranked Tier-A list, supports partial inputs.
#
# Usage flow:
#   1. Coordinator manually downloads each member's task<N>_trial<T>.json
#      from the team Drive folder into local report/ dir.
#   2. Run: bash TBXT/experiment_scripts/task10.sh
#   3. Output: report/task10_consensus_trial<T>.json + a human summary log
set -euo pipefail

TASK_ID="task10"
TASK_NAME="Consensus aggregation across all task JSONs (coordinator)"

source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
_parse_args "$@"
_setup_paths
_check_skip_or_resume
_activate_env
_begin

REPORT_DIR_GLOB="$TBXT_ROOT/report"
TRIAL_TAG="trial${TRIAL}"

log_info "Scanning $REPORT_DIR_GLOB for task<N>_${TRIAL_TAG}.json reports..."

# Collect what's available
REPORTS_FOUND=()
for n in 1 2 3 4 5 6 7 8 9; do
    f="$REPORT_DIR_GLOB/task${n}_${TRIAL_TAG}.json"
    if [ -f "$f" ]; then
        REPORTS_FOUND+=("$f")
        log_info "  found: $(basename "$f")"
    else
        log_info "  missing: task${n}_${TRIAL_TAG}.json"
    fi
done

if [ ${#REPORTS_FOUND[@]} -eq 0 ]; then
    log_error "No task reports found at $REPORT_DIR_GLOB. Download from Drive first."
    EXTRAS="$DATA_DIR/_extras.json"
    python -c "import json; json.dump({'status_detail': 'no_input_reports'}, open('$EXTRAS','w'), indent=2)"
    _end FAIL "$EXTRAS"
    exit 1
fi

# Run the consensus aggregator (signals merged from each task's all_results)
OUT_CSV="$DATA_DIR/consensus_table.csv"
RANKED_CSV="$DATA_DIR/tier_a_ranked.csv"

python - "$REPORT_DIR_GLOB" "$TRIAL_TAG" "$OUT_CSV" "$RANKED_CSV" <<'PYEOF'
"""
Aggregate per-task JSONs into a composite consensus ranking.
Supports partial inputs: signals from missing tasks are skipped (with notes).
"""
import csv, json, os, sys
from pathlib import Path

report_dir, trial_tag, out_csv, ranked_csv = sys.argv[1:]
report_dir = Path(report_dir)

# Map: task_id → handler that extracts {id: {signals…}} from the JSON
def task2_signals(j):  # multi-seed GNINA at site F
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        out[r["id"]] = {
            "smiles": r.get("smiles"),
            "cnn_pose_F_mean": r["cnn_pose_mean"],
            "cnn_pose_F_stdev": r["cnn_pose_stdev"],
            "cnn_pkd_F": r["cnn_pkd_mean"],
            "vina_F": r["vina_kcal_mean"],
        }
    return out
def task3_signals(j):  # site A
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        out[r["id"]] = {
            "cnn_pose_A": r["cnn_pose"],
            "cnn_pkd_A": r["cnn_pkd"],
            "vina_A": r["vina_kcal"],
        }
    return out
def task4_signals(j):  # boltz
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        out[r["id"]] = {
            "boltz_pkd": r.get("affinity_pkd"),
            "boltz_kd_uM": r.get("affinity_kd_uM"),
            "boltz_iptm": r.get("ipTM"),
            "boltz_prob_binder": r.get("prob_binder"),
        }
    return out
def task5_signals(j):  # mmgbsa
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        out[r["id"]] = {"mmgbsa_dg": r["delta_e_kcal"]}
    return out
def task6_signals(j):  # selectivity
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        out[r["id"]] = {"selectivity_kcal_min": r.get("selectivity_kcal_min")}
    return out
def task7_signals(j):  # generative — they're new compounds; track separately
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        out[r["id"]] = {"generative_qsar_pkd": r.get("qsar_pkd_ens"),
                        "generative_kd_uM": r.get("qsar_kd_uM"),
                        "smiles": r.get("smiles")}
    return out
def task8_signals(j):  # FEP
    out = {}
    for r in j.get("metrics", {}).get("all_results", []):
        pair = r.get("pair", "")
        # pair format: "<id1>+<id2>" — credit the candidate id (not reference)
        for cid in pair.split("+"):
            cid = cid.strip()
            if cid and cid != "Z795991852":
                out[cid] = {"fep_dd_g": r["delta_dg_kcal"], "fep_error": r["error_kcal"]}
    return out

handlers = {
    "task2": task2_signals, "task3": task3_signals, "task4": task4_signals,
    "task5": task5_signals, "task6": task6_signals, "task7": task7_signals,
    "task8": task8_signals,
}

# Aggregate
all_signals = {}      # id → dict of signals
tasks_used = []
tasks_missing = []
for n in range(1, 10):
    tid = f"task{n}"
    f = report_dir / f"{tid}_{trial_tag}.json"
    if not f.exists():
        tasks_missing.append(tid); continue
    try:
        j = json.load(open(f))
    except Exception as e:
        print(f"  WARN: could not parse {f}: {e}")
        continue
    handler = handlers.get(tid)
    if handler is None:
        tasks_used.append(f"{tid}(no-aggregator)"); continue
    sigs = handler(j)
    for cid, s in sigs.items():
        all_signals.setdefault(cid, {}).update(s)
    tasks_used.append(f"{tid}({len(sigs)})")

print(f"  Compounds with at least one signal: {len(all_signals)}")
print(f"  Tasks aggregated: {tasks_used}")
print(f"  Tasks missing:    {tasks_missing}")

# Composite scoring (uses whatever signals are present; missing → no contribution)
def f_or_none(v):
    try: return float(v)
    except (TypeError, ValueError): return None

def normalize(v, lo, hi):
    if v is None: return 0.0
    return max(0.0, min(1.0, (v - lo) / (hi - lo)))

def composite(s):
    return (
        0.25 * normalize(f_or_none(s.get("cnn_pose_F_mean")), 0.3, 0.8)
      + 0.20 * normalize(f_or_none(s.get("cnn_pkd_F")),       4.5, 6.5)
      + 0.15 * normalize(f_or_none(s.get("boltz_prob_binder")), 0.3, 0.7)
      + 0.10 * normalize(f_or_none(s.get("boltz_pkd") or s.get("generative_qsar_pkd")), 4.0, 6.0)
      + 0.10 * normalize(-(f_or_none(s.get("vina_F")) or 0), 5.0, 9.0)
      + 0.10 * normalize(-(f_or_none(s.get("mmgbsa_dg")) or 0), 8.0, 25.0)
      + 0.05 * normalize(-(f_or_none(s.get("fep_dd_g")) or 0), -2, 2)
      + 0.05 * normalize(f_or_none(s.get("selectivity_kcal_min")), 0.5, 3.0)
    )

# Hard tier-A check (requires GNINA + at least one of QSAR/Boltz/FEP)
def passes_tier_a(s):
    pose = f_or_none(s.get("cnn_pose_F_mean"))
    pkd  = f_or_none(s.get("cnn_pkd_F"))
    vina = f_or_none(s.get("vina_F"))
    if pose is None or pkd is None or vina is None: return False
    if not (pose >= 0.5 and pkd >= 4.5 and vina <= -6.0): return False
    return True

ranked = sorted(all_signals.items(),
                key=lambda kv: -composite(kv[1]))

# Write the full table
all_keys = sorted({k for s in all_signals.values() for k in s.keys()})
header = ["id", "composite", "tier_a_pass"] + all_keys
with open(out_csv, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(header)
    for cid, s in ranked:
        w.writerow([cid, round(composite(s), 4), passes_tier_a(s)] +
                   [s.get(k, "") for k in all_keys])

# Tier-A only, ranked
tier_a = [(cid, s) for cid, s in ranked if passes_tier_a(s)]
with open(ranked_csv, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(header)
    for cid, s in tier_a:
        w.writerow([cid, round(composite(s), 4), True] +
                   [s.get(k, "") for k in all_keys])

# Print top 10
print(f"\n  Top 10 Tier-A by composite score:")
print(f"  {'id':30s}  {'composite':>9}  {'cnn_pose_F':>10}  {'cnn_pkd_F':>9}  {'vina_F':>6}")
for cid, s in tier_a[:10]:
    pose = s.get("cnn_pose_F_mean") or 0
    pkd  = s.get("cnn_pkd_F") or 0
    vina = s.get("vina_F") or 0
    print(f"  {cid:30s}  {composite(s):>9.4f}  {pose:>10.3f}  {pkd:>9.2f}  {vina:>6.2f}")

# Persist for the report extras
import json as _json
with open(out_csv.replace(".csv", "_meta.json"), "w") as fout:
    _json.dump({
        "tasks_aggregated": tasks_used,
        "tasks_missing": tasks_missing,
        "n_compounds_with_signals": len(all_signals),
        "n_tier_a_pass": len(tier_a),
        "top_50_tier_a_ids": [cid for cid, s in tier_a[:50]],
    }, fout, indent=2)
PYEOF

EXTRAS="$DATA_DIR/_extras.json"
META="$DATA_DIR/consensus_table_meta.json"
[ -f "$META" ] && cp "$META" "$EXTRAS" || python -c "import json; json.dump({}, open('$EXTRAS','w'))"

_end OK "$EXTRAS"
