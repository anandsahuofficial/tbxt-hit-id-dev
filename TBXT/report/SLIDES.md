---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification

**Multi-signal consensus pipeline for chordoma's master regulator**

Anand Sahu — TBXT Hackathon, Pillar VC Boston, May 9, 2026

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

> v2 deck: pick #2 swapped `gen_0025` → `gen_0004` after T-0 cross-variant audit.

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

Plus **alchemical-style 12-λ × 5 ns FEP ΔΔG** vs CF Labs reference scaffold (Z795991852_analog_0008).

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

## Final 4 picks (site-diverse: 3F + 1A)

| # | ID | Site | GNINA Kd | Boltz Kd | prob_binder | MMGBSA ΔE | Reach | Selectivity |
|---:|---|:---:|---:|---:|---:|---:|---:|---:|
| **1** | `Z795991852_analog_0021` | A | **0.28 µM** | 0.46 µM ★ | 0.64 ★ | — | **1.00** | — |
| **2** | `gen_0004` (NEW) | F | 0.35 µM | 3.78 µM | 0.59 | -3.19 / -3.14 MD | 0.745 | 0.47 |
| **3** | `gen_0007` | F | 0.79 µM | 2.46 µM | 0.60 | **-7.67** | 0.74 | 0.40 |
| **4** | `Z795991852_analog_0087` | F | 0.89 µM | **1.87 µM** | 0.53 | -4.40 | **1.00** | 0.51 |

★ = added during T-0 audit (Jack full-pool Boltz). **Pick #2 swap rationale on the next slide.**

- **2 sites** (3 site-F + 1 site-A); **2 chemotypes** (2 novel BRICS + 2 Z795991852-derived)
- **All 4 picks now reachable via onepot CORE 7 reactions** (gen_0025 sulfonamide retired)

---

## Pick 1: gen_0004 — chemotype-preserving, synthesis-tractable swap

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(Cn3nc4ccccn4c3=O)c2cc1N`

**Why this is the swap-in (replacing gen_0025):**
- **Same chemotype** — Tanimoto 0.69 to gen_0025; same quinazoline-bisaniline core, same site-F engagement, same novel-scaffold rationale
- **Synthesis tractability** — `CH₂-N-aryl` linker (N-alkylation, in onepot CORE) replaces gen_0025's `N-S(=O)₂-Ar` sulfonamide (NOT in the 7 reactions). All 4 picks now strictly onepot-CORE reachable
- **Strictly better convergence** — wins on every refinement signal vs gen_0025: MMGBSA-MD ΔE -3.14 vs -2.51, alchemical FEP ΔΔG +0.53 vs +1.14, Mark-multiseed top-10 (gen_0025 not), composite 0.6749 (rank 1) vs 0.6451

Boltz prob_binder 0.59, ipTM 0.85, Vina -7.91 kcal/mol, CNN-pKd 6.45. Engages 9 site-F residues including the TBXT-unique R174 / G/D177 / M181 / T183 / L42 set.

---

## Pick 2: gen_0007 — strongest by free-energy

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(-n3nc4ccccn4c3=O)c2cc1N`

- **MMGBSA ΔE = -7.67 kcal/mol** (best of all 30 MMGBSA-screened compounds)
- **Alchemical FEP ΔΔG = -3.97 kcal/mol** vs CF Labs reference Z795991852_analog_0008 (12 λ × 5 ns; **only pick with negative ΔΔG — beats the validated reference**)
- v4 MMGBSA-MD ΔE = -7.7 kcal/mol (1 ns × 10 frames; rank 1 in v4)
- Triazolopyridazinone warhead at the D177-engagement pocket
- Boltz prob_binder 0.60, predicted Boltz Kd 2.5 µM

The free-energy methods (orthogonal to docking) both put gen_0007 ahead of the reference. Strongest evidence-of-binding pick.

---

## Pick 3 (wildcard): Z795991852_analog_0087 — catalog-tractable + pose-stable

**SMILES:** `Cn1c(=O)c2ccccc2n2c(COc3cccc(C4Cc5ccccc5O4)c3)nnc12`

- **Designated wildcard pick** — addresses organizer's recommended 2F + 1A + 1 wildcard composition while keeping site-F coverage at 3
- **Onepot.ai catalog: 86% top similarity** (highest of all 4 picks) — strongest catalog-membership evidence; most likely of the 4 to be in or one bond from the 3.4B onepot library
- Derived from Z795991852 (CF Labs SPR-validated 10 µM binder)
- **Lowest Boltz Kd in top 30** (1.87 µM); MMGBSA ΔE = -4.40 (2nd-strongest); Vina = -8.04 (deepest pose)
- **Mark 10-seed multiseed: lowest CNN-pKd σ (0.037) of any pick** — most pose-stable site-F pick

Tractability anchor: shares synthesis path with the validated parent.

---

## Pick 4: Z795991852_analog_0021 — site-A diversification

**SMILES:** `Cn1c(=O)c2ccccc2n2c(C(=O)NC(=O)c3cccc(C4Cc5ccccc5O4)c3)nnc12`

- **Picked at site A** (dimerization-interface secondary pocket) — single-site bet hedge
- **Site-A predicted Kd = 0.28 µM** (CNN pose 0.79, pKd 6.55, Vina −8.44 kcal/mol)
- **NEW Boltz coverage from T-0 audit:** Jack full-pool Boltz at site F gives Kd **0.46 µM, prob_binder 0.64** — best-Kd pick after the audit; first independent affinity signal at this compound
- **Mark 10-seed multiseed at site F: Vina = -8.50 ± 0.01** — most stable pose of all 4 picks
- **Onepot reachability score 1.00** via amide coupling — same disconnection as the validated parent

Chosen for **site-diversity** (organizer's recommended composition) and **synthesis tractability**.

---

## T-0 Convergence Audit — 5 variants + onepot.ai

10 independent ranking sources aggregated tonight: orig site-F · variant-1 onepot-friendly REINVENT gen · variant-3 receptor-ensemble (4 receptors LOCAL + SCC) · variant-4 longer-MD MMGBSA + alchemical FEP (12λ × 5 ns) · variant-5 site-G dock · orig Boltz top-30 · Jack full-pool Boltz (570/570) · Mark multi-seed gnina (570/570 × 10 seeds).

**Robust set** (compounds in top-10 of ≥3 of 10 sources):

| Compound | Votes | Sources |
|---|:---:|---|
| **gen_0004** (new pick #1) | 4 | orig_F · v4_MMGBSA_MD · boltz_orig · mark_multiseed |
| **Z795991852_analog_0087** ★ | 4 | orig_F · v4_MMGBSA_MD · boltz_orig · mark_multiseed |
| **gen_0007** ★ | 3 | orig_F · v4_MMGBSA_MD · boltz_orig |
| Z795991852_analog_0011 | 3 | orig_F · v4_MMGBSA_MD · mark_multiseed |
| Z795991852_analog_0001 | 3 | orig_F · v4_MMGBSA_MD · boltz_orig |
| FM001452_analog_0130 | 3 | orig_F · v5_siteG · boltz_orig |

★ = current pick. **gen_0025 appears in 0 of 10 variant top-10s** → triggered the swap to gen_0004.

---

## onepot.ai catalog cross-validation

Queried the onepot.ai web UI on **75 compounds** (4 final picks incl. post-swap gen_0004 + parent + top-20 backups + variant-1 onepot-friendly REINVENT proposals + key novel BRICS).

**Result: 75/75 returned hits, 0 errors. Mean top-similarity = 70.2%.**

| Top-similarity bucket | Count |
|---|---:|
| 100% (exact catalog match) | **23 / 75** |
| 80–99% | 1 |
| 60–79% | 19 |
| 40–59% | 31 |
| < 40% | 1 |

**Key validation finding: 19 of the 20 variant-1 onepot-friendly REINVENT proposals match the catalog at 100%.** That is independent confirmation our 7-reaction local enumeration is consistent with the actual onepot library — the synthesis-tractability heuristic we used reflects catalog reality. The 4 final picks return 41–86% top-similarity (parent at 78%) — same band as the validated reference scaffold.

---

## Honest expectations

- Public methods over-predict TBXT affinity by **6–25×** at the µM regime (validated on 6 reference compounds)
- HDB-vs-CF Labs SPR reproducibility is **3–10× spread** at µM Kd
- Realistic SPR outcome: **1–2 picks bind in 20–60 µM range** — competitive with disclosed compounds
- 1 µM tier (experimental prize) requires further optimization rounds; this submission is for the **judging prize**
- **gen_0007 is genuinely novel** (42% top onepot.ai similarity, lowest of picks) — supported by best alchemical FEP (-3.97 kcal/mol) and triple convergence; the catalog *confirms* it is far from any known molecule
- **T-0 swap rationale:** gen_0025 → gen_0004 fixes the only sulfonamide synthesis liability in our final 4 — same chemotype, strictly better convergence, all picks now onepot-CORE reachable

We've prioritized **rationale and judgment over raw affinity claims**.

---

## Reproducibility

- **GitHub:** `git@github.com:anandsahuofficial/Hackathon.git` branch `TBXT`
- **HF dataset bundles:** `anandsahuofficial/tbxt-hackathon-bundles` (env + data + 570 docked poses + checksums)
- Single-command setup for any teammate: `bash TBXT/setup_hf.sh`
- Top-100 ranked CSV + final-4 picks CSV (v2) + per-pick rationale + CONVERGENCE_AUDIT.md all in `TBXT/report/`
- T-0 snapshot frozen under `data/snapshots/post-prod/`

Pipeline scripts (`experiment_scripts/task1.sh` … `task10.sh`) are checkpointable and resumable; any team member can rerun any single signal independently. 5 variants ran overnight on HPC (variant1–5) + Jack's full-pool Boltz + Mark's 10-seed gnina; all surfaced in `report/CONVERGENCE_AUDIT.md`.

---

## Q&A

Anything else?
