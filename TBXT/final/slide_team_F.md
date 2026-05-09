---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification — Team F

**Subset:** Ranks 21-24

`<TEAM_BASE>-F` · `<NAME 1>, <NAME 2>`

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## Pipeline (one slide)

**570-compound novelty-filtered pool** scored on **6 orthogonal signals** (Vina ensemble, GNINA CNN, TBXT QSAR, Boltz-2, MMGBSA, T-box paralog selectivity), then gated through the **7-criterion strict filter**:

- C1 onepot 100% match · C2 non-covalent · C3 Chordoma chemistry · C4 lead-like · C5 PAINS-clean · C6 Tanimoto < 0.85 to organizer DBs · C7 predicted soluble

Of 570 → 137 pass all 7. Our team submits 24 across 6 sub-teams; this team (F) carries **ranks 21-24**.

---

## The 4 picks (Team F)

| # | ID | Boltz Kd Jack/SCC | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM001452_analog_0029` | 7.464 / 7.527 µM | - | $295 | low/low |
| **2** | `FM001452_analog_0059` | 7.856 / 7.598 µM | - | $590 | medium/low |
| **3** | `FM002150_analog_0027` | 10.34 / 9.307 µM | - | $885 | high/medium |
| **4** | `FM001452_analog_0015` | 10.253 / 11.556 µM | - | $1000 | low/high |

All 4 picks: 100% onepot.ai catalog match · strictly non-covalent · Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical.

---

## Pick 1: `FM001452_analog_0029`

**SMILES:** `Nc1cc(OCc2ccccc2)ccc1-c1ccncc1`

- Boltz Kd: 7.464 / 7.527 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 276.3, LogP 3.91, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $295 · chem_risk low · supplier_risk low

---

## Pick 2: `FM001452_analog_0059`

**SMILES:** `Nc1cc(OCc2ccccc2)cc(-c2ccccn2)c1`

- Boltz Kd: 7.856 / 7.598 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 276.3, LogP 3.91, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $590 · chem_risk medium · supplier_risk low

---

## Pick 3: `FM002150_analog_0027`

**SMILES:** `O=C(O)COCc1ccccc1-c1ccsc1`

- Boltz Kd: 10.34 / 9.307 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 248.3, LogP 3.02, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $885 · chem_risk high · supplier_risk medium

---

## Pick 4: `FM001452_analog_0015`

**SMILES:** `Nc1cc(OCc2ccccc2)ccc1C(F)(F)F`

- Boltz Kd: 10.253 / 11.556 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 267.2, LogP 3.87, HBD 1, HBA 2
- Onepot: similarity 1.000 · price $1000 · chem_risk low · supplier_risk high

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
