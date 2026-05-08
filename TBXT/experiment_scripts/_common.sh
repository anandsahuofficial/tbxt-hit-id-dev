#!/usr/bin/env bash
# Shared helpers for TBXT experiment scripts.
#
# Every task script (task1.sh, task2.sh, …) sources this file FIRST. After
# sourcing, the task script:
#   1. Defines TASK_ID + TASK_NAME at the top
#   2. Calls _parse_args "$@"             — handles --trial / --test / --restart / --help
#   3. Calls _setup_paths                  — populates DATA_DIR, LOG_FILE, CHECKPOINT_FILE, REPORT_FILE
#   4. Calls _check_skip_or_resume        — exits 0 if status=OK and no --restart
#   5. Calls _begin                        — opens the log + records start time
#   6. Does the actual work (calling run_python, writing checkpoints)
#   7. Calls _end OK or _end FAIL          — writes the report JSON and closes the log
#
# Patterns adopted from <internal-pipeline>/pipeline.sh
# (backup_if_exists, _step_begin/_step_end, skip-if-OK, log scraping for warnings/errors).

set -euo pipefail

# ─── Project root resolution (works from any cwd, any machine path) ────────
# This file is at <ROOT>/TBXT/experiment_scripts/_common.sh, so PROJECT_ROOT
# is parents[2] and TBXT_ROOT is parents[1] of THIS file's location.
_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT_ROOT="$(cd "$_COMMON_DIR/.." && pwd)"        # .../Hackathon/TBXT
PROJECT_ROOT="$(cd "$_COMMON_DIR/../.." && pwd)"  # .../Hackathon

# ─── Defaults (overridable via CLI flags) ──────────────────────────────────
TRIAL="${TRIAL:-1}"
TEST_MODE="false"
RESTART="false"

# ─── Helpers: logging primitives ───────────────────────────────────────────
# Inside _begin..._end the exec> redirect prepends a timestamp to every line,
# so log_* funcs don't add their own. Before _begin (e.g. parse-error path)
# we still emit clean labels.
_TS() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
_HMS() { date +%H:%M:%S; }
log_info()  { printf "%s\n" "$*"; }
log_warn()  { printf "WARN: %s\n" "$*"; }
log_error() { printf "ERROR: %s\n" "$*" >&2; }
log_ok()    { printf "OK: %s\n" "$*"; }

# ─── Conda env activation ──────────────────────────────────────────────────
_activate_env() {
    local conda_dir="${CONDA_DIR:-$HOME/miniconda3}"
    local env_name="${ENV_NAME:-tbxt}"
    if [ ! -f "$conda_dir/etc/profile.d/conda.sh" ]; then
        log_error "conda not found at $conda_dir. Run setup.sh first."
        exit 2
    fi
    # shellcheck disable=SC1091
    source "$conda_dir/etc/profile.d/conda.sh"
    conda activate "$env_name"
    if [ ! -d "${CONDA_PREFIX:-/__none__}" ]; then
        log_error "Failed to activate conda env '$env_name'. Run setup.sh first."
        exit 2
    fi
    export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
    export PYTHONPATH="$TBXT_ROOT:${PYTHONPATH:-}"
    export PYTHONUNBUFFERED=1
}

# ─── CLI argument parser ───────────────────────────────────────────────────
# Usage: _parse_args "$@"
_parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --trial)
                TRIAL="$2"
                shift 2
                ;;
            --trial=*)
                TRIAL="${1#--trial=}"
                shift
                ;;
            --test)
                TEST_MODE="true"
                shift
                ;;
            --restart)
                RESTART="true"
                shift
                ;;
            --help|-h)
                _print_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                _print_help
                exit 2
                ;;
        esac
    done
    # In --test mode, default trial bumps to 99 unless user overrode it
    if [ "$TEST_MODE" = "true" ] && [ "$TRIAL" = "1" ]; then
        TRIAL=99
        log_info "Test mode: trial defaulted to 99 (override with --trial N)"
    fi
}

_print_help() {
    cat <<EOF
Usage: bash $(basename "${BASH_SOURCE[1]:-task.sh}") [OPTIONS]

Options:
  --trial N      Trial number for output isolation (default: 1; 99 in --test)
  --test         Run with reduced parameters for fast pipeline validation (~30s-5min)
  --restart      Backup existing data and start fresh (does NOT delete; renames to backup_<ts>)
  --help, -h     Show this message

Outputs:
  data/task<N>/trial<T>/        Raw outputs (NOT shared)
  data/logs/task<N>_trial<T>.log
  data/logs/task<N>_trial<T>.checkpoint.json
  report/task<N>_trial<T>.json  Shareable analysis report (upload to team Drive)
EOF
}

# ─── Path setup ────────────────────────────────────────────────────────────
# Must be called AFTER _parse_args. Requires TASK_ID to be set by the caller.
_setup_paths() {
    [ -n "${TASK_ID:-}" ] || { log_error "TASK_ID not set"; exit 2; }
    local trial_tag="trial${TRIAL}"
    DATA_DIR="$TBXT_ROOT/data/${TASK_ID}/${trial_tag}"
    LOG_DIR="$TBXT_ROOT/data/logs"
    REPORT_DIR="$TBXT_ROOT/report"

    LOG_FILE="$LOG_DIR/${TASK_ID}_${trial_tag}.log"
    CHECKPOINT_FILE="$LOG_DIR/${TASK_ID}_${trial_tag}.checkpoint.json"
    REPORT_FILE="$REPORT_DIR/${TASK_ID}_${trial_tag}.json"

    mkdir -p "$DATA_DIR" "$LOG_DIR" "$REPORT_DIR"
}

# ─── Backup helper (mirrors EDL's _backup_if_exists) ──────────────────────
_backup_if_exists() {
    local target="$1"
    [ ! -e "$target" ] && return 0
    local ts; ts=$(date +%Y%m%d_%H%M%S)
    local parent; parent=$(dirname "$target")
    local base; base=$(basename "$target")
    local backup_dir="$parent/backup_${ts}"
    mkdir -p "$backup_dir"
    mv "$target" "$backup_dir/$base"
    log_info "  backed up $target → $backup_dir/$base"
}

# ─── Skip-if-OK / resume / restart gating ──────────────────────────────────
# Must be called AFTER _setup_paths.
_check_skip_or_resume() {
    if [ "$RESTART" = "true" ]; then
        log_warn "RESTART requested — backing up existing artifacts"
        _backup_if_exists "$DATA_DIR"
        _backup_if_exists "$LOG_FILE"
        _backup_if_exists "$CHECKPOINT_FILE"
        _backup_if_exists "$REPORT_FILE"
        mkdir -p "$DATA_DIR"  # _backup_if_exists removed it
        return 0
    fi
    if [ -f "$REPORT_FILE" ]; then
        # Python may not be activated yet — use grep instead
        if grep -qE '"status"[[:space:]]*:[[:space:]]*"OK"' "$REPORT_FILE" 2>/dev/null; then
            log_ok "${TASK_ID} trial${TRIAL} already complete (status=OK at $REPORT_FILE)"
            log_info "  To force re-run:  bash ${BASH_SOURCE[1]:-task.sh} --restart"
            exit 0
        fi
    fi
    if [ -f "$CHECKPOINT_FILE" ]; then
        log_info "RESUME — picking up from checkpoint at $CHECKPOINT_FILE"
        local last_unit
        last_unit=$(grep -oE '"last_completed_unit"[[:space:]]*:[[:space:]]*"[^"]*"' "$CHECKPOINT_FILE" 2>/dev/null | head -1 | cut -d'"' -f4 || echo "?")
        log_info "  Last completed unit: ${last_unit:-?}"
    else
        log_info "STARTING task ${TASK_ID} trial${TRIAL} (test=${TEST_MODE})"
    fi
}

# ─── Step begin/end (timing + log + JSON write) ────────────────────────────
_T0=""
_begin() {
    _T0=$(date +%s)
    _T0_ISO=$(_TS)
    # Open log: append, not truncate (resumes preserve history)
    echo "" >> "$LOG_FILE"
    echo "===== [$(_TS)] BEGIN ${TASK_ID} trial${TRIAL} (test=${TEST_MODE}, restart=${RESTART}) =====" >> "$LOG_FILE"
    # Tee from this point forward to LOG_FILE
    exec > >(while IFS= read -r line; do printf "[%s] %s\n" "$(_HMS)" "$line"; done | tee -a "$LOG_FILE")
    exec 2> >(while IFS= read -r line; do printf "[%s] %s\n" "$(_HMS)" "$line"; done | tee -a "$LOG_FILE" >&2)
}

# _end <status> [extras_json_path]
# status: OK | FAIL | PARTIAL
# extras_json_path: optional path to a JSON file whose top-level keys are
#                   merged into the report's metrics{} block.
_end() {
    local status="$1"
    local extras_path="${2:-}"
    local t1; t1=$(date +%s)
    local wall=$(( t1 - _T0 ))
    local t1_iso; t1_iso=$(_TS)

    local extras_json="{}"
    if [ -n "$extras_path" ] && [ -f "$extras_path" ]; then
        extras_json=$(cat "$extras_path")
    fi

    local git_commit
    git_commit=$(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    local env_hash
    env_hash=$(conda list --explicit 2>/dev/null | sha256sum 2>/dev/null | cut -c1-12 || echo "unknown")

    python - "$REPORT_FILE" "$TASK_ID" "${TASK_NAME:-$TASK_ID}" "$status" \
            "$_T0_ISO" "$t1_iso" "$wall" "$TRIAL" "$TEST_MODE" \
            "$git_commit" "$env_hash" "$LOG_FILE" "$extras_json" <<'PYEOF'
import json, sys, os
(out, task_id, task_name, status, t0, t1, wall, trial, test_mode,
 git_commit, env_hash, log_path, extras_s) = sys.argv[1:]

# Auto-scrape warnings + errors from the log
warnings, errors = [], []
if os.path.exists(log_path):
    with open(log_path, errors='replace') as f:
        for line in f:
            line = line.rstrip()
            if not line or line.startswith("#"): continue
            up = line.upper()
            if "WARNING" in up and "UserWarning" not in line and "DEPRECATION" not in up:
                warnings.append(line[:200])
            if ("ERROR" in up or "TRACEBACK" in up) \
                    and "would error with" not in line:
                errors.append(line[:200])

data = {
    "task_id": task_id,
    "task_name": task_name,
    "trial": int(trial),
    "test_mode": test_mode == "true",
    "status": status,
    "started_at_utc": t0,
    "ended_at_utc": t1,
    "wall_time_seconds": int(wall),
    "git_commit": git_commit,
    "env_hash": env_hash,
    "log_file": log_path,
    "metrics": json.loads(extras_s),
    "warnings": warnings[-50:],
    "errors": errors[-50:],
}
with open(out, "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    echo "===== [$(_TS)] END ${TASK_ID} trial${TRIAL} status=${status} wall=${wall}s =====" >> "$LOG_FILE"
    log_info ""
    log_info "[${status}] ${TASK_ID} trial${TRIAL}  wall=${wall}s"
    log_info "  Report:     $REPORT_FILE"
    log_info "  Log:        $LOG_FILE"
    log_info "  Data dir:   $DATA_DIR"
    if [ "$status" = "OK" ]; then
        log_ok "Task complete. Upload $REPORT_FILE to the team Drive folder."
    fi
}

# ─── Checkpoint helpers (called from inside the work loop) ─────────────────
checkpoint_save() {
    # Usage: checkpoint_save <key> <value> [<key> <value>] ...
    # All args are merged into the existing checkpoint JSON (or initialize it).
    python - "$CHECKPOINT_FILE" "$@" <<'PYEOF'
import json, sys
path = sys.argv[1]
pairs = sys.argv[2:]
try:
    with open(path) as f: data = json.load(f)
except Exception:
    data = {}
for i in range(0, len(pairs), 2):
    k = pairs[i]; v = pairs[i+1]
    # try to parse as int/float, fall back to string
    try: data[k] = int(v)
    except ValueError:
        try: data[k] = float(v)
        except ValueError: data[k] = v
import datetime
data["_last_update_utc"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
with open(path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF
}

checkpoint_load() {
    # Usage: VALUE=$(checkpoint_load <key> [default])
    local key="$1"
    local default="${2:-}"
    if [ ! -f "$CHECKPOINT_FILE" ]; then
        printf "%s" "$default"; return
    fi
    python -c "
import json, sys
try:
    d = json.load(open('$CHECKPOINT_FILE'))
    print(d.get('$key', '$default'))
except Exception:
    print('$default')
" 2>/dev/null || printf "%s" "$default"
}

# ─── Convenience: run a Python script with logging captured ────────────────
run_python() {
    python "$@"
}
