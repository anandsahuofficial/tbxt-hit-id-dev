# Pick Swap Decision Memo — Team Lead Action Required

**Date:** 2026-05-09 (T-0, submission 7 PM) · **Author:** Anand Sahu (T-0 audit)
**Decision:** swap pick #2 — `gen_0025` → `gen_0004` (same chemotype, site F).

## Why the swap

`gen_0025` is the only locked pick that scores badly across **3 independent free-energy methods** AND has a **synthesis liability**:
1. Sulfonamide `N-S(=O)₂-Ar` linker is NOT in the 7 onepot CORE reactions.
2. 0 of 10 variant top-10s — only the original composite ranking surfaced it.
3. Worst MMGBSA-MD ΔE (-2.51), unfavorable alchemical FEP ΔΔG (+1.14), highest CNN-pKd seed-stdev (0.236) of any pick.

`gen_0004` is the **same-pose isostere** (Tanimoto 0.69; same quinazoline-bisaniline core; same site-F engagement; same novel-scaffold rationale) that wins on every comparable signal:
- MMGBSA-MD ΔE = **-3.14** vs -2.51; alchemical FEP ΔΔG = **+0.53** vs +1.14
- composite = **0.6749** vs 0.6451 (gen_0004 is **rank 1** in `top_100_consensus.csv`)
- 4 votes in robust set (orig_F + v4_MMGBSA_MD + Boltz_orig + Mark_multiseed)
- onepot.ai catalog: 53% top similarity vs gen_0025 47% (closer to a real molecule)
- linker is `CH₂-N-aryl` → onepot **N-alkylation reachable** (allowed reaction)

Full evidence: `report/CONVERGENCE_AUDIT.md` §4.

## What changes

CSV row in final_4_picks.csv (rank 2 → gen_0004); SMILES copy-paste in SUBMISSION; per-pick rationale § Pick 2; pick-2 slide in SLIDES.

## What does NOT change

Chemotype slot (1 novel-BRICS at site F + gen_0007 still); site coverage (3F + 1A); scoring philosophy (6-signal consensus + diversity rules); picks #1, #3, #4 (all confirmed).

---

**Action required from team lead:** rename `SUBMISSION_v2.md` → `SUBMISSION.md` and `final_4_picks_v2.csv` → `final_4_picks.csv` to apply, OR ignore these v2 files to keep the locked picks.
