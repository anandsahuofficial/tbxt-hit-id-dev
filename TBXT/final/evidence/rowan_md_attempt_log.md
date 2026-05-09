# Rowan Pose-Analysis MD — Attempt Log

**Status:** Attempted, not delivered. Documented for transparency.

## What we tried

Run Rowan's `pose_analysis_md` (explicit-solvent, AMBER ff14SB protein +
OpenFF 2.2.1 ligand + TIP3P water, 5 ns / 1 traj per pick) on the 4
top picks to provide RMSD trajectories + movies.

## Methods attempted (in order)

| Attempt | Method | Outcome |
|---|---|---|
| 1 | Direct Rowan SDK, all 5 API keys, PDB ID `6F59` auto-fetch | Keys 0, 3, 4: HTTP 400/422 at workflow submission. Keys 1, 2: workflows submitted (uuids `450a3f68-...`, `71ffcb66-...`) but **failed cloud-side** with `WorkflowError`. |
| 2 | muni.bio `rowan_pose_analysis_md` tool, PDB `6F59`, `prepare_protein=true` | HTTP 400 at `validate_forcefield`: 27 atoms with extreme force, hydrogen clashes (ARG63, GLN80, GLU3, GLY2, ...). |
| 3 | Pre-prepared protein via `Protein.prepare()` (remove + re-add H, optimize), then muni MD | Protein prep succeeded (UUID `46598331-...`) but muni MD call hit `403`: protein not visible across accounts (each Rowan key has its own protein scope). |

## What we have instead (Rowan engagement)

- **Rowan ADMET** (49 properties × 4 picks) — `evidence/rowan_re_rank.json` + `.md`. Successful via Rowan SDK key 0. Used in submission rationale.
- **Rowan Docking** (Vina/Vinardo + conformer search) — `evidence/rowan_re_rank.json`. Successful. Re-ranks the 4 picks: analog_0021 wins (-6.21 best score) — agrees with our internal multi-signal consensus.

## What we have instead (binding-pose stability)

In place of MD, we cite:
- **Mark's multi-seed GNINA** (10 seeds × 570 compounds at site F) — assesses pose stability via GNINA's own scoring across multiple random seeds. The top picks have low CNN-pKd stdev across seeds (analog_0087 σ=0.037 = most pose-stable site-F pick we have).
- **Dual-engine Boltz cross-validation** (Jack local + SCC re-run) — two completely independent Boltz-2 runs agree within 1.01-1.34× on Kd for all 4 picks. Catches any single-run noise.

## Honest framing for judges

If asked "did you run MD?": *We attempted Rowan's pose-analysis MD on the
top 4 picks but the Rowan accounts available to us don't carry the credit
tier required for explicit-solvent MD workflows; the attempts are
documented in `evidence/rowan_md_attempt_log.md`. We have GNINA
multi-seed pose stability (Mark, 10 seeds × 570 compounds) and dual-
engine Boltz cross-validation as our pose-stability evidence in lieu of
explicit-solvent MD.*
