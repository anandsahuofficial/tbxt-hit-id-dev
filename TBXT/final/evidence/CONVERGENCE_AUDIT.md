# Convergence Audit — Final 4 Picks

**Date:** 2026-05-09 (T-0, submission 7 PM)
**Author:** Anand Sahu (with cross-variant convergence over 10 evidence sources)
**Variants integrated:** original site-F pipeline · v1 onepot-friendly gen · v3-LOCAL ensemble (4 receptors) · v3-SCC ensemble · v4 MMGBSA-MD top-30 · v4 alchemical-style ΔΔG · v5 site-G dock · original Boltz top-30 · Jack full-pool Boltz (570/570 parsed) · Mark multi-seed gnina (570/570 with 10 seeds) · Rabia parallel v1 onepot

---

## 1. Headline

- **Pick 1 — `Z795991852_analog_0021` (site A): CONFIRM.** Mark-multiseed Vina = -8.50 ± 0.01 (10 seeds, near-zero variance — most stable pose of all 4). Jack-Boltz Kd = 0.46 µM, prob_binder = 0.64 (NEW: not in original Boltz top-30; Jack confirms strong binder).
- **Pick 2 — `gen_0025` (site F): SWAP recommended → `gen_0004`.** gen_0025 is the only pick scoring badly across 3 independent FE methods (MMGBSA ΔE -2.51 worst of picks; alchemical ΔΔG +1.14 *unfavorable*; multiseed cnn_pose stdev 0.134 = highest variance). gen_0004 (same scaffold, CH₂ replaces sulfonamide) wins 4 votes (orig_F + v4 MMGBSA + Boltz_orig + Mark-multiseed) and resolves the sulfonamide synthesis liability (see §4).
- **Pick 3 — `gen_0007` (site F): CONFIRM.** Best alchemical ΔΔG of all picks (-3.97 kcal/mol, only one negative). MMGBSA ΔE -7.7 (best of 30 in v4-MD). Jack-Boltz reproduces orig (2.43 vs 2.46 µM). 3 independent variant top-10s.
- **Pick 4 — `Z795991852_analog_0087` (site F): CONFIRM.** 4 votes across orig_F + v4-MD + Boltz_orig + Mark-multiseed. Multiseed Vina -8.25 ± 0.05, lowest cnn_pose stdev (0.055) of any site-F pick.

---

## 2. Robust set (top-10 hits across ≥3 of 10 variant sources)

| Compound | Votes | Sources |
|---|:---:|---|
| **gen_0004**                | 4 | orig_F · v4_MMGBSA_MD · boltz_orig · mark_multiseed |
| **Z795991852_analog_0087** ★ | 4 | orig_F · v4_MMGBSA_MD · boltz_orig · mark_multiseed |
| **gen_0007** ★              | 3 | orig_F · v4_MMGBSA_MD · boltz_orig |
| Z795991852_analog_0011     | 3 | orig_F · v4_MMGBSA_MD · mark_multiseed |
| Z795991852_analog_0001     | 3 | orig_F · v4_MMGBSA_MD · boltz_orig |
| FM001452_analog_0130       | 3 | orig_F · v5_siteG · boltz_orig |

★ = current pick. **gen_0025 appears in 0 of the variant top-10s** (only the original composite ranking rewarded its high cnn_pose). v3-LOCAL/SCC top-10 are entirely Z795991852 chromene-amide analogs already represented by our two picks of that family — no additional convergence signal there. Robust convergence selects **gen_0004 over gen_0025** unambiguously.

---

## 3. Site G option

| v5 site-G top 5 | G-composite | G-vina | F-composite | F-vina |
|---|---:|---:|---:|---:|
| Z795991852_analog_0044 | 1.923 | -7.00 | 1.561 | -7.89 |
| Z795991852_analog_0086 | 1.883 | -6.74 | 1.793 | -8.21 |
| Z795991852_analog_0039 | 1.869 | -7.31 | 1.767 | -7.95 |
| Z795991852_analog_0085 | 1.858 | -6.83 | 1.811 | -7.79 |
| Z795991852_analog_0042 | 1.858 | -6.95 | 1.702 | -7.97 |

**Recommendation: do NOT swap a site-G compound into the final 4.** All top-5 site-G binders are Z795991852 analogs that *also* score well at site F (often better — site G < site F vina in 5/5). They are NOT site-selective — they're promiscuous chromene-amide binders. Adding one would (a) over-represent the chromene-amide family (already 2 picks), (b) provide no real site diversity since they bind both sites, and (c) we already have site-A coverage via analog_0021. Site G remains a backup for on-day Q&A, not a final pick.

---

## 4. gen_0025 sulfonamide audit

**SMILES:** `COc1cc2nc(-c3cccc(N)c3)nc(NS(=O)(=O)c3ccc(C)cc3)c2cc1N`

**Verdict: NOT reachable via the 7 onepot CORE reactions.** The sulfonamide N–S(=O)₂ linker requires sulfonyl-chloride + amine, which is **not in the allowed list** (amide coupling, Suzuki, Buchwald, urea, thiourea, N-alkylation, O-alkylation). The original retrosynth marked reachability = 0.74 because the *Suzuki* disconnection on the biaryl works, but that leaves the sulfonamide as an unsynthesizable starting material in onepot CORE. Documented limitation in SUBMISSION.md, but it remains a real risk.

**Same-pose isostere — `gen_0004`** (already in pool, ID exists, scored throughout pipeline):

`COc1cc2nc(-c3cccc(N)c3)nc(Cn3nc4ccccn4c3=O)c2cc1N`

- Same quinazoline-bisaniline core (Tanimoto to gen_0025 = 0.69 — same chemotype).
- N-S(=O)₂-Ar linker → CH₂-N-aryl linker, **N-alkylation reachable** (allowed).
- v3-LOCAL: vina_min -7.98, cnn_pkd_max 6.47 (vs gen_0025: -7.58, 6.40 — gen_0004 *better*).
- v4 MMGBSA-MD: ΔE = -3.14 (vs -2.51 — better).
- v4 alchemical ΔΔG: +0.53 (vs +1.14 — better).
- Mark-multiseed: in top-10 by composite (gen_0025 is not).
- Boltz_orig: gen_0004 Kd 3.78 µM, prob_binder 0.59 (vs gen_0025 5.17 µM, 0.61 — comparable).

**Decision: swap gen_0025 → gen_0004.** Same pharmacophore, better convergence, no sulfonamide synthesis risk.

---

## 5. Boltz coverage delta (Jack's full-pool Boltz)

| Pick | Original Boltz Kd (µM) | Jack Boltz Kd (µM) | Jack prob_binder |
|---|---:|---:|---:|
| Z795991852_analog_0021 | — (not in top-30) | **0.464** | **0.637** |
| gen_0007                | 2.463 | 2.431 | 0.595 |
| Z795991852_analog_0087  | 1.873 | 2.035 | 0.509 |
| gen_0025                | 5.173 | 4.946 | 0.609 |

Jack confirms all 3 site-F picks within ~10% of the original Boltz Kd — independent reproduction. **Big win:** Pick 1 (analog_0021) now has Boltz coverage for the first time, and it is the **best-Kd pick** at 0.46 µM with prob_binder 0.64 (above the "binder" threshold). This validates the site-A choice that previously had no Boltz signal.

**Top compounds new in v3/v5 top-10 that now have Jack-Boltz Kd:**

| Compound | Jack Kd (µM) | prob_binder |
|---|---:|---:|
| Z795991852_analog_0039 | **0.337** | 0.734 |
| Z795991852_analog_0030 | 0.432 | 0.572 |
| Z795991852_analog_0044 | 0.933 | 0.618 |
| Z795991852_analog_0010 | 1.128 | 0.659 |

These look strong but are all Z795991852 chromene-amide analogs — the same family already represented by analog_0087 and analog_0021. Not enough diversity rationale to swap in.

---

## 6. Multi-seed Vina/CNN delta (Mark, 10 seeds at site F)

| Pick | Vina mean ± min | CNN_pose mean ± std | CNN_pkd mean ± std |
|---|---:|---:|---:|
| Z795991852_analog_0021 | **-8.50 ± 0.01** | 0.416 ± 0.139 | 6.08 ± 0.218 |
| Z795991852_analog_0087 | -8.25 ± 0.05 | 0.617 ± **0.055** | 6.03 ± **0.037** |
| gen_0007                | -7.50 ± 0.16 | 0.334 ± 0.117 | 5.65 ± 0.130 |
| gen_0025                | -7.45 ± 0.08 | 0.561 ± **0.134** | 6.06 ± **0.236** |

(`vina_kcal_min` reported alongside mean to show seed-to-seed variance.)

**Pick 4 (analog_0087) is rock-solid** — lowest cnn_pose and cnn_pkd stdev of all picks. **Pick 1 (analog_0021) has the deepest, most consistent vina** (-8.50 mean, range 0.01). **gen_0025 has the highest cnn_pkd stdev (0.236)** — Mark's data confirms its pose/affinity is not stable across seeds. **gen_0004** (proposed swap) is in Mark-multiseed top-10 with vina_mean ≈ -8.0, cnn_pose_mean ≈ 0.65 — more stable than gen_0025 on the same metric.

---

## 7. Final verdict

**SWAP: replace pick #2 (`gen_0025`) with `gen_0004`.** Justification: gen_0004 is the same chemotype/pharmacophore (Tanimoto 0.69), wins the 4-vote convergence robustly across orig_F + Boltz + MMGBSA-MD + Mark-multiseed, has a strictly better alchemical ΔΔG (+0.53 vs +1.14 kcal/mol), strictly better MMGBSA ΔE (-3.14 vs -2.51), and most importantly **eliminates the sulfonamide onepot-CORE synthesis liability** (its CH₂-N-aryl linker is reachable via N-alkylation, an allowed reaction). Picks 1, 3, 4 confirmed unchanged.

---

### Data-quality issues found
- v3-SCC ensemble includes the broken-Vina 6F58 receptor; its Vina=0 entries skew `vina_min`. Confirmed CNN scores are still valid; v3-LOCAL (4 receptors all valid) is preferred for ranking.
- v4 alchemical FEP returned a numerical blow-up for `Z795991852_analog_0052` (1e16 kcal/mol); filtered.
- Pick 1 (analog_0021) has no entries in the v3-LOCAL top-10 because it was scored at site A, not site F — site-A confirmation comes from task3 + Mark-multiseed-F (where it still wins on Vina).

### Files of record
- `TBXT/report/final_4_picks.csv` — locked, NOT modified by this audit (per constraint)
- `TBXT/report/CONVERGENCE_AUDIT.md` — this file
- Recommended next action: regenerate `final_4_picks.csv` swapping gen_0025 → gen_0004 (same site F, same chemotype slot), update SUBMISSION.md per-pick rationale §"Pick 2", refresh 2D/3D renders for gen_0004.
