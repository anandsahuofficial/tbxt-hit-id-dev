#!/usr/bin/env bash
# Launch all 5 overnight variants in parallel via PBS qsub on an HPC with
# multi-L40S nodes. Adapt the `qsub` line for your scheduler if not PBS.
#
# This is a CONVENIENCE wrapper. Each variant is independently runnable
# without a scheduler — just `bash variantN_<name>.sh`.
#
# What it does:
#   for each variant<N>_*.sh in this directory:
#     qsub -l ngpus=1 -l walltime=20:00:00 -- bash <variant.sh>
#
# Override the scheduler command via SCHED_CMD:
#   SCHED_CMD='sbatch --gres=gpu:l40s:1 --time=20:00:00 --wrap'  bash launch_all_variants.sh
#
# Or do a dry-run that just prints what would be submitted:
#   bash launch_all_variants.sh --dry-run

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN="false"
[ "${1:-}" = "--dry-run" ] && DRY_RUN="true"

SCHED_CMD="${SCHED_CMD:-qsub -l ngpus=1 -l walltime=20:00:00 --}"

variants=(
    "$HERE/variant1_onepot_friendly_gen.sh"
    "$HERE/variant2_full_pool_boltz.sh"
    "$HERE/variant3_receptor_ensemble.sh"
    "$HERE/variant4_alchemical_fep.sh"
    "$HERE/variant5_site_g_dock.sh"
)

echo "Submitting ${#variants[@]} variant jobs"
echo "  scheduler cmd: $SCHED_CMD"
echo

for v in "${variants[@]}"; do
    name="$(basename "$v" .sh)"
    if [ ! -x "$v" ] && [ ! -f "$v" ]; then
        echo "  SKIP $name (script not found at $v)"
        continue
    fi
    chmod +x "$v" 2>/dev/null || true
    if [ "$DRY_RUN" = "true" ]; then
        echo "  [dry-run] $SCHED_CMD bash $v"
    else
        echo "  submitting $name"
        eval "$SCHED_CMD bash \"$v\""
    fi
done

echo
echo "Submitted. After all jobs complete, on the lead's machine run:"
echo "  python TBXT/scripts/team/convergence_audit.py"
echo "  python TBXT/scripts/team/build_submission.py"
