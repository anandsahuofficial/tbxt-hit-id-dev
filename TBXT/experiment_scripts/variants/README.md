# Overnight HPC variants

Each `variantN_<name>.sh` is a self-contained, schedule-agnostic bash script
that runs ONE independent perturbation of the consensus pipeline. Submit
them in parallel on a multi-L40S HPC; the lead aggregates outputs after.

## What each variant does

| # | Script | What it adds | GPU-h on L40S |
|---:|---|---|---:|
| 1 | `variant1_onepot_friendly_gen.sh` | Enumerates ~50K compounds via the 7 onepot reactions on a small BB sample, filters drug-like + Naar-novel, docks survivors at site F, returns top 50 onepot-reachable site-F binders | ~10-15 |
| 2 | `variant2_full_pool_boltz.sh` | Boltz-2 on FULL 570 (vs current top 30) at production settings | ~12-16 |
| 3 | `variant3_receptor_ensemble.sh` | task2-style GNINA on 570 against 2-3 receptor conformations; min-vina + mean-CNN consensus | ~10-15 |
| 4 | `variant4_alchemical_fep.sh` | Longer-MD MMGBSA (1 ns equilibration, 10-frame avg) on top 30 + (if OpenFE installed) real alchemical FEP on top 8 | ~10-14 |
| 5 | `variant5_site_g_dock.sh` | task3-style GNINA on 570 at SITE G (TEP's 3rd recommended pocket); covers the wildcard slot | ~5-8 |

Total ~56 GPU-h ÷ 5 GPUs in parallel = ~11-12 wall-clock hours.

## How to submit

### One-shot (PBS qsub default)

```
bash launch_all_variants.sh
```

### Different scheduler

```
SCHED_CMD='sbatch --gres=gpu:l40s:1 --time=20:00:00 --wrap'  bash launch_all_variants.sh
```

### Dry-run (just print what would submit)

```
bash launch_all_variants.sh --dry-run
```

### Submit one variant only

```
bash variant3_receptor_ensemble.sh
```

## Output isolation

Each variant writes to:

```
TBXT/data/variants/<VARIANT_NAME>/                # raw outputs (gitignored)
TBXT/data/logs/variants/<VARIANT_NAME>.log        # full terminal capture
TBXT/report/variants/<VARIANT_NAME>/<task>.json   # shareable summary
```

These do not collide with the main `TBXT/data/task<N>/` and `TBXT/report/task<N>_trial1.json` paths. Variants run independently and their results don't overwrite production-pipeline artifacts.

## After all variants finish (lead's machine)

```
# 1. Cross-compare picks
python TBXT/scripts/team/convergence_audit.py

# 2. Re-aggregate consensus including variant signals
python TBXT/scripts/team/build_submission.py

# 3. (Optional) Rowan re-rank on top 4
ROWAN_API_KEY=rowan_xxx \
python TBXT/scripts/team/rowan_re_rank.py \
    --picks TBXT/report/final_4_picks.csv \
    --receptor-pdb TBXT/data/dock/receptor/6F59_apo.pdb \
    --out TBXT/report/rowan_re_rank.json
```

## Convergence audit (the rigour argument for judging)

`convergence_audit.py` reads every variant's top-50 list and reports the
"robust set" — compounds that appear in top-4 of ≥ 4 of the 5 variants.

If the robust set ⊇ our current 4 picks → ship them with the convergence
argument. If not → the divergent variants tell us which axes are sensitive.

## Member usage on HPC

```
# 1. Pull latest repo + bundles
cd ~/Hackathon
git pull
bash TBXT/setup_hf.sh --update

# 2. Submit one or more variants
qsub -l ngpus=1 -l walltime=20:00:00 -- \
    bash ~/Hackathon/TBXT/experiment_scripts/variants/variant3_receptor_ensemble.sh

# 3. After each job completes, the variant report JSON is at
#    ~/Hackathon/TBXT/report/variants/<VARIANT_NAME>/<task>.json
#    Upload to the team Drive / HF-clone for lead aggregation.
```

## Resumability

Each variant is checkpointable per-step. If a variant fails midway:

```
bash variantN_<name>.sh         # re-run; skips completed steps if it can
```

If you need to force a clean re-run, delete the variant's data dir first:

```
rm -rf TBXT/data/variants/<VARIANT_NAME>
bash variantN_<name>.sh
```
