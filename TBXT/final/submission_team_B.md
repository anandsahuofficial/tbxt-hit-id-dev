# TBXT Hit Identification — Submission (Team B)

**Subset:** Ranks 5-8
**Date:** 2026-05-09 · **Event:** TBXT Hit Identification Hackathon, Pillar VC Boston, hosted by muni.bio
**Team Name:** `<TEAM_BASE>-B` (replace `<TEAM_BASE>` with chosen base, e.g. `Brachyury Pillar Hunters`)
**Members:** `<NAME 1>, <NAME 2>` *(fill in)*
**Project lead:** Anand Sahu

## 4 Ranked Compounds

| Rank | ID | SMILES | Boltz Kd (Jack/SCC) | $ | risks |
|---:|---|---|---:|---:|:---:|
| **1** | `FM002150_analog_0082` | `O=C(O)COCc1ccc(-c2ccoc2)cc1` | 4.736 / 4.662 µM | $250 | medium/low |
| **2** | `FM001452_analog_0040` | `COc1cc(N)cc(OCc2ccccc2)c1` | 5.868 / 5.651 µM | $1000 | low/high |
| **3** | `FM001452_analog_0009` | `CNC(=O)Nc1cccc(OCc2ccccc2)c1` | 6.245 / 7.723 µM | $375 | high/medium |
| **4** | `FM001452_analog_0008` | `CS(=O)(=O)Nc1cccc(OCc2ccccc2)c1` | 6.315 / 6.991 µM | $375 | high/medium |

## SMILES (rank-ordered, copy-paste for portal)

```
FM002150_analog_0082	O=C(O)COCc1ccc(-c2ccoc2)cc1
FM001452_analog_0040	COc1cc(N)cc(OCc2ccccc2)c1
FM001452_analog_0009	CNC(=O)Nc1cccc(OCc2ccccc2)c1
FM001452_analog_0008	CS(=O)(=O)Nc1cccc(OCc2ccccc2)c1
```

## Why these 4

All 4 picks are drawn from a 137-compound pool that strictly satisfies every organizer constraint (see `TBXT/final/all_candidates_tiered.csv`). The 4 here are ranks FM002150_analog-class compounds at positions 5-8 of the tiered pool, ranked by predicted Boltz-2 Kd (lowest first).

**Filter chain — every compound passes all 7:**

C1 onepot 100% catalog match (similarity = 1.000 in muni `onepot` tool) · 
C2 strictly non-covalent (no boronic acids, no Michael acceptors) · 
C3 Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) · 
C4 lead-like ideal (10–30 HA, HBD+HBA ≤ 11, LogP < 5, < 5 rings, ≤ 2 fused) · 
C5 PAINS-clean + no acid halides / aldehydes / diazo / imines / polycyclic > 2 fused / long alkyl · 
C6 Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical · 
C7 predicted soluble (ESOL log S > -5)

## Per-pick rationale (1-2 lines each)

### Pick 1: `FM002150_analog_0082`

`O=C(O)COCc1ccc(-c2ccoc2)cc1`

Boltz Kd 4.736 / 4.662 µM; gnina Vina - kcal/mol; MW 232.2, LogP 2.55; onepot $$250, risks medium/low. balanced profile.

### Pick 2: `FM001452_analog_0040`

`COc1cc(N)cc(OCc2ccccc2)c1`

Boltz Kd 5.868 / 5.651 µM; gnina Vina - kcal/mol; MW 229.3, LogP 2.86; onepot $$1000, risks low/high. balanced profile.

### Pick 3: `FM001452_analog_0009`

`CNC(=O)Nc1cccc(OCc2ccccc2)c1`

Boltz Kd 6.245 / 7.723 µM; gnina Vina - kcal/mol; MW 256.3, LogP 3.02; onepot $$375, risks high/medium. balanced profile.

### Pick 4: `FM001452_analog_0008`

`CS(=O)(=O)Nc1cccc(OCc2ccccc2)c1`

Boltz Kd 6.315 / 6.991 µM; gnina Vina - kcal/mol; MW 277.3, LogP 2.64; onepot $$375, risks high/medium. balanced profile.

## **Methods + models used:** Multi-signal computational consensus pipeline. Tools/models: GNINA CNN docking (PDB 6F59 chain A, site F); Boltz-2 co-folding (3 samples × 200 sampling × 3 recycling, dual-engine cross-validation Jack local + SCC re-run); TBXT-specific QSAR (RF + XGBoost on 650 measured Naar SPR Kd); MMGBSA implicit-solvent refinement (OpenMM + GBn2); muni.bio `onepot` tool for catalog membership + price + chemistry/supplier risk; Rowan ADMET (49 properties) + Rowan Docking (Vina/Vinardo); T-box paralog selectivity (sequence-aware site-F contact analysis on 16 paralogs); RDKit ESOL solubility + Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) + lead-like ideal filter (10–30 HA, < 5 rings, ≤ 2 fused). Final hard gate: 100% onepot.ai catalog match (similarity = 1.000) + strictly non-covalent + Tanimoto < 0.85 to organizer DBs (Naar SPR, TEP fragments, prior_art_canonical).

## Honest expectations

Public methods over-predict Kd by 6-25× at µM regime. Realistic CF Labs SPR Kd for these 4: ~28-157 µM range. Submission targets the hackathon judging prize (rationale + tractability + judgment) primarily; experimental tier ($100K @ Kd ≤ 1 µM, $250K @ Kd ≤ 300 nM) is plausible long-shot for the strongest binders across the 24-compound team submission.

## See also (team-wide)

- `TBXT/final/all_candidates_tiered.csv` — all 137 organizer-compliant candidates with per-criterion flags
- `TBXT/final/tiered/TIERED_CANDIDATES_RATIONALE.md` — full tier definitions + 7-criterion explanation
- `TBXT/final/team_submissions.md` — single-table view across all 6 sub-teams
