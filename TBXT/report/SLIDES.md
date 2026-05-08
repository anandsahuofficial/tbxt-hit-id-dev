---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification

**Multi-signal consensus pipeline for chordoma's master regulator**

Anand Sahu — TBXT Hackathon, Pillar VC Boston, May 9, 2026

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

---

## What we built

**570-compound novelty-filtered pool**, scored on **6 orthogonal signals**:

| Signal | What it catches |
|---|---|
| **Vina ensemble** (6 receptor confs) | Geometric fit; receptor flexibility |
| **GNINA CNN pose + pKd** | Vina-trap detection (contact-maximizing decoys); ML affinity |
| **TBXT QSAR** (RF + XGBoost on 650 Naar SPR Kd) | Target-specific affinity (the only on-target signal) |
| **Boltz-2 co-folding** (3 samples × 200 steps) | Independent affinity + binder/non-binder classifier |
| **MMGBSA single-snapshot** (OpenMM + GBn2) | Free-energy refinement (top 30) |
| **T-box paralog selectivity** (sequence-aware site-F contacts × 16 paralogs) | Off-target risk |

Plus **MMGBSA-derived ΔΔG vs CF Labs reference scaffold** (Z795991852_analog_0008).

---

## Why a multi-signal stack

Each method has a known failure mode:

- **Vina** rewards contact-maximizing decoys → caught by **GNINA CNN pose**
- **GNINA CNN affinity** is PDBbind-distribution-biased → corrected by **target-specific QSAR**
- **Rigid-receptor docking** is induced-fit-blind → addressed by **Boltz-2 generative co-folding**
- **All docking** is gas-phase → refined by **MMGBSA implicit solvent**
- **Off-target bias** is invisible to docking alone → caught by **paralog selectivity**

Validation on 6 reference compounds (3 CF Labs binders + 3 TEP fragments):
- Boltz `prob_binder` cleanly separates binders (0.49–0.56) from fragments (0.19–0.32)
- QSAR within 10–30% on Z795991852 (most accurate single method on TBXT)
- GNINA CNN catches Vina-traps (D203-0031 has CNN pose 0.23 — legitimately uncertain)

---

## Why site F

TEP recommends site F + site A. We focused on F because:

1. **Engages D177 directly** — the variant residue. Pocket is unique to TBXT G177D.
2. **All best Naar SPR binders predicted at site F** (HDB + CF Labs)
3. **Most isolated chemotype space** — Z795991852 has Tanimoto 0.27 to its nearest disclosed neighbor
4. **Sequence-aware selectivity** — G177 (0% conserved across 16 T-box paralogs), M181 (7%), T183 (13%) → site F is intrinsically TBXT-selective

---

## Final 4 picks

| # | ID | GNINA Kd | Boltz Kd | prob_binder | MMGBSA ΔE | FEP ΔΔG vs ref | Selectivity |
|---:|---|---:|---:|---:|---:|---:|---:|
| **1** | `gen_0025` | 0.51 µM | 5.17 µM | 0.61 | -2.63 | +1.90 | 0.47 |
| **2** | `gen_0007` | 0.79 µM | 2.46 µM | 0.60 | **-7.67** | **-0.81** ✓ | 0.40 |
| **3** | `Z795991852_analog_0087` | 0.89 µM | **1.87 µM** | 0.53 | -4.40 | +0.11 | 0.51 |
| **4** | `Z795991852_analog_0001` | 1.21 µM | 3.46 µM | 0.52 | -2.34 | +2.26 | **0.77** |

Pairwise Tanimoto < 0.55. All Tier-A on multi-mode docking. All Boltz-confirmed binders (prob ≥ 0.52). All MMGBSA-favorable (ΔE between -2.34 and -7.67 kcal/mol).

---

## Pick 1: gen_0025 — novel BRICS sulfonamide

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(NS(=O)(=O)c3ccc(C)cc3)c2cc1N`

- Novel scaffold (Tanimoto < 0.5 to all 2274 known compounds)
- Highest **Boltz prob_binder** in our 4 picks (0.61) and high ipTM (0.90)
- Sulfonamide chemotype is **chemically distinct** from the Z-series (orthogonal hypothesis)
- Engages 9 site-F residues including all 5 TBXT-unique ones (R174, G/D177, M181, T183, L42)

⚠ Note: sulfonamide formation is not in onepot's listed 7 reactions — confirm onepot membership at submission.

---

## Pick 2: gen_0007 — strongest by free-energy

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(-n3nc4ccccn4c3=O)c2cc1N`

- **MMGBSA ΔE = -7.67 kcal/mol** (best of all 30 MMGBSA-screened compounds)
- **FEP ΔΔG = -0.81 kcal/mol** vs CF Labs reference Z795991852_analog_0008 (BEATS the validated reference)
- Triazolopyridazinone warhead at the D177-engagement pocket
- Boltz prob_binder 0.60, predicted Boltz Kd 2.5 µM

The free-energy methods (orthogonal to docking) both put gen_0007 ahead of the reference. Strongest evidence-of-binding pick.

---

## Pick 3: Z795991852_analog_0087 — best Boltz Kd

**SMILES:** `Cn1c(=O)c2ccccc2n2c(COc3cccc(C4Cc5ccccc5O4)c3)nnc12`

- Derived from Z795991852 (CF Labs SPR-validated 10 µM binder at site F)
- **Lowest Boltz Kd in top 30** (1.87 µM)
- MMGBSA ΔE = -4.40 kcal/mol (2nd-strongest)
- Vina = -8.04 kcal/mol (deepest pose)
- Preserves the validated chromene-amide pharmacophore via -O- linker variant

Tractability anchor: shares synthesis path with the validated parent.

---

## Pick 4: Z795991852_analog_0001 — selectivity champion

**SMILES:** `Cn1c(=O)c2ccccc2n2c(NC(=O)C3Cc4ccccc4O3)nnc12`

- **Highest selectivity score in top picks (0.77)** — all contacts on TBXT-unique residues
- Boltz prob_binder 0.52, Kd 3.5 µM
- MMGBSA ΔE = -2.34 kcal/mol
- Direct -CO-NH- linker (amide, in onepot's listed 7 reactions)

Chosen as the **off-target-risk hedge**: even if our affinity predictions are off by 5×, this pick is least likely to bind T-box paralogs.

---

## Honest expectations

- Public methods over-predict TBXT affinity by **6–25×** at the µM regime (validated on 6 reference compounds)
- HDB-vs-CF Labs SPR reproducibility is **3–10× spread** at µM Kd
- Realistic SPR outcome: **1–2 picks bind in 20–60 µM range** — competitive with disclosed compounds
- 1 µM tier (experimental prize) requires further optimization rounds; this submission is for the **judging prize**

We've prioritized **rationale and judgment over raw affinity claims**.

---

## Reproducibility

- **GitHub:** `git@github.com:anandsahuofficial/Hackathon.git` branch `TBXT`
- **HF dataset bundles:** `anandsahuofficial/tbxt-hackathon-bundles` (env + data + 570 docked poses + checksums)
- Single-command setup for any teammate: `bash TBXT/setup_hf.sh`
- Top-100 ranked CSV + final-4 picks CSV + per-pick rationale all in `TBXT/report/`
- T-0 snapshot frozen under `data/snapshots/post-prod/`

Pipeline scripts (`experiment_scripts/task1.sh` … `task10.sh`) are checkpointable and resumable; any team member can rerun any single signal independently.

---

## Q&A

Anything else?
