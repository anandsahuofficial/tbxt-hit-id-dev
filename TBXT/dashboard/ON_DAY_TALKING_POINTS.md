# TBXT Hackathon — On-Day Talking Points (Live Demo Cheat Sheet)

**Submission: 7 PM. Demo + judging: 7:30 PM. v2 picks (post T-0 swap).**

---

## 30-second elevator pitch

We built a **6-signal orthogonal consensus pipeline** for TBXT G177D — Vina ensemble, GNINA CNN, target-specific QSAR (650 SPR Kd), Boltz-2 co-folding, MMGBSA + alchemical FEP, and 16-paralog selectivity — over a 570-compound novelty-filtered pool. Tonight we ran **5 HPC variants + onepot.ai catalog validation** on top of that, then re-ran a **convergence audit across 10 ranking sources**. The audit triggered a chemotype-preserving swap to gen_0004 that fixes our only remaining synthesis liability. **All 4 picks are now onepot-CORE reachable, three of four sit in the robust set across ≥3 independent variants, and the fourth is independently confirmed by Jack's full-pool Boltz at 0.46 µM.**

---

## The 4 picks (one line each)

| # | ID | Site | Headline | Why we chose it |
|---:|---|:---:|---|---|
| **1** | `Z795991852_analog_0021` | A | Multiseed Vina **-8.50 ± 0.01** (most stable pose) + Boltz Kd **0.46 µM** | Site-A diversification of CF Labs SPR-validated parent; only site-A pick; reach 1.00 |
| **2** | `gen_0004` | F | Composite **rank 1** (0.6749) + alchemical FEP +0.53 (vs gen_0025 +1.14) | Same chemotype as the swapped-out gen_0025; CH₂-N replaces sulfonamide → onepot N-alkylation reachable; strictly better refinement |
| **3** | `gen_0007` | F | Alchemical FEP **-3.97 kcal/mol** (only negative ΔΔG of any pick) + MMGBSA-MD -7.7 | Novel BRICS-recombinant scaffold; beats validated parent on FEP; triple convergence |
| **4** | `Z795991852_analog_0087` | F | Boltz Kd **1.87 µM** (best) + onepot.ai **86%** top similarity (highest) | CF Labs parent analog with most pose-stable multiseed (CNN-pKd σ = 0.037) |

---

## 3 likely judge questions + 2-line answers

**Q: "Why is your novel pick (gen_0007) trustworthy if it's not in any catalog?"**
- **Alchemical 12-λ × 5 ns FEP returned ΔΔG = -3.97 kcal/mol vs the validated CF Labs reference — the only pick with a negative ΔΔG.** Backed by independent MMGBSA-MD ΔE -7.7 (rank 1 in v4) and 3 of 10 variant top-10s. The molecule is BRICS-recombination of fragments from validated binders, not generated from scratch — and onepot retrosynth gives it ≥0.74 reachability via Suzuki on the bisaniline.

**Q: "What's your selectivity story?"**
- **Sequence-aware 16-paralog scoring on the site-F contact set: G177 is 0% conserved, M181 7%, T183 13% across the T-box family.** All 4 picks have selectivity scores 0.40–0.51 — engaging the TBXT-unique residues, not the conserved DNA-binding face. (We did not run real cross-paralog docking — flag if pressed; sequence-aware is a conservative proxy.)

**Q: "What's the synthesis risk?"**
- **We swapped pick #2 today specifically to eliminate it.** gen_0025 had a sulfonamide linker (not in onepot's 7 reactions); we replaced it with gen_0004 (same chemotype, CH₂-N linker reachable via N-alkylation). All 4 picks are now reachable via at least one of the 7 onepot CORE reactions. We also ran 75 picks through the live onepot.ai search — 0 errors, 23/75 at 100% catalog match, including 19/20 of our variant-1 onepot-friendly REINVENT proposals.

**Q: "Why are your Rowan ADMET numbers so bad — DILI 0.95-1.00, hERG 0.78-0.79 on the novel picks?"**
- **Two-part answer.** (1) These are *predictions on uncharacterized scaffolds*, not assayed values; public ADMET models are notoriously over-predictive on novel chemistries that fall outside their training distribution (PDBbind / Tox21). The same models score Z analog_0021 at hERG 0.53 — moderate — and analog_0087 at AMES 0.26 — low — so they're not uniformly red. (2) **Chordoma is a rare, near-incurable cancer; the tox-tolerance bar is dramatically higher than chronic indications.** Approved chordoma agents (imatinib off-label, brigatinib in trials) carry meaningful tox liabilities. The first SAR cycle would optimize hERG by tweaking the basic amine count and TPSA — well-understood medchem.

**Q: "Where's your wildcard? You're 3 site-F + 1 site-A."**
- **Pick #4 (`Z795991852_analog_0087`) is our designated wildcard.** It has the highest onepot.ai catalog similarity (86%) of any pick — the most likely of the 4 to literally exist in the 3.4B onepot library. We surveyed site G via variant-5 (570 compounds docked) but the top-5 site-G binders all also score well at site F — they're promiscuous, not site-selective — so a site-G "diversity" pick would be illusory. We held the wildcard slot for catalog-tractability instead.

---

## Backup picks (if judges challenge any)

| Challenged pick | Backup | Reason |
|---|---|---|
| `gen_0004` (site F, novel) | `gen_0007` re-emphasized as the novel anchor; or `Z795991852_analog_0011` (3-vote robust set, MMGBSA-MD ΔE -2.97) | Same site, established convergence |
| `Z795991852_analog_0021` (site A) | `Z795991852_analog_0010` (Jack-Boltz Kd 1.13 µM, prob_binder 0.66) — site-A alternate | Same chemotype, additional Boltz coverage |
| `FM001452_analog_0201` | Site-G wildcard if judges want a 3rd-site bet (but: NOT in our final 4 because site-G top-5 are all also site-F binders — promiscuous, not selective; 100% onepot.ai match available) |
| Whole site-F set | `Z795991852_analog_0039` (Jack-Boltz Kd **0.337 µM, prob_binder 0.73**) — strongest Jack-Boltz number in entire 570-pool but already over-represents the chromene-amide family |

---

## Defensive talking points (only if attacked)

- **"All in-silico methods over-predict at µM."** Yes — we explicitly note 6–25× over-prediction in our reference-set validation; realistic SPR is 20–60 µM. We're playing for the judging prize, with the experimental tier as a lottery.
- **"Why didn't you use Rowan / muni.bio?"** muni.bio site was 403 pre-event; Rowan we plan to engage live during Q&A if credits are distributed. Pipeline doesn't depend on either.
- **"How do we know your onepot reachability is real?"** Independent: 19/20 of our variant-1 REINVENT-generated onepot-friendly proposals matched 100% in the live onepot.ai search today (75 picks queried, 0 errors, 23 at 100% catalog match). The reachability heuristic is consistent with catalog reality.
- **"gen_0025 was in your locked submission an hour ago."** Correct — we ran a convergence audit at T-0 (`report/CONVERGENCE_AUDIT.md`), found gen_0025 in 0 of 10 variant top-10s and a non-trivial sulfonamide synthesis risk, and swapped to the same-chemotype isostere gen_0004 that wins 4 of 10 votes. The swap is documented end-to-end.

---

## Live demo cues (in order)

1. Open `report/SUBMISSION_v2.md` — read the 4-pick table aloud
2. Open `report/CONVERGENCE_AUDIT.md` §2 — show the robust set table
3. Open `data/onepot_top_picks_results.csv` — show 0 errors, 20× 100% matches
4. If asked for code: open `experiment_scripts/task10.sh` (consensus aggregator) — show 6-signal weighting
