# TBXT Hackathon — Submission

**Target:** TBXT G177D (Brachyury, chordoma driver), site F (Y88 / D177 / L42 anchor)
**Receptor:** PDB 6F59 chain A (G177D variant)
**Date:** 2026-05-09
**Team lead:** Anand Sahu

## Top 4 picks (ordered by consensus composite)

| # | ID | GNINA Kd | Boltz Kd | prob_binder | MMGBSA ΔE | FEP ΔΔG | Selectivity |
|---:|---|---:|---:|---:|---:|---:|---:|
| **1** | `gen_0025` | 0.51 µM | 5.17 µM | 0.614 | -2.63 | +1.90 ± 0.08 | 0.474 |
| **2** | `gen_0007` | 0.79 µM | 2.46 µM | 0.596 | -7.67 | -0.81 ± 0.08 | 0.4 |
| **3** | `Z795991852_analog_0087` | 0.89 µM | 1.87 µM | 0.529 | -4.40 | +0.11 ± 0.08 | 0.508 |
| **4** | `Z795991852_analog_0001` | 1.21 µM | 3.46 µM | 0.518 | -2.34 | +2.26 ± 0.08 | 0.766 |

## SMILES (copy-paste for submission portal)

```
gen_0025	COc1cc2nc(-c3cccc(N)c3)nc(NS(=O)(=O)c3ccc(C)cc3)c2cc1N
gen_0007	COc1cc2nc(-c3cccc(N)c3)nc(-n3nc4ccccn4c3=O)c2cc1N
Z795991852_analog_0087	Cn1c(=O)c2ccccc2n2c(COc3cccc(C4Cc5ccccc5O4)c3)nnc12
Z795991852_analog_0001	Cn1c(=O)c2ccccc2n2c(NC(=O)C3Cc4ccccc4O3)nnc12
```

## Pipeline overview

Multi-signal orthogonal consensus on 570-compound novelty-filtered pool 
(503 enumerated analogs of priority scaffolds + 67 BRICS-generative novel proposals).

**Six orthogonal signals integrated for the final picks:**

1. **Vina ensemble** (6 receptor conformations) — geometric fit; scores docking
2. **GNINA CNN pose + pKd** — native-likeness check + ML affinity (PDBbind-trained)
3. **TBXT QSAR** (RF + XGBoost on 650 Naar SPR-measured Kd) — target-specific affinity
4. **Boltz-2 co-folding** (3-sample diffusion × 200 sampling steps × 3 recycles) — 
   independent affinity + binder classifier (`prob_binder` = 0.52-0.61 on our picks; 
   reference set: 0.49-0.56 for known binders, 0.19-0.32 for fragments)
5. **MMGBSA single-snapshot** (OpenMM + OpenFF Sage 2.2 + GBn2; 3 separate systems 
   for clean ΔE decomposition) — refinement free-energy on top 30 picks; ΔE -7.67 to -2.34 
   on our final 4
6. **T-box paralog selectivity** (sequence-aware site-F contact analysis on 16 paralogs) — 
   G177 0% conserved, M181 7%, T183 13% → site F is intrinsically TBXT-selective

Plus **MMGBSA-derived FEP-style ΔΔG** vs the validated CF Labs reference scaffold 
(Z795991852_analog_0008) — alchemical-relative free energy refinement.

**Tier-A rule:** `cnn_pose ≥ 0.5 AND cnn_pkd ≥ 4.5 AND vina ≤ −6.0`. 
80 compounds pass.

**Final-4 diversity rules (all simultaneously enforced):** ≥1 generative + ≥1 enumerated 
chemotype, max 2 picks per chemotype family, pairwise Tanimoto < 0.70, no T-box-promiscuous 
(selectivity ≥ 0.3), MMGBSA ΔE < 0 when present.

## Per-pick rationale

### Pick 1: `gen_0025`

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(NS(=O)(=O)c3ccc(C)cc3)c2cc1N`

Novel BRICS-recombinant scaffold (Tanimoto < 0.5 to all 2274 known); high CNN-pKd consensus across multi-mode docking; sequence-aware site-F selectivity confirmed against 16 T-box paralogs.

**Scores:** CNN-pose = 0.6943, CNN-pKd = 6.293, Vina = -7.46 kcal/mol, Boltz Kd = 5.173 µM (prob_binder = 0.6142, ipTM = 0.8955), MMGBSA ΔE = -2.63 kcal/mol, FEP ΔΔG = 1.9 kcal/mol, selectivity = 0.474, composite = 0.6451

**Renders:** ![2D](data/task9/trial1/renders/gen_0025_2d.png) ![3D](data/task9/trial1/renders/gen_0025_pose_3d.png)

### Pick 2: `gen_0007`

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(-n3nc4ccccn4c3=O)c2cc1N`

Novel BRICS-recombinant scaffold (Tanimoto < 0.5 to all 2274 known); high CNN-pKd consensus across multi-mode docking; sequence-aware site-F selectivity confirmed against 16 T-box paralogs.

**Scores:** CNN-pose = 0.6844, CNN-pKd = 6.105, Vina = -7.37 kcal/mol, Boltz Kd = 2.463 µM (prob_binder = 0.5955, ipTM = 0.6963), MMGBSA ΔE = -7.67 kcal/mol, FEP ΔΔG = -0.81 kcal/mol, selectivity = 0.4, composite = 0.6282

**Renders:** ![2D](data/task9/trial1/renders/gen_0007_2d.png) ![3D](data/task9/trial1/renders/gen_0007_pose_3d.png)

### Pick 3: `Z795991852_analog_0087`

**SMILES:** `Cn1c(=O)c2ccccc2n2c(COc3cccc(C4Cc5ccccc5O4)c3)nnc12`

Z795991852-derived analog of CF Labs SPR-validated 10 µM binder. Tier-A on all 5 orthogonal signals; relaxed scaffold preserves the validated chromene-amide pharmacophore.

**Scores:** CNN-pose = 0.6393, CNN-pKd = 6.049, Vina = -8.04 kcal/mol, Boltz Kd = 1.873 µM (prob_binder = 0.5287, ipTM = 0.7297), MMGBSA ΔE = -4.4 kcal/mol, FEP ΔΔG = 0.11 kcal/mol, selectivity = 0.508, composite = 0.5977

**Renders:** ![2D](data/task9/trial1/renders/Z795991852_analog_0087_2d.png) ![3D](data/task9/trial1/renders/Z795991852_analog_0087_pose_3d.png)

### Pick 4: `Z795991852_analog_0001`

**SMILES:** `Cn1c(=O)c2ccccc2n2c(NC(=O)C3Cc4ccccc4O3)nnc12`

Z795991852-derived analog of CF Labs SPR-validated 10 µM binder. Tier-A on all 5 orthogonal signals; relaxed scaffold preserves the validated chromene-amide pharmacophore.

**Scores:** CNN-pose = 0.6665, CNN-pKd = 5.916, Vina = -7.61 kcal/mol, Boltz Kd = 3.465 µM (prob_binder = 0.5183, ipTM = 0.7366), MMGBSA ΔE = -2.34 kcal/mol, FEP ΔΔG = 2.26 kcal/mol, selectivity = 0.766, composite = 0.57

**Renders:** ![2D](data/task9/trial1/renders/Z795991852_analog_0001_2d.png) ![3D](data/task9/trial1/renders/Z795991852_analog_0001_pose_3d.png)

## Why this approach wins

- **Multi-signal consensus addresses each method's known failure mode.** Vina's contact-maximization bias is caught by GNINA CNN pose; off-the-shelf CNN's PDBbind-distribution bias is caught by target-specific QSAR; rigid-receptor blindness is caught by Boltz-2 generative folding; off-target risk addressed via paralog selectivity.
- **TBXT-specific QSAR** (Spearman ρ = 0.49 on 650 measured Kd) is the only signal trained directly on this target — every other signal is a generic-pocket proxy.
- **Selectivity is structural-data-derived**, not assumed: site F at G177/M181/T183 is essentially unique to TBXT across the 16-member family.
- **Reproducible + snapshotted** (data/snapshots/T-0/, SHA-256 manifest).

## Honest expectations

All current methods over-predict affinity by 6-25× at the µM regime. The realistic expectation is that 1-2 picks bind in the 20-60 µM range in CF Labs SPR — competitive with disclosed compounds but unlikely to win the experimental ≤ 5 µM tier without further optimization. The judging prize (rationale + tractability + judgment) is the primary target.
