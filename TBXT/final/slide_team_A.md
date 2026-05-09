---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification — Team A

**Subset:** Top 4 — judges-facing primary

`<TEAM_BASE>-A` · `<NAME 1>, <NAME 2>`

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## Pipeline (one slide)

**570-compound novelty-filtered pool** scored on **6 orthogonal signals** (Vina ensemble, GNINA CNN, TBXT QSAR, Boltz-2, MMGBSA, T-box paralog selectivity), then gated through the **7-criterion strict filter**:

- C1 onepot 100% match · C2 non-covalent · C3 Chordoma chemistry · C4 lead-like · C5 PAINS-clean · C6 Tanimoto < 0.85 to organizer DBs · C7 predicted soluble

Of 570 → 137 pass all 7. Our team submits 24 across 6 sub-teams; this team (A) carries **ranks 1-4**.

---

## The 4 picks (Team A)

| # | ID | Boltz Kd Jack/SCC | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM002150_analog_0083` | 3.2 / 3.256 µM | - | $- | -/- |
| **2** | `FM001452_analog_0104` | 3.722 / 4.973 µM | - | $125 | low/medium |
| **3** | `FM001452_analog_0201` | 8.157 / 8.761 µM | - | $375 | high/medium |
| **4** | `FM001452_analog_0171` | 8.318 / 8.171 µM | - | $250 | medium/medium |

All 4 picks: 100% onepot.ai catalog match · strictly non-covalent · Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical.

---

## Pick 1: `FM002150_analog_0083`

**SMILES:** `O=C(O)COCc1ccc(-c2ccsc2)cc1`

- Boltz Kd: 3.2 / 3.256 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 248.3, LogP 3.02, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $- · chem_risk - · supplier_risk -

---

## Pick 2: `FM001452_analog_0104`

**SMILES:** `Cc1ccccc1COc1cccc(N)c1`

- Boltz Kd: 3.722 / 4.973 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 213.3, LogP 3.16, HBD 1, HBA 2
- Onepot: similarity 1.000 · price $125 · chem_risk low · supplier_risk medium

---

## Pick 3: `FM001452_analog_0201`

**SMILES:** `NC(=O)Nc1cccc(OCc2ccccc2)c1`

- Boltz Kd: 8.157 / 8.761 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 242.3, LogP 2.76, HBD 2, HBA 2
- Onepot: similarity 1.000 · price $375 · chem_risk high · supplier_risk medium

---

## Pick 4: `FM001452_analog_0171`

**SMILES:** `Nc1cccc(OCc2ccc(-c3ccncc3)cc2)c1`

- Boltz Kd: 8.318 / 8.171 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 276.3, LogP 3.91, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $250 · chem_risk medium · supplier_risk medium

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
