# TBXT Experiment Scripts — Member Quick Reference

Each member runs **exactly one** `task<N>.sh` (assigned by the coordinator). The script handles env activation, checkpointing, JSON report generation, and Drive-uploadable summary — no manual setup.

## After setup.sh + smoke_test.sh succeed

```bash
cd ~/Hackathon
bash TBXT/experiment_scripts/task<N>.sh           # production run
bash TBXT/experiment_scripts/task<N>.sh --test    # ~30 sec to 5 min validation run
```

That's it. The script:

1. Sources conda + activates `tbxt` env
2. Sets `LD_LIBRARY_PATH`
3. Runs the actual computation with checkpointing
4. Writes raw outputs to `data/task<N>/trial<T>/` (NOT shared)
5. Writes terminal capture to `data/logs/task<N>_trial<T>.log`
6. Writes the **shareable analysis JSON** to `report/task<N>_trial<T>.json`
7. Tells you what to upload to the team Drive folder

## Available flags (every script)

| Flag | Default | Purpose |
|---|---|---|
| `--trial N` | 1 (or 99 in `--test`) | Output isolation; multiple trials don't collide |
| `--test` | off | Reduced parameters for fast pipeline validation |
| `--restart` | off | Backup existing data + log + report to `backup_<ts>/`, then start fresh |
| `--help` | — | Print usage |

Behaviour:
- **Default re-run on a completed task** → `OK: task<N> trial<T> already complete; To force re-run: bash …`. Exits 0. (Skip-if-OK based on the JSON's `"status": "OK"` field.)
- **Default re-run on a partial task** → resumes from checkpoint with a `RESUME` message.
- **`--restart`** → renames existing dirs/files to `backup_<YYYYMMDD_HHMMSS>` (never deletes), then runs fresh.

## Tasks (one script per dashboard task)

| Script | What | Test cost | Production cost |
|---|---|---|---|
| `task1.sh` | Print + save organizer email body | < 1 s | same |
| `task2.sh` | Multi-seed GNINA on full 570 pool at site F | ~30 s | ~5 GPU-h |
| `task3.sh` | Site-A GNINA pool dock | ~30 s | ~50 min CPU/GPU |
| `task4.sh` | Boltz-2 co-fold on full 570 pool | ~3 min | ~10 GPU-h |
| `task5.sh` | MMGBSA fix + run on top 50 picks | ~5 min | ~3 GPU-h |
| `task6.sh` | Selectivity dock vs TBR1/TBX2/TBX21 | ~2 min | ~5 GPU-h |
| `task7.sh` | Generative chemistry (BRICS + QSAR) | ~2 min | ~30 GPU-h |
| `task8.sh` | FEP on top 8 picks (alchemical ΔΔG) | ~5 min | ~40 GPU-h |
| `task9.sh` | PyMOL + RDKit pose renders for slides | ~10 s | ~5 min |
| `task10.sh` | **Coordinator-only** — consensus aggregation | < 5 s | < 5 s |

## Coordinator workflow

After members upload their `report/task<N>_trial<T>.json` files to the team Drive:

1. Coordinator manually downloads all received JSONs into local `report/`.
2. Coordinator runs:
   ```bash
   bash TBXT/experiment_scripts/task10.sh --trial 1
   ```
3. The aggregator supports **partial inputs** — if some tasks are still running, it merges what's available and notes which signals are missing.
4. Output: `report/task10_trial1.json` (composite-ranked Tier-A list).

## Status snapshot

Anytime, see what's complete/failed/missing across all tasks for a trial:

```bash
bash TBXT/experiment_scripts/pipeline_status.sh --trial 1
bash TBXT/experiment_scripts/pipeline_status.sh --all-trials
```

This script reads only the JSONs (no raw data needed); safe to run on any machine after pulling JSONs from Drive.

## File layout (per task)

```
TBXT/data/task<N>/trial<T>/                   ← raw outputs (do NOT upload)
TBXT/data/task<N>/backup_<ts>/                ← prior trial preserved by --restart
TBXT/data/logs/task<N>_trial<T>.log           ← full terminal capture
TBXT/data/logs/task<N>_trial<T>.checkpoint.json
TBXT/report/task<N>_trial<T>.json             ← ⭐ upload this to team Drive
TBXT/report/backup_<ts>/                      ← prior reports preserved by --restart
```

## Status semantics in the JSON

| Status | Meaning |
|---|---|
| `OK` | Task completed successfully and produced expected outputs |
| `PARTIAL` | Task ran but with known limitations (e.g. missing dependencies, scaffold-only impl) |
| `FAIL` | Task failed; check the log for the error |

## What the JSON contains

```json
{
  "task_id": "task2",
  "task_name": "Multi-seed GNINA on full 570 pool at site F",
  "trial": 1,
  "test_mode": false,
  "status": "OK",
  "started_at_utc": "...",
  "ended_at_utc": "...",
  "wall_time_seconds": 6180,
  "git_commit": "<sha>",
  "env_hash": "<sha>",
  "log_file": "...",
  "metrics": {
    "config": {...},
    "input": {"n": 570, "source": "..."},
    "processed": {"n_ok": 568, "n_failed": 2},
    "summary_stats": {...},
    "top_50_ids": [...],
    "top_50_results": [...],
    "all_results": [...]
  },
  "warnings": [...],
  "errors": [...]
}
```

The `metrics.all_results` and `metrics.top_50_results` are the per-compound signals that the consensus aggregator (task10) consumes.

## Common issues

| Problem | Fix |
|---|---|
| `conda not found at $HOME/miniconda3` | Run `setup.sh` first |
| `Failed to activate conda env 'tbxt'` | Run `setup.sh` to unpack the env |
| `task<N> trial<T> already complete` (when you want to re-run) | Add `--restart` |
| GPU OOM on a particular compound | Lower `--exhaustiveness` (built into the underlying scripts; tweak in task<N>.sh if needed) |
| "WARN: scripts/team/<X>.py not yet written" (Tasks 5, 6, 8) | Coordinator-side prerequisite; see the corresponding `dashboard/0X_*.md` |
