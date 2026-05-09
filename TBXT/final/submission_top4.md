# TBXT Hackathon — Submission (top 4 picks for hackathon judging)

**Target:** TBXT G177D (Brachyury, chordoma driver)
**Sites:** F (Y88 / D177 / L42 anchor — TBXT-unique residues)
**Receptor:** PDB 6F59 chain A (G177D variant)
**Date:** 2026-05-09
**Project lead / methodology / live demo:** Anand Sahu

This file is the **hackathon-judging submission for the 4 ranked picks**.
The 20 additional team submissions (experimental program first batch)
are documented in `submission_top5to24.md` + `top5to24.csv`.

## Top 4 picks

| # | ID | Site | Boltz Kd (Jack/SCC) | prob_binder | gnina Vina | gnina pKd | onepot match | $ |
|---:|---|:---:|---:|---:|---:|---:|---:|---:|
| **1** | `FM002150_analog_0083` | F | 3.2 / 3.26 µM | 0.30 | -5.01 | 3.94 | **1.000** | $125 |
| **2** | `FM001452_analog_0104` | F | 3.7 / 4.97 µM | 0.41 | -5.77 | 4.03 | **1.000** | $250 |
| **3** | `FM001452_analog_0201` | F | 8.16 / 8.76 µM | 0.36 | -6.07 | 4.69 | **1.000** | $375 |
| **4** | `FM001452_analog_0171` | F | 8.32 / 8.17 µM | 0.46 | -6.19 | 4.44 | **1.000** | $250 |

All 4 picks pass simultaneously: 100% onepot.ai catalog match (similarity = 1.000 in muni `onepot` tool), strictly non-covalent (no boronic acids, no Michael acceptors, no acyl-halide warheads), Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical, MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12, lead-like ideal (10–30 HA, HBD+HBA ≤ 11, < 5 rings, ≤ 2 fused), PAINS-clean.

## SMILES (copy-paste for submission portal)

```
FM002150_analog_0083	O=C(O)COCc1ccc(-c2ccsc2)cc1
FM001452_analog_0104	Cc1ccccc1COc1cccc(N)c1
FM001452_analog_0201	NC(=O)Nc1cccc(OCc2ccccc2)c1
FM001452_analog_0171	Nc1cccc(OCc2ccc(-c3ccncc3)cc2)c1
```

## Pipeline (one paragraph)

Multi-signal orthogonal consensus on a 570-compound novelty-filtered pool
(503 enumerated analogs of priority Naar SPR scaffolds + 67 BRICS-
generative novel proposals). Six methods: Vina ensemble (6 receptors),
GNINA CNN pose + pKd, target-specific QSAR (RF + XGBoost on 650 measured
Naar SPR Kd), Boltz-2 co-folding (3 samples × 200 sampling steps × 3
recycles, dual-engine — Jack local + SCC re-run), MMGBSA implicit-solvent
(top 30), and T-box paralog selectivity (sequence-aware site-F contact
analysis on 16 paralogs). Final hard gate: 100%-onepot non-covalent +
Chordoma chemistry rule + Tanimoto < 0.85 to organizer DBs. Of 570 pool
compounds, **18 non-covalent** sit at exact onepot catalog match;
137 candidates after expanding the validation across the full pool. The
**4 picks are ranks 1, 2, 11, 22** of the curated 137-candidate pool
(see `top4_rationale.md` for per-pick justification + `tiered/TIERED_CANDIDATES_RATIONALE.md` for the full tier breakdown).

## Per-pick rationale (short)

### Pick 1: `FM002150_analog_0083`
Strongest Boltz Kd (3.2 µM) of any 100%-onepot non-covalent compound.
Phenoxyacetic-acid + thiophene scaffold; carboxylate H-bonds to Y88 /
D177 (variant residue). Cheapest + lowest-risk of the 4 ($125, low/low).
Dual-engine Boltz cross-validates at 1.02×.

### Pick 2: `FM001452_analog_0104`
Second-strongest Boltz Kd (3.7 / 4.97 µM). Cleanest medchem in the pool
— minimal heteroatom decoration. Anilino-N + ether-O H-bond pattern
targets D177. Mass-efficient (MW 213). $250 medium-risk catalog molecule.

### Pick 3: `FM001452_analog_0201`
N-aryl urea + benzyl ether designed for R174 + D177 H-bond engagement.
**Deepest Vina pose (-6.07) of the 4** + highest gnina CNN-pKd (4.69).
Boltz Kd 8.16 / 8.76 µM. Adds urea-linker chemotype diversity. $375
high-chem-risk (urea synthesis is the limiting step).

### Pick 4: `FM001452_analog_0171`
Pyridyl-benzyl-ether-aniline. **Pyridyl basic-N for selectivity probing**
— may differentiate TBXT from T-box paralogs. **Highest prob_binder
(0.46)** of the 4. Tightest dual-engine Boltz agreement (1.02×). $250
medium-risk.

(Full per-pick rationale + 2D + 3D pose renders: `top4_rationale.md`)

## Cross-validation evidence

| Signal | Where | Status for the 4 picks |
|---|---|---|
| Multi-method consensus (6 signals) | `evidence/CONVERGENCE_AUDIT.md` | All 4 in v2/v3 robust set (FM_* family) |
| Dual-engine Boltz (Jack + SCC) | `evidence/boltz_summary_scc.csv` | Agreement 1.01-1.34× across all 4 |
| Rowan ADMET (49 properties) | `evidence/rowan_re_rank.{json,md}` | All 4 ADMET-profiled |
| **Rowan pose-analysis MD** (explicit-solvent, 5 ns × 1 traj + 1 ns equil) | `evidence/rowan_pose_md_<id>.json` | See per-file presence; 2-4 of 4 expected at submission time |
| Onepot.ai catalog (similarity + price + risks) | `evidence/onepot_100pct_non_covalent_candidates.csv` | All 4 at similarity = 1.000 |

## Honest expectations

- Public methods over-predict Kd by **6-25×** at the µM regime per the validation set (HDB / CF Labs SPR). Realistic SPR for these 4: **18-200 µM range**.
- **Hackathon judging prize ($250 muni credits):** strong shot — multi-signal consensus + 7-criterion filter chain + transparent tier methodology directly maps to the three judging axes.
- **Experimental $100K @ Kd ≤ 1 µM:** plausible long-shot — best Boltz prediction is 3.2 µM, which becomes 18-75 µM at typical over-prediction. May land below 1 µM by chance for 1-2 of the 24 across the broader team submission.
- **Experimental $250K @ Kd ≤ 300 nM:** unlikely without further SAR — but the FM_* family is a workable starting point for hit-to-lead optimization.

## Reproducibility

- **GitHub:** `git@github.com:anandsahuofficial/Hackathon.git` branch `TBXT`
- **HF dataset bundles:** `anandsahuofficial/tbxt-hackathon-bundles`
- **Single-command setup for any teammate:** `bash TBXT/setup_hf.sh`
- **All 137 candidates with per-criterion flags:** `TBXT/final/all_candidates_tiered.csv`
- **Full rationale + tier definitions:** `TBXT/final/tiered/TIERED_CANDIDATES_RATIONALE.md`
- **This submission folder:** `TBXT/final/` — single source of truth (see `README.md`).
