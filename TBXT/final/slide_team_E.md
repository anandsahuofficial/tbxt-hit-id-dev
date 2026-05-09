---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification — Team E

**Subset:** Ranks 17-20

`<TEAM_BASE>-E` · `<NAME 1>, <NAME 2>`

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## Pipeline (one slide)

**570-compound novelty-filtered pool** scored on **6 orthogonal signals** (Vina ensemble, GNINA CNN, TBXT QSAR, Boltz-2, MMGBSA, T-box paralog selectivity), then gated through the **7-criterion strict filter**:

- C1 onepot 100% match · C2 non-covalent · C3 Chordoma chemistry · C4 lead-like · C5 PAINS-clean · C6 Tanimoto < 0.85 to organizer DBs · C7 predicted soluble

Of 570 → 137 pass all 7. Our team submits 24 across 6 sub-teams; this team (E) carries **ranks 17-20**.

---

## The 4 picks (Team E)

| # | ID | Boltz Kd Jack/SCC | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM001452_analog_0001` | 9.296 / 9.906 µM | - | $295 | low/medium |
| **2** | `FM001452_analog_0030` | 5.974 / 5.862 µM | - | $540 | low/low |
| **3** | `opv1_000076` | gnina Kd 6.32 µM | - | $375 | high/low |
| **4** | `FM001452_analog_0032` | 6.343 / 6.475 µM | - | $590 | medium/low |

All 4 picks: 100% onepot.ai catalog match · strictly non-covalent · Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical.

---

## Pick 1: `FM001452_analog_0001`

**SMILES:** `Nc1cccc(OCc2ccncc2)c1`

- Boltz Kd: 9.296 / 9.906 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 200.2, LogP 2.24, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $295 · chem_risk low · supplier_risk medium

---

## Pick 2: `FM001452_analog_0030`

**SMILES:** `Nc1cc(OCc2ccccc2)ccc1-c1ccccn1`

- Boltz Kd: 5.974 / 5.862 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 276.3, LogP 3.91, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $540 · chem_risk low · supplier_risk low

---

## Pick 3: `opv1_000076`

**SMILES:** `O=C(Nc1cccc(Br)c1)Nc1cccc(Br)c1`

- Boltz Kd: gnina Kd 6.32 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 370.0, LogP 4.86, HBD 2, HBA 1
- Onepot: similarity 1.000 · price $375 · chem_risk high · supplier_risk low

---

## Pick 4: `FM001452_analog_0032`

**SMILES:** `Nc1cc(OCc2ccccc2)ccc1-c1ccsc1`

- Boltz Kd: 6.343 / 6.475 µM
- gnina Vina: - kcal/mol; CNN-pKd: -
- MW 281.4, LogP 4.58, HBD 1, HBA 3
- Onepot: similarity 1.000 · price $590 · chem_risk medium · supplier_risk low

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
