---
marp: true
theme: default
paginate: true
---

# TBXT Hit Identification

**Multi-signal consensus pipeline for chordoma's master regulator**

Anand Sahu — TBXT Hackathon, Pillar VC Boston, May 9, 2026

*Project lead, methodology, and live demo: Anand Sahu.*

Target: TBXT G177D (Brachyury) · PDB 6F59 chain A · Site F (Y88 / D177 / L42)

> v3 deck: all 4 picks swapped to satisfy organizer T-0 hard constraints (100% onepot exact match, non-covalent, Tanimoto < 0.85 to organizer DBs).

---

## What we built

**570-compound novelty-filtered pool**, scored on **6 orthogonal signals**:

| Signal | What it catches |
|---|---|
| **Vina ensemble** (6 receptor confs) | Geometric fit; receptor flexibility |
| **GNINA CNN pose + pKd** | Vina-trap detection (contact-maximizing decoys); ML affinity |
| **TBXT QSAR** (RF + XGBoost on 650 Naar SPR Kd) | Target-specific affinity (the only on-target signal) |
| **Boltz-2 co-folding** (3 samples × 200 steps; Jack + SCC dual engine) | Independent affinity + binder/non-binder classifier |
| **MMGBSA single-snapshot** (OpenMM + GBn2) | Free-energy refinement (top 30) |
| **T-box paralog selectivity** (sequence-aware site-F contacts × 16 paralogs) | Off-target risk |

Final hard gate (T-0 organizer clarification): **100% onepot.ai exact match + strictly non-covalent + Tanimoto < 0.85 to organizer DBs.**

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

## Final 4 picks (all 100% onepot, all non-covalent, all site F)

| # | ID | Site | Boltz Kd (Jack/SCC) | prob_binder | gnina Vina | gnina pKd | onepot match | $ |
|---:|---|:---:|---:|---:|---:|---:|---:|---:|
| **1** | `FM002150_analog_0083` | F | **3.2 / 3.26 µM** | 0.30 | -5.01 | 3.94 | **1.000** | $125 |
| **2** | `FM001452_analog_0104` | F | 3.7 / 4.97 µM | 0.41 | -5.77 | 4.03 | **1.000** | $250 |
| **3** | `FM001452_analog_0201` | F | 8.16 / 8.76 µM | 0.36 | -6.07 | **4.69** | **1.000** | $375 |
| **4** | `FM001452_analog_0171` | F | 8.32 / 8.17 µM | **0.46** | **-6.19** | 4.44 | **1.000** | $250 |

- **All site F**, all from our Boltz-validated **FM_* family** already in the 570-compound pool
- **All 4 confirmed at similarity = 1.000** via the muni.bio `onepot` tool (catalog-resident, not just synthesis-reachable)
- **All 4 strictly non-covalent**; all 4 Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical

---

## Tiered candidate pool — 137 strictly compliant compounds

The 4 picks above come from a 137-compound pool that passes **every** organizer constraint. Same pool feeds the experimental program first batch (Sept 1, $100K @ Kd ≤ 1 µM / $250K @ Kd ≤ 300 nM tiers).

| Tier | Count | Definition |
|---|---:|---|
| **T1 GOLD** | 0 | Hard ✓ + lead-like ✓ + Boltz Kd ≤ 5 µM + low/low risks. **Empty — honest finding** (no compound hits all maxima simultaneously). |
| **T2 SILVER** | 16 | Hard ✓ + lead-like ✓ + soluble + Boltz Kd ≤ 10 µM. Primary submission pool. |
| **T3 BRONZE** | 89 | Hard ✓ + lead-like ✓ + Kd ≤ 50 µM, borderline aqueous solubility (DMSO @ 10 mM still OK) |
| **T4 RELAXED** | 32 | Hard ✓, lead-like graceful — still organizer-compliant |

**7-criterion filter chain:** onepot 100% match · non-covalent · Chordoma rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) · lead-like ideal · PAINS-clean + no forbidden motifs · Tanimoto < 0.85 to Naar (2274 prior compounds) · ESOL log S > -5

**Files:** `data/all_candidates_tiered.csv` (full 137 rows, every flag) + `report/TIERED_CANDIDATES_RATIONALE.md` (per-tier explanations + top-30 with per-pick why)

The 4 final picks above are T2 ranks 1, 2, 11 + T3 rank 22.

---

## Pick 1: FM002150_analog_0083 — strongest 100%-onepot non-covalent

**SMILES:** `O=C(O)COCc1ccc(-c2ccsc2)cc1`

Strongest predicted Boltz Kd (3.2 µM) of any 100%-onepot non-covalent candidate; SCC and Jack Boltz cross-validate at 1.02× agreement. Phenoxyacetic acid + thiophene scaffold is a well-precedented carboxylate medchem chemotype, low chemistry risk per onepot, $125 price. The carboxylate offers an H-bond donor handle for Y88 / D177 engagement.

**Site F scores:** Boltz Kd Jack 3.2 µM / SCC 3.26 µM, prob_binder 0.30, gnina Vina -5.01, gnina CNN-pKd 3.94, MW 248.3, logP 3.02
**Onepot catalog:** similarity 1.000 (exact match) · price $125 · chemistry_risk low · supplier_risk low

![w:280](data/task9/trial1/renders/FM002150_analog_0083_2d.png) ![w:280](data/task9/trial1/renders/FM002150_analog_0083_pose_3d.png)

---

## Pick 2: FM001452_analog_0104 — cleanest medchem, second-strongest

**SMILES:** `Cc1ccccc1COc1cccc(N)c1`

Boltz Kd 3.7 µM (Jack) / 4.97 µM (SCC) — second-strongest 100%-onepot non-covalent binder. Methyl-phenyl-CH2-O-aniline scaffold; cleanest medchem in the pool (no heteroatoms beyond anilino N + ether O). Onepot catalog confirmed at exact match; low synthesis risk; $250.

**Site F scores:** Boltz Kd Jack 3.7 µM / SCC 4.97 µM, prob_binder 0.41, gnina Vina -5.77, gnina CNN-pKd 4.03, MW 213.3, logP 3.16
**Onepot catalog:** similarity 1.000 (exact match) · price $250 · chemistry_risk medium · supplier_risk medium

![w:280](data/task9/trial1/renders/FM001452_analog_0104_2d.png) ![w:280](data/task9/trial1/renders/FM001452_analog_0104_pose_3d.png)

---

## Pick 3: FM001452_analog_0201 — urea + benzyl ether for R174 / D177

**SMILES:** `NC(=O)Nc1cccc(OCc2ccccc2)c1`

Boltz Kd 8.16 µM (Jack) / 8.76 µM (SCC). N-aryl urea + benzyl ether — recognized H-bond-donor / acceptor pair for site-F R174 + D177 engagement. Onepot exact match; high chemistry risk per onepot scoring (likely the urea synthesis); $375.

**Site F scores:** Boltz Kd Jack 8.16 µM / SCC 8.76 µM, prob_binder 0.36, gnina Vina -6.07, gnina CNN-pKd 4.69, MW 242.3, logP 2.76
**Onepot catalog:** similarity 1.000 (exact match) · price $375 · chemistry_risk high · supplier_risk medium

![w:280](data/task9/trial1/renders/FM001452_analog_0201_2d.png) ![w:280](data/task9/trial1/renders/FM001452_analog_0201_pose_3d.png)

---

## Pick 4: FM001452_analog_0171 — pyridyl selectivity probe

**SMILES:** `Nc1cccc(OCc2ccc(-c3ccncc3)cc2)c1`

Boltz Kd 8.32 µM (Jack) / 8.17 µM (SCC). Pyridyl-benzyl-ether-aniline. Pyridyl introduces basic N for selectivity probing; benzyl ether is the conserved scaffold across this FM family. Medium chemistry + supplier risk; $250.

**Site F scores:** Boltz Kd Jack 8.32 µM / SCC 8.17 µM, prob_binder 0.46, gnina Vina -6.19, gnina CNN-pKd 4.44, MW 276.3, logP 3.91
**Onepot catalog:** similarity 1.000 (exact match) · price $250 · chemistry_risk medium · supplier_risk medium

![w:280](data/task9/trial1/renders/FM001452_analog_0171_2d.png) ![w:280](data/task9/trial1/renders/FM001452_analog_0171_pose_3d.png)

---

## T-0 Convergence Audit — 5 variants + onepot.ai (post-swap)

10 independent ranking sources aggregated tonight: orig site-F · variant-1 onepot-friendly REINVENT gen · variant-3 receptor-ensemble (4 receptors LOCAL + SCC) · variant-4 longer-MD MMGBSA + alchemical FEP (12λ × 5 ns) · variant-5 site-G dock · orig Boltz top-30 · Jack full-pool Boltz (570/570) · Mark multi-seed gnina (570/570 × 10 seeds) · **SCC Boltz re-run (dual-engine cross-validation)**.

**Dual-engine Boltz cross-validation on the 4 v3 picks:**

| Pick | Jack Boltz Kd | SCC Boltz Kd | Agreement |
|---|---:|---:|---:|
| FM002150_analog_0083 | 3.20 µM | 3.26 µM | 1.02× |
| FM001452_analog_0104 | 3.70 µM | 4.97 µM | 1.34× |
| FM001452_analog_0201 | 8.16 µM | 8.76 µM | 1.07× |
| FM001452_analog_0171 | 8.32 µM | 8.17 µM | 1.02× |

The FM_* family was already in the v2 robust set (FM001452_analog_0130, 3 votes); the 100%-onepot non-covalent filter narrowed it to these 4.

---

## onepot.ai catalog cross-validation (post-swap)

Queried the **muni.bio `onepot` tool** (organizer-recommended interface; exposes `similarity`, `price`, `chemistry_risk`, `supplier_risk` per hit) on **178 compounds** (v3 picks + v2 picks + parent + top-100 backups + FM_* family + variant-1 REINVENT proposals + key BRICS).

| Bucket | Count |
|---|---:|
| **100% similarity (exact catalog match)** | **25 / 178** |
| of those, **strictly non-covalent** | **18** |
| of those 18, **our final 4 picks** | 4 |

**The T-0 swap was triggered by this validation.** Previous v2 picks topped out at 86% onepot similarity (gen_0007 at 42%, gen_0004 at 53%, analog_0021 at 41%, analog_0087 at 86%) — synthesis-reachable, but not catalog-resident under the strict 100% interpretation. All 4 v3 picks now sit in the 18-compound non-covalent 100% subset with full `price` / `chemistry_risk` / `supplier_risk` metadata.

---

## Why this approach wins

- **Multi-signal consensus** addresses each method's known failure mode (Vina-trap, PDBbind bias, rigid-receptor blindness, off-target).
- **TBXT-specific QSAR** (Spearman ρ = 0.49 on 650 measured Kd) is the only on-target signal.
- **Selectivity is structural-data-derived** at G177/M181/T183 (site F is intrinsically TBXT-selective).
- **Final picks satisfy all 3 organizer hard constraints** (100% onepot exact match, non-covalent, Tanimoto < 0.85 to organizer DBs) with **dual-engine Boltz cross-validation** (Jack + SCC within ~1.0–1.3× on every pick).
- **Reproducible + snapshotted** (`data/snapshots/T-0/`, SHA-256 manifest).

---

## Honest expectations

- Public methods over-predict TBXT affinity by **6–25×** at the µM regime (validated on 6 reference compounds)
- HDB-vs-CF Labs SPR reproducibility is **3–10× spread** at µM Kd
- Realistic SPR outcome: **1–2 picks bind in 20–60 µM range** — competitive with disclosed compounds
- 1 µM tier (experimental prize) requires further optimization rounds; this submission is for the **judging prize**
- **All 4 picks are at site F** — we lost the site-A coverage from the swapped-out `Z795991852_analog_0021` because the 100%-onepot non-covalent constraint dominated final selection. Site-A backup `Z795991852_analog_0048` (Boltz 0.65 µM, non-covalent) is documented in `TEAM_PICKS_GUIDE.md` if challenged.
- **T-0 swap rationale:** v2 picks were synthesis-reachable but not catalog-resident at 100% similarity; v3 picks are all literal catalog molecules per the muni.bio onepot tool.

We've prioritized **rationale and judgment over raw affinity claims**.

---

## Reproducibility

- **GitHub:** `git@github.com:anandsahuofficial/Hackathon.git` branch `TBXT`
- **HF dataset bundles:** `anandsahuofficial/tbxt-hackathon-bundles` (env + data + 570 docked poses + checksums)
- Single-command setup for any teammate: `bash TBXT/setup_hf.sh`
- Top-100 ranked CSV + final-4 picks CSV (v3) + per-pick rationale + CONVERGENCE_AUDIT.md all in `TBXT/report/`
- T-0 snapshot frozen under `data/snapshots/post-prod/`

Pipeline scripts (`experiment_scripts/task1.sh` … `task10.sh`) are checkpointable and resumable; any team member can rerun any single signal independently. 5 variants ran overnight on HPC (variant1–5) + Jack's full-pool Boltz + Mark's 10-seed gnina + SCC Boltz dual-engine re-run; all surfaced in `report/CONVERGENCE_AUDIT.md`.

---

## Q&A

Anything else?
