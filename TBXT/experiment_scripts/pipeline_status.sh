#!/usr/bin/env bash
# pipeline_status.sh — TBXT hackathon pipeline status report.
#
# Reads ONLY the per-task JSON reports (TBXT/report/task<N>_trial<T>.json) and
# prints a human-readable status. Does not touch raw data, so it is safe to
# run on a coordinator's machine after manually downloading JSONs from the
# team Drive folder.
#
# Usage:
#   bash TBXT/experiment_scripts/pipeline_status.sh                # default trial 1
#   bash TBXT/experiment_scripts/pipeline_status.sh --trial 1
#   bash TBXT/experiment_scripts/pipeline_status.sh --trial 99     # test trial
#   bash TBXT/experiment_scripts/pipeline_status.sh --all-trials   # show every trial

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$TBXT_ROOT/report"

# Activate env if available (we use python json parsing). Falls back to system
# python3 if the env isn't installed (e.g. coordinator on a bare machine).
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    # shellcheck disable=SC1091
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
    conda activate tbxt 2>/dev/null || true
fi
if ! command -v python >/dev/null; then
    if command -v python3 >/dev/null; then
        alias python=python3
        shopt -s expand_aliases
    else
        echo "ERROR: neither python nor python3 found" >&2
        exit 2
    fi
fi

TRIAL="${TRIAL:-1}"
ALL_TRIALS="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --trial) TRIAL="$2"; shift 2 ;;
        --all-trials) ALL_TRIALS="true"; shift ;;
        --help|-h)
            sed -n '1,17p' "$0" | sed 's/^#\s\?//'
            exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ ! -d "$REPORT_DIR" ]; then
    echo "ERROR: report directory not found: $REPORT_DIR"
    echo "  Run a task first, or coordinator-pull JSONs from Drive into $REPORT_DIR/"
    exit 1
fi

python - "$REPORT_DIR" "$TRIAL" "$ALL_TRIALS" <<'PYEOF'
import json, os, sys, re
from datetime import datetime, timezone
from pathlib import Path

report_dir = Path(sys.argv[1])
trial_arg  = sys.argv[2]
all_trials = sys.argv[3] == "true"

ALL_TASKS = [f"task{n}" for n in range(1, 11)]

def discover_trials():
    trials = set()
    for f in report_dir.glob("task*_trial*.json"):
        m = re.match(r"task(\d+)_trial(\d+)\.json", f.name)
        if m: trials.add(int(m.group(2)))
    return sorted(trials)

trials = discover_trials() if all_trials else [int(trial_arg)]

def fmt_status(s):
    return {"OK": "✅ OK     ", "FAIL": "❌ FAIL   ",
            "PARTIAL": "⚠️  PARTIAL", "MISSING": "⬜ MISSING ",
            "CORRUPT": "💥 CORRUPT"}.get(s, "?  UNKNOWN ")

def fmt_age(iso):
    if not iso: return "       "
    try:
        t = datetime.fromisoformat(iso.replace("Z", "+00:00"))
        delta = datetime.now(timezone.utc) - t
        s = delta.total_seconds()
        if s < 60: return f"{int(s)}s ago"
        if s < 3600: return f"{int(s/60)}m ago"
        if s < 86400: return f"{int(s/3600)}h ago"
        return f"{int(s/86400)}d ago"
    except Exception:
        return iso[:10]

def load(path):
    if not path.exists(): return None
    try:
        with path.open() as f: return json.load(f)
    except Exception as e:
        return {"_error": str(e), "status": "CORRUPT"}

print("=" * 88)
print(f"  TBXT Hackathon Pipeline Status")
print(f"  Report dir: {report_dir}")
print(f"  Generated:  {datetime.now().isoformat(timespec='seconds')}")
print("=" * 88)

for trial in trials:
    print()
    print(f"━━━ TRIAL {trial} ━━━")
    print()
    print(f"  {'task':10s}  {'status':12s}  {'wall':>10}  {'age':>10}  {'errors':>7}  {'warnings':>9}  task name")
    print("  " + "─" * 86)
    for tid in ALL_TASKS:
        path = report_dir / f"{tid}_trial{trial}.json"
        d = load(path)
        if d is None:
            print(f"  {tid:10s}  {fmt_status('MISSING')}  {'—':>10}  {'—':>10}  {'—':>7}  {'—':>9}  -")
            continue
        status = d.get("status", "UNKNOWN")
        wall = d.get("wall_time_seconds", 0)
        wall_str = f"{wall}s" if wall < 60 else f"{wall//60}m{wall%60}s" if wall < 3600 else f"{wall//3600}h{(wall%3600)//60}m"
        age = fmt_age(d.get("ended_at_utc"))
        n_err = len(d.get("errors", []))
        n_warn = len(d.get("warnings", []))
        name = d.get("task_name", "")[:40]
        print(f"  {tid:10s}  {fmt_status(status)}  {wall_str:>10}  {age:>10}  {n_err:>7}  {n_warn:>9}  {name}")

    # Per-trial highlights
    completed = [tid for tid in ALL_TASKS
                 if (report_dir / f"{tid}_trial{trial}.json").exists()
                 and (load(report_dir / f"{tid}_trial{trial}.json") or {}).get("status") == "OK"]
    print()
    print(f"  Trial {trial}: {len(completed)}/{len(ALL_TASKS)} tasks OK")
    if completed:
        print(f"    Done: {', '.join(completed)}")

print()
print("=" * 88)
print("  Tip: bash TBXT/experiment_scripts/pipeline_status.sh --all-trials")
print("       reads every trial in $TBXT_ROOT/report/")
print("=" * 88)
PYEOF
