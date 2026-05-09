---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification — Team C

**Subset:** Ranks 9-12

`<TEAM_BASE>-C` · `<NAME 1>, <NAME 2>`

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## Pipeline (one slide)

**570-compound novelty-filtered pool** scored on **6 orthogonal signals** (Vina ensemble, GNINA CNN, TBXT QSAR, Boltz-2, MMGBSA, T-box paralog selectivity), then gated through the **7-criterion strict filter**:

- C1 onepot 100% match · C2 non-covalent · C3 Chordoma chemistry · C4 lead-like · C5 PAINS-clean · C6 Tanimoto < 0.85 to organizer DBs · C7 predicted soluble

Of 570 → 137 pass all 7. Our team submits 24 across 6 sub-teams; this team (C) carries **ranks 9-12**.

---

## The 4 picks (Team C)

| # | ID | Boltz Kd Jack/SCC | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM001452_analog_0005` | 6.762 / 8.079 µM | - | $250 | medium/low |
| **2** | `FM001452_analog_0004` | 7.0 / 6.994 µM | - | $250 | medium/medium |
| **3** | `FM001452_analog_0020` | 7.002 / 7.286 µM | - | $125 | low/low |
| **4** | `FM002150_analog_0080` | 7.635 / 7.529 µM | - | $250 | medium/low |

All 4 picks: 100% onepot.ai catalog match · strictly non-covalent · Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical.

---

## Pick 1: `FM001452_analog_0005`

**SMILES:** `CCC(=O)Nc1cccc(OCc2ccccc2)c1`

- Boltz Kd: 6.762 / 8.079 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 255.3, LogP 3.61, HBD 1, HBA 2
- Onepot: similarity 1.000 · price $250 · chem_risk medium · supplier_risk low

---

## Pick 2: `FM001452_analog_0004`

**SMILES:** `CC(=O)Nc1cccc(OCc2ccccc2)c1`

- Boltz Kd: 7.0 / 6.994 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 241.3, LogP 3.22, HBD 1, HBA 2
- Onepot: similarity 1.000 · price $250 · chem_risk medium · supplier_risk medium

---

## Pick 3: `FM001452_analog_0020`

**SMILES:** `Cc1ccc(OCc2ccccc2)cc1N`

- Boltz Kd: 7.002 / 7.286 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 213.3, LogP 3.16, HBD 1, HBA 2
- Onepot: similarity 1.000 · price $125 · chem_risk low · supplier_risk low

---

## Pick 4: `FM002150_analog_0080`

**SMILES:** `O=C(O)COCc1ccc(-c2ccncc2)cc1`

- Boltz Kd: 7.635 / 7.529 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 243.3, LogP 2.35, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $250 · chem_risk medium · supplier_risk low

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
