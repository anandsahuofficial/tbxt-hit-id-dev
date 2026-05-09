# Final Submission Bundle — TBXT Hit Identification Hackathon

**Date:** 2026-05-09 · **Submission deadline:** 7 PM today
**Project lead:** Anand Sahu

This directory is the **single source of truth** for the team's final
submission. Everything you need to (a) submit the 4 picks for hackathon
judging, (b) pick from the 30 picks for the experimental program first
batch, or (c) coordinate sub-team submissions is here.

If a file isn't in `final/`, it's not part of the submission.

## What to read first

**The team submits 24 compounds total: 4 to judges + 20 additional for experimental program.**

| If you want to … | Open |
|---|---|
| **Hackathon judging — present 4 picks** | `submission_top4.md` + `slide_top4.md` + `top4.csv` + `top4_rationale.md` |
| **Experimental program first batch — 20 additional picks** | `submission_top5to24.md` + `slide_top5to24.md` + `top5to24.csv` + `top5to24_rationale.md` |
| **Pick top N (10/30/50) from full 137-candidate pool** | `tiered/TIERED_CANDIDATES_RATIONALE.md` + `all_candidates_tiered.csv` |
| **Coordinate as a sub-team** (legacy 5×4 split) | `team_distribution/TEAM_5_GROUPS_PICKS.md` |
| **Older single-submission view** (kept for reference) | `SUBMISSION.md` + `SLIDES.md` + `final_4_picks.csv` |

## Directory layout

```
final/
├── README.md                          ← you are here
├── SUBMISSION.md                      ← written submission text
├── SLIDES.md                          ← Marp slide deck for live demo
├── final_4_picks.csv                  ← THE 4 RANKED PICKS — primary deliverable
├── final_4_picks_smiles.txt           ← tab-separated id<TAB>SMILES, copy-paste-ready
├── all_candidates_tiered.csv          ← 137 rows, every per-criterion flag (the master pool)
│
├── tiered/                            ← per-tier rationale + top-30 first-batch list
│   ├── TIERED_CANDIDATES_RATIONALE.md
│   └── onepot_top30_picks.csv
│
├── team_distribution/                 ← sub-team coordination
│   ├── TEAM_5_GROUPS_PICKS.md         ← 5 sub-teams × 4 picks allocation
│   ├── team_picks_pool.csv            ← 100-pool reference
│   └── team_top50_with_groups.csv     ← top-50 with group assignments
│
├── evidence/                          ← cross-validation evidence
│   ├── CONVERGENCE_AUDIT.md           ← T-0 cross-variant consensus
│   ├── boltz_summary_scc.csv          ← SCC v2 Boltz (cross-validation)
│   ├── onepot_100pct_non_covalent_candidates.csv
│   ├── rowan_re_rank.json + .md       ← Rowan ADMET + Docking
│   └── variants/                      ← 7 variant result JSONs
│
└── renders/                           ← 8 PNGs (4 picks × 2D + 3D pose)
    ├── FM002150_analog_0083_{2d,pose_3d}.png
    ├── FM001452_analog_0104_{2d,pose_3d}.png
    ├── FM001452_analog_0201_{2d,pose_3d}.png
    └── FM001452_analog_0171_{2d,pose_3d}.png
```

## The 4 final picks (ordered)

| # | ID | Site | Boltz Kd (Jack/SCC) | $ | risks |
|---:|---|:---:|---:|---:|---|
| **1** | `FM002150_analog_0083` | F | 3.2 / 3.26 µM | $125 | low/low |
| **2** | `FM001452_analog_0104` | F | 3.7 / 4.97 µM | $250 | med/med |
| **3** | `FM001452_analog_0201` | F | 8.16 / 8.76 µM | $375 | high/med |
| **4** | `FM001452_analog_0171` | F | 8.32 / 8.17 µM | $250 | med/med |

All 4 strictly satisfy the organizer's constraints:
- ✅ 100% match in onepot.ai catalog (similarity = 1.000 via muni `onepot` tool)
- ✅ Strictly non-covalent
- ✅ Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12)
- ✅ Lead-like ideal (10–30 HA, HBD+HBA ≤ 11, LogP < 5, < 5 rings, ≤ 2 fused)
- ✅ PAINS-clean + no forbidden motifs
- ✅ Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical
- ✅ Predicted soluble (ESOL log S > -5)

## What lives OUTSIDE this directory (and why)

| Excluded | Where it lives | Why |
|---|---|---|
| Pipeline source code | `TBXT/scripts/`, `TBXT/experiment_scripts/` | Run from main repo; not part of submission bundle |
| Raw intermediates (poses, dock CSVs) | `TBXT/data/dock/`, `TBXT/data/full_pool_gnina_F/` | Multi-GB; regeneratable |
| Member supplementary runs | `TBXT/member_data/` | Already credited in evidence/; full data too large |
| Pre-swap snapshots | `TBXT/report/*_pre_100pct_swap.{csv,md}` | Obsolete; would confuse |
| Lead-only live-demo script | (gitignored, lead's machine) | Live demo is led by the project lead |
| Internal notes (MISALLIGNMENT_FIX, CRITERIA, etc.) | repo root / TBXT/ | Pre-submission notes; not for distribution |
