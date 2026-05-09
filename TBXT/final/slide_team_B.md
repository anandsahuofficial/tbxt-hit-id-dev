---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification — Team B

**Subset:** Ranks 5-8

`<TEAM_BASE>-B` · `<NAME 1>, <NAME 2>`

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## Pipeline (one slide)

**570-compound novelty-filtered pool** scored on **6 orthogonal signals** (Vina ensemble, GNINA CNN, TBXT QSAR, Boltz-2, MMGBSA, T-box paralog selectivity), then gated through the **7-criterion strict filter**:

- C1 onepot 100% match · C2 non-covalent · C3 Chordoma chemistry · C4 lead-like · C5 PAINS-clean · C6 Tanimoto < 0.85 to organizer DBs · C7 predicted soluble

Of 570 → 137 pass all 7. Our team submits 24 across 6 sub-teams; this team (B) carries **ranks 5-8**.

---

## The 4 picks (Team B)

| # | ID | Boltz Kd Jack/SCC | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM002150_analog_0082` | 4.736 / 4.662 µM | - | $250 | medium/low |
| **2** | `FM001452_analog_0040` | 5.868 / 5.651 µM | - | $1000 | low/high |
| **3** | `FM001452_analog_0009` | 6.245 / 7.723 µM | - | $375 | high/medium |
| **4** | `FM001452_analog_0008` | 6.315 / 6.991 µM | - | $375 | high/medium |

All 4 picks: 100% onepot.ai catalog match · strictly non-covalent · Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical.

---

## Pick 1: `FM002150_analog_0082`

**SMILES:** `O=C(O)COCc1ccc(-c2ccoc2)cc1`

- Boltz Kd: 4.736 / 4.662 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 232.2, LogP 2.55, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $250 · chem_risk medium · supplier_risk low

---

## Pick 2: `FM001452_analog_0040`

**SMILES:** `COc1cc(N)cc(OCc2ccccc2)c1`

- Boltz Kd: 5.868 / 5.651 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 229.3, LogP 2.86, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $1000 · chem_risk low · supplier_risk high

---

## Pick 3: `FM001452_analog_0009`

**SMILES:** `CNC(=O)Nc1cccc(OCc2ccccc2)c1`

- Boltz Kd: 6.245 / 7.723 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 256.3, LogP 3.02, HBD 2, HBA 2
- Onepot: similarity 1.000 · price $375 · chem_risk high · supplier_risk medium

---

## Pick 4: `FM001452_analog_0008`

**SMILES:** `CS(=O)(=O)Nc1cccc(OCc2ccccc2)c1`

- Boltz Kd: 6.315 / 6.991 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 277.3, LogP 2.64, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $375 · chem_risk high · supplier_risk medium

---

## Honest expectations

- Public methods over-predict Kd by 6-25× at µM regime
- Realistic SPR Kd: 18-265 µM range across the 4
- Targets hackathon judging prize primarily; 1 µM experimental tier ($100K) plausible long-shot

---

## Reproducibility

- **GitHub:** `git@github.com:anandsahuofficial/Hackathon.git` branch `TBXT`
- **All 137 candidates with per-criterion flags:** `TBXT/final/all_candidates_tiered.csv`
- **Team-wide table:** `TBXT/final/team_submissions.md`
