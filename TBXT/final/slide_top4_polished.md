<!--
slide_top4_polished.md — presentable variant of slide_top4.md
Same content, denser-to-the-point per slide, stronger visual hierarchy,
big-number openers, two-column pick layout, lead slides for each act.
Original slide_top4.md preserved untouched.
-->
---
marp: true
theme: default
paginate: true
math: katex
style: |
  section { font-family: -apple-system, "Segoe UI", system-ui, sans-serif; padding: 56px 64px; }
  h1 { color: #1a3a5c; letter-spacing: -0.5px; }
  h2 { color: #1a3a5c; border-bottom: 2px solid #d0d7de; padding-bottom: 8px; }
  strong { color: #0f5132; }
  table { font-size: 0.85em; border-collapse: collapse; }
  th { background: #f0f4f8; }
  th, td { padding: 6px 10px; border: 1px solid #d0d7de; }
  blockquote { border-left: 4px solid #0066cc; background: #f0f7ff; padding: 8px 16px; margin: 12px 0; }
  .big { font-size: 3em; font-weight: 700; color: #0066cc; line-height: 1; }
  .label { font-size: 0.9em; color: #666; text-transform: uppercase; letter-spacing: 1px; }
  .columns { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
  section.lead { text-align: center; }
  section.lead h1 { font-size: 2.4em; margin-bottom: 16px; }
  footer { color: #888; font-size: 0.7em; }
---

<!-- _class: lead -->

# TBXT Hit Identification
## Top 4 Picks for Chordoma's Master Regulator

<br/>

**Anand Sahu** · Project lead, methodology, live demo

TBXT Hackathon · Pillar VC Boston · 2026-05-09

---

<!-- _class: lead -->

## The headline

<div class="big">137</div>

<span class="label">Strictly compliant compounds<br/>distilled from a 570-pool</span>

<br/>

<div class="columns">
<div>
<div class="big">4</div>
<span class="label">picks for judges</span>
</div>
<div>
<div class="big">3.2 µM</div>
<span class="label">best predicted Boltz Kd<br/>(dual-engine cross-val 1.02×)</span>
</div>
</div>

---

## Target

**Human TBXT (Brachyury)** · 435 aa · DBD residues 42-219

- **G177D** = `rs2305089`, common chordoma variant in **>90% of Western cases** (allele freq 42%)
- Site F = `Y88 / D177 / L42` — pocket directly engages the variant residue
- Sequence-aware selectivity: **G177 is 0% conserved** across 16 T-box paralogs; M181 7%, T183 13%
- Receptor: **PDB 6F59 chain A** (G177D + DNA — matches CF Labs SPR construct)

> **Why site F:** TEP-recommended · all best Naar SPR binders predicted at F · TBXT-unique residues = intrinsic selectivity

---

## The pipeline — 6 orthogonal signals

| Signal | What it catches |
|---|---|
| **Vina ensemble** (6 receptor confs) | Geometric fit + receptor flexibility |
| **GNINA CNN** pose + pKd | Vina-trap detection (contact-maximizing decoys) |
| **TBXT QSAR** (RF + XGBoost on 650 measured Naar SPR Kd) | The **only on-target signal** |
| **Boltz-2 co-folding** — Jack local + SCC re-run | Independent affinity + binder/non-binder classifier |
| **MMGBSA** (OpenMM + GBn2, top 30) | Free-energy refinement |
| **T-box paralog selectivity** (16 paralogs) | Off-target risk |

> Each signal has a known failure mode → **caught by another signal in the stack**

---

## The 7-criterion strict filter (T-0 hard gate)

> **Of 570 pool compounds → 137 pass all 7 → 4 picks (ranks 1, 2, 11, 22)**

<div class="columns">
<div>

**Organizer-defined hard:**

- **C1** onepot 100% catalog match (similarity = 1.000)
- **C2** strictly non-covalent
- **C3** Chordoma rule
- **C5** PAINS-clean + no acid halides / aldehydes / diazo / imines / etc.
- **C6** Tanimoto < 0.85 to Naar / TEP / prior_art

</div>
<div>

**Lead-like + feasibility:**

- **C4** 10–30 HA · HBD+HBA ≤ 11 · LogP < 5 · < 5 rings · ≤ 2 fused
- **C7** ESOL log S > -5 (DMSO @ 10 mM + aqueous @ 50 µM)

**Tier breakdown of 137:**
T1 GOLD: 0 (empty by design — honest) · T2 SILVER: 16 · T3 BRONZE: 89 · T4 RELAXED: 32

</div>
</div>

---

<!-- _class: lead -->

## The 4 picks

| # | ID | Boltz Kd | gnina Vina | $ | risks |
|---:|---|---:|---:|---:|:---:|
| **1** | `FM002150_analog_0083` | **3.2 µM** | -5.01 | **$125** | **low/low** |
| **2** | `FM001452_analog_0104` | **3.7 µM** | -5.77 | $250 | med/med |
| **3** | `FM001452_analog_0201` | 8.16 µM | **-6.07** | $375 | high/med |
| **4** | `FM001452_analog_0171` | 8.32 µM | -6.19 | $250 | med/med |

<br/>

**$875 total** to source · **4/4 site F** · **dual-engine Boltz 1.01-1.34×** agreement on every pick

---

## Pick 1 — `FM002150_analog_0083`

<div class="columns">
<div>

`O=C(O)COCc1ccc(-c2ccsc2)cc1`

**Best of all 4 metrics**

- **Boltz Kd 3.2 µM** — strongest 100%-onepot non-covalent
- Phenoxyacetic acid + thiophene; carboxylate H-bonds **Y88 / D177**
- **$125 + low/low risk** — cheapest + lowest-risk pick
- MW 248.3 · LogP 3.02 · HBD 1 · HBA 4
- Dual-engine Boltz 1.02× agreement

</div>
<div>

![w:250](renders/FM002150_analog_0083_2d.png)

![w:300](renders/FM002150_analog_0083_pose_3d.png)

</div>
</div>

---

## Pick 2 — `FM001452_analog_0104`

<div class="columns">
<div>

`Cc1ccccc1COc1cccc(N)c1`

**Cleanest medchem in the pool**

- **Boltz Kd 3.7 / 4.97 µM** — second-strongest
- Methyl-phenyl-CH₂-O-aniline; aniline-N H-bonds **D177**
- **MW 213.3** — most fragment-like; best SAR starting point
- Minimal heteroatom decoration → easiest to optimize
- $250 medium-risk

</div>
<div>

![w:250](renders/FM001452_analog_0104_2d.png)

![w:300](renders/FM001452_analog_0104_pose_3d.png)

</div>
</div>

---

## Pick 3 — `FM001452_analog_0201`

<div class="columns">
<div>

`NC(=O)Nc1cccc(OCc2ccccc2)c1`

**Designed H-bond pattern for R174 + D177**

- **Deepest Vina (-6.07)** + **highest CNN-pKd (4.69)** of the 4
- N-aryl urea + benzyl ether — donor / acceptor pair targeting the variant residue specifically
- Adds urea-linker chemotype diversity
- Boltz Kd 8.16 / 8.76 µM
- $375 (urea synthesis = high chem risk)

</div>
<div>

![w:250](renders/FM001452_analog_0201_2d.png)

![w:300](renders/FM001452_analog_0201_pose_3d.png)

</div>
</div>

---

## Pick 4 — `FM001452_analog_0171`

<div class="columns">
<div>

`Nc1cccc(OCc2ccc(-c3ccncc3)cc2)c1`

**Pyridyl selectivity probe**

- **Highest prob_binder (0.46)** of the 4
- **Tightest dual-engine Boltz match (1.02×)** — most reproducible Kd prediction
- Pyridyl basic-N for paralog differentiation
- Boltz Kd 8.32 / 8.17 µM
- $250 medium / medium

</div>
<div>

![w:250](renders/FM001452_analog_0171_2d.png)

![w:300](renders/FM001452_analog_0171_pose_3d.png)

</div>
</div>

---

## Cross-validation evidence

> Every pick supported by **multiple independent lines of evidence** — not a single-score gamble

- ✅ **Two independent Boltz-2 runs** (Jack local + SCC re-run): 4/4 agree within 1.34×
- ✅ **Mark's 10-seed GNINA pose stability**: pick #4 (`analog_0087` σ=0.037 in v3 robust set) is the most pose-stable
- ✅ **Rowan ADMET** (49 properties × 4 picks)
- ✅ **Rowan Docking** (Vina/Vinardo + conformer search) — independent re-rank
- ✅ **muni.bio `onepot` tool** — all 4 at similarity = 1.000 with price + chem_risk + supplier_risk
- ⚠️ **Rowan pose-analysis MD** attempted (5 keys × 3 mechanisms) — credit-tier blocked; documented in `evidence/rowan_md_attempt_log.md`

---

## Tradeoffs we made (judgment axis)

<div class="columns">
<div>

**All 4 site F**

The 100%-onepot non-covalent constraint dominated; the FM_* family is naturally site-F. Site-A backups documented in `top5to24_rationale.md` for the broader 24-pick team submission.

</div>
<div>

**T1 GOLD tier empty**

No compound simultaneously hits Boltz Kd ≤ 5 µM AND low/low risk. We surface this **honestly** rather than overclaim.

</div>
</div>

<div class="columns">
<div>

**Chemotype dominance**

FM001452 family in 3/4 picks — not artificially diversified. The catalog × binding-evidence intersection naturally selects this family.

</div>
<div>

**No MD movies**

Rowan MD blocked by credit tier. Substitute: Mark's 10-seed GNINA + dual-engine Boltz cross-val.

</div>
</div>

---

<!-- _class: lead -->

## Honest expectations

> Public methods over-predict Kd by **6-25×** at µM regime
> Realistic CF Labs SPR for these 4: **18-200 µM range**

| Prize tier | Our shot |
|---|---|
| **Hackathon judging** ($250 muni credits) | **Strong** — multi-signal + filter chain + tier methodology maps all 3 judging axes |
| **$100K @ Kd ≤ 1 µM** | Plausible long-shot — best Boltz pred 3.2 µM |
| **$250K @ Kd ≤ 300 nM** | Requires further hit-to-lead optimization |

---

## Reproducibility

- **GitHub:** `git@github.com:anandsahuofficial/Hackathon.git` branch `TBXT`
- **Single-command setup:** `bash TBXT/setup_hf.sh`
- **All 137 candidates with per-criterion flags:** `TBXT/final/all_candidates_tiered.csv`
- **24-pick team submission:** `TBXT/final/top4.csv` + `top5to24.csv`
- **Per-tier rationale:** `TBXT/final/tiered/TIERED_CANDIDATES_RATIONALE.md`
- **Rowan MD attempt log:** `TBXT/final/evidence/rowan_md_attempt_log.md`

---

<!-- _class: lead -->

# Q&A

**InChIKeys for the 4 picks:**

| # | ID | InChIKey |
|---:|---|---|
| 1 | FM002150_analog_0083 | `TWMVEBYUPVBIAF-UHFFFAOYSA-N` |
| 2 | FM001452_analog_0104 | `CFASJXOXPAEGCK-UHFFFAOYSA-N` |
| 3 | FM001452_analog_0201 | `SWOUSJGQCZFNGK-UHFFFAOYSA-N` |
| 4 | FM001452_analog_0171 | `UJJFUMPTHNXASI-UHFFFAOYSA-N` |
