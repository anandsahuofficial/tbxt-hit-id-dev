# TBXT Hit Identification — Submission (Team D)

**Subset:** Ranks 13-16
**Date:** 2026-05-09 · **Event:** TBXT Hit Identification Hackathon, Pillar VC Boston, hosted by muni.bio
**Team Name:** `<TEAM_BASE>-D` (replace `<TEAM_BASE>` with chosen base, e.g. `Brachyury Pillar Hunters`)
**Members:** `<NAME 1>, <NAME 2>` *(fill in)*
**Project lead:** Anand Sahu

## 4 Ranked Compounds

| Rank | ID | SMILES | Boltz Kd (Jack/SCC) | $ | risks |
|---:|---|---|---:|---:|:---:|
| **1** | `FM002150_analog_0053` | `O=C(O)COCc1cccc(-c2ccncc2)c1` | 8.195 / 9.686 µM | $590 | medium/medium |
| **2** | `FM002150_analog_0056` | `O=C(O)COCc1cccc(-c2ccsc2)c1` | 8.343 / 8.333 µM | $885 | high/medium |
| **3** | `FM001452_analog_0155` | `COc1ccc(COc2cccc(N)c2)cc1` | 8.472 / 8.447 µM | $125 | low/low |
| **4** | `FM001452_analog_0162` | `Cc1ccc(COc2cccc(N)c2)cc1` | 9.513 / 8.771 µM | $125 | low/medium |

## SMILES (rank-ordered, copy-paste for portal)

```
FM002150_analog_0053	O=C(O)COCc1cccc(-c2ccncc2)c1
FM002150_analog_0056	O=C(O)COCc1cccc(-c2ccsc2)c1
FM001452_analog_0155	COc1ccc(COc2cccc(N)c2)cc1
FM001452_analog_0162	Cc1ccc(COc2cccc(N)c2)cc1
```

## Why these 4

All 4 picks are drawn from a 137-compound pool that strictly satisfies every organizer constraint (see `TBXT/final/all_candidates_tiered.csv`). The 4 here are ranks FM002150_analog-class compounds at positions 13-16 of the tiered pool, ranked by predicted Boltz-2 Kd (lowest first).

**Filter chain — every compound passes all 7:**

C1 onepot 100% catalog match (similarity = 1.000 in muni `onepot` tool) · 
C2 strictly non-covalent (no boronic acids, no Michael acceptors) · 
C3 Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) · 
C4 lead-like ideal (10–30 HA, HBD+HBA ≤ 11, LogP < 5, < 5 rings, ≤ 2 fused) · 
C5 PAINS-clean + no acid halides / aldehydes / diazo / imines / polycyclic > 2 fused / long alkyl · 
C6 Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical · 
C7 predicted soluble (ESOL log S > -5)

## Per-pick rationale (1-2 lines each)

### Pick 1: `FM002150_analog_0053`

`O=C(O)COCc1cccc(-c2ccncc2)c1`

Boltz Kd 8.195 / 9.686 µM; gnina Vina - kcal/mol; MW 243.3, LogP 2.35; onepot $$590, risks medium/medium. balanced profile.

### Pick 2: `FM002150_analog_0056`

`O=C(O)COCc1cccc(-c2ccsc2)c1`

Boltz Kd 8.343 / 8.333 µM; gnina Vina - kcal/mol; MW 248.3, LogP 3.02; onepot $$885, risks high/medium. balanced profile.

### Pick 3: `FM001452_analog_0155`

`COc1ccc(COc2cccc(N)c2)cc1`

Boltz Kd 8.472 / 8.447 µM; gnina Vina - kcal/mol; MW 229.3, LogP 2.86; onepot $$125, risks low/low. clean low/low risks · cheapest tier ($125).

### Pick 4: `FM001452_analog_0162`

`Cc1ccc(COc2cccc(N)c2)cc1`

Boltz Kd 9.513 / 8.771 µM; gnina Vina - kcal/mol; MW 213.3, LogP 3.16; onepot $$125, risks low/medium. cheapest tier ($125) · mass-efficient (<220 Da).

## **Methods + models used:** Multi-signal computational consensus pipeline. Tools/models: GNINA CNN docking (PDB 6F59 chain A, site F); Boltz-2 co-folding (3 samples × 200 sampling × 3 recycling, dual-engine cross-validation Jack local + SCC re-run); TBXT-specific QSAR (RF + XGBoost on 650 measured Naar SPR Kd); MMGBSA implicit-solvent refinement (OpenMM + GBn2); muni.bio `onepot` tool for catalog membership + price + chemistry/supplier risk; Rowan ADMET (49 properties) + Rowan Docking (Vina/Vinardo); T-box paralog selectivity (sequence-aware site-F contact analysis on 16 paralogs); RDKit ESOL solubility + Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) + lead-like ideal filter (10–30 HA, < 5 rings, ≤ 2 fused). Final hard gate: 100% onepot.ai catalog match (similarity = 1.000) + strictly non-covalent + Tanimoto < 0.85 to organizer DBs (Naar SPR, TEP fragments, prior_art_canonical).

## Honest expectations

Public methods over-predict Kd by 6-25× at µM regime. Realistic CF Labs SPR Kd for these 4: ~49-237 µM range. Submission targets the hackathon judging prize (rationale + tractability + judgment) primarily; experimental tier ($100K @ Kd ≤ 1 µM, $250K @ Kd ≤ 300 nM) is plausible long-shot for the strongest binders across the 24-compound team submission.

## See also (team-wide)

- `TBXT/final/all_candidates_tiered.csv` — all 137 organizer-compliant candidates with per-criterion flags
- `TBXT/final/tiered/TIERED_CANDIDATES_RATIONALE.md` — full tier definitions + 7-criterion explanation
- `TBXT/final/team_submissions.md` — single-table view across all 6 sub-teams
