# TBXT Hit Identification — Submission (Team C)

**Subset:** Ranks 9-12
**Date:** 2026-05-09 · **Event:** TBXT Hit Identification Hackathon, Pillar VC Boston, hosted by muni.bio
**Team Name:** `<TEAM_BASE>-C` (replace `<TEAM_BASE>` with chosen base, e.g. `Brachyury Pillar Hunters`)
**Members:** `<NAME 1>, <NAME 2>` *(fill in)*
**Project lead:** Anand Sahu

## 4 Ranked Compounds

| Rank | ID | SMILES | Boltz Kd (Jack/SCC) | $ | risks |
|---:|---|---|---:|---:|:---:|
| **1** | `FM001452_analog_0005` | `CCC(=O)Nc1cccc(OCc2ccccc2)c1` | 6.762 / 8.079 µM | $250 | medium/low |
| **2** | `FM001452_analog_0004` | `CC(=O)Nc1cccc(OCc2ccccc2)c1` | 7.0 / 6.994 µM | $250 | medium/medium |
| **3** | `FM001452_analog_0020` | `Cc1ccc(OCc2ccccc2)cc1N` | 7.002 / 7.286 µM | $125 | low/low |
| **4** | `FM002150_analog_0080` | `O=C(O)COCc1ccc(-c2ccncc2)cc1` | 7.635 / 7.529 µM | $250 | medium/low |

## SMILES (rank-ordered, copy-paste for portal)

```
FM001452_analog_0005	CCC(=O)Nc1cccc(OCc2ccccc2)c1
FM001452_analog_0004	CC(=O)Nc1cccc(OCc2ccccc2)c1
FM001452_analog_0020	Cc1ccc(OCc2ccccc2)cc1N
FM002150_analog_0080	O=C(O)COCc1ccc(-c2ccncc2)cc1
```

## Why these 4

All 4 picks are drawn from a 137-compound pool that strictly satisfies every organizer constraint (see `TBXT/final/all_candidates_tiered.csv`). The 4 here are ranks FM001452_analog-class compounds at positions 9-12 of the tiered pool, ranked by predicted Boltz-2 Kd (lowest first).

**Filter chain — every compound passes all 7:**

C1 onepot 100% catalog match (similarity = 1.000 in muni `onepot` tool) · 
C2 strictly non-covalent (no boronic acids, no Michael acceptors) · 
C3 Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) · 
C4 lead-like ideal (10–30 HA, HBD+HBA ≤ 11, LogP < 5, < 5 rings, ≤ 2 fused) · 
C5 PAINS-clean + no acid halides / aldehydes / diazo / imines / polycyclic > 2 fused / long alkyl · 
C6 Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical · 
C7 predicted soluble (ESOL log S > -5)

## Per-pick rationale (1-2 lines each)

### Pick 1: `FM001452_analog_0005`

`CCC(=O)Nc1cccc(OCc2ccccc2)c1`

Boltz Kd 6.762 / 8.079 µM; gnina Vina - kcal/mol; MW 255.3, LogP 3.61; onepot $$250, risks medium/low. balanced profile.

### Pick 2: `FM001452_analog_0004`

`CC(=O)Nc1cccc(OCc2ccccc2)c1`

Boltz Kd 7.0 / 6.994 µM; gnina Vina - kcal/mol; MW 241.3, LogP 3.22; onepot $$250, risks medium/medium. balanced profile.

### Pick 3: `FM001452_analog_0020`

`Cc1ccc(OCc2ccccc2)cc1N`

Boltz Kd 7.002 / 7.286 µM; gnina Vina - kcal/mol; MW 213.3, LogP 3.16; onepot $$125, risks low/low. clean low/low risks · cheapest tier ($125) · mass-efficient (<220 Da).

### Pick 4: `FM002150_analog_0080`

`O=C(O)COCc1ccc(-c2ccncc2)cc1`

Boltz Kd 7.635 / 7.529 µM; gnina Vina - kcal/mol; MW 243.3, LogP 2.35; onepot $$250, risks medium/low. balanced profile.

## **Methods + models used:** Multi-signal computational consensus pipeline. Tools/models: GNINA CNN docking (PDB 6F59 chain A, site F); Boltz-2 co-folding (3 samples × 200 sampling × 3 recycling, dual-engine cross-validation Jack local + SCC re-run); TBXT-specific QSAR (RF + XGBoost on 650 measured Naar SPR Kd); MMGBSA implicit-solvent refinement (OpenMM + GBn2); muni.bio `onepot` tool for catalog membership + price + chemistry/supplier risk; Rowan ADMET (49 properties) + Rowan Docking (Vina/Vinardo); T-box paralog selectivity (sequence-aware site-F contact analysis on 16 paralogs); RDKit ESOL solubility + Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) + lead-like ideal filter (10–30 HA, < 5 rings, ≤ 2 fused). Final hard gate: 100% onepot.ai catalog match (similarity = 1.000) + strictly non-covalent + Tanimoto < 0.85 to organizer DBs (Naar SPR, TEP fragments, prior_art_canonical).

## Honest expectations

Public methods over-predict Kd by 6-25× at µM regime. Realistic CF Labs SPR Kd for these 4: ~40-190 µM range. Submission targets the hackathon judging prize (rationale + tractability + judgment) primarily; experimental tier ($100K @ Kd ≤ 1 µM, $250K @ Kd ≤ 300 nM) is plausible long-shot for the strongest binders across the 24-compound team submission.

## See also (team-wide)

- `TBXT/final/all_candidates_tiered.csv` — all 137 organizer-compliant candidates with per-criterion flags
- `TBXT/final/tiered/TIERED_CANDIDATES_RATIONALE.md` — full tier definitions + 7-criterion explanation
- `TBXT/final/team_submissions.md` — single-table view across all 6 sub-teams
