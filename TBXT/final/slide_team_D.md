---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification — Team D

**Subset:** Ranks 13-16

`<TEAM_BASE>-D` · `<NAME 1>, <NAME 2>`

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## Pipeline (one slide)

**570-compound novelty-filtered pool** scored on **6 orthogonal signals** (Vina ensemble, GNINA CNN, TBXT QSAR, Boltz-2, MMGBSA, T-box paralog selectivity), then gated through the **7-criterion strict filter**:

- C1 onepot 100% match · C2 non-covalent · C3 Chordoma chemistry · C4 lead-like · C5 PAINS-clean · C6 Tanimoto < 0.85 to organizer DBs · C7 predicted soluble

Of 570 → 137 pass all 7. Our team submits 24 across 6 sub-teams; this team (D) carries **ranks 13-16**.

---

## The 4 picks (Team D)

| # | ID | Boltz Kd Jack/SCC | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM002150_analog_0053` | 8.195 / 9.686 µM | - | $590 | medium/medium |
| **2** | `FM002150_analog_0056` | 8.343 / 8.333 µM | - | $885 | high/medium |
| **3** | `FM001452_analog_0155` | 8.472 / 8.447 µM | - | $125 | low/low |
| **4** | `FM001452_analog_0162` | 9.513 / 8.771 µM | - | $125 | low/medium |

All 4 picks: 100% onepot.ai catalog match · strictly non-covalent · Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical.

---

## Pick 1: `FM002150_analog_0053`

**SMILES:** `O=C(O)COCc1cccc(-c2ccncc2)c1`

- Boltz Kd: 8.195 / 9.686 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 243.3, LogP 2.35, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $590 · chem_risk medium · supplier_risk medium

---

## Pick 2: `FM002150_analog_0056`

**SMILES:** `O=C(O)COCc1cccc(-c2ccsc2)c1`

- Boltz Kd: 8.343 / 8.333 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 248.3, LogP 3.02, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $885 · chem_risk high · supplier_risk medium

---

## Pick 3: `FM001452_analog_0155`

**SMILES:** `COc1ccc(COc2cccc(N)c2)cc1`

- Boltz Kd: 8.472 / 8.447 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 229.3, LogP 2.86, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $125 · chem_risk low · supplier_risk low

---

## Pick 4: `FM001452_analog_0162`

**SMILES:** `Cc1ccc(COc2cccc(N)c2)cc1`

- Boltz Kd: 9.513 / 8.771 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 213.3, LogP 3.16, HBD 1, HBA 2
- Onepot: similarity 1.000 · price $125 · chem_risk low · supplier_risk medium

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
