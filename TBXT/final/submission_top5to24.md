# TBXT Hackathon — Submission (additional 20 picks; experimental program first batch)

**Project lead:** Anand Sahu · **Date:** 2026-05-09

This file documents the **20 additional team submissions** (ranks 5-24)
beyond the 4 picks presented to judges (`submission_top4.md`).
Together = **24-compound team submission** ready for the experimental
prize program first batch (Sept 1).

## Picks 5-24 (one-line each)

```
FM002150_analog_0082	O=C(O)c1cc(-c2ccsc2)ccc1OCC(=O)O
FM001452_analog_0040	[ranks 5-24 — see top5to24.csv for SMILES]
FM001452_analog_0009
FM001452_analog_0008
FM001452_analog_0005
FM001452_analog_0004
FM001452_analog_0020
FM002150_analog_0080
FM002150_analog_0053
FM002150_analog_0056
FM001452_analog_0155
FM001452_analog_0162
FM001452_analog_0001
FM001452_analog_0030
opv1_000076
FM001452_analog_0032
FM001452_analog_0029
FM001452_analog_0059
FM002150_analog_0027
FM001452_analog_0015
```

(Full SMILES + all per-criterion data: `top5to24.csv`)

## Selection rule

These are ranks 5-24 of the 137-compound tiered candidate pool, sorted
strict-first (T2 SILVER → T3 BRONZE) then by Boltz Kd ascending. All
20 pass the **same 7-criterion filter chain** as the top 4:

C1 onepot 100% catalog match (similarity = 1.000) ·
C2 strictly non-covalent ·
C3 Chordoma chemistry rule (MW ≤ 600, LogP ≤ 6, HBD ≤ 6, HBA ≤ 12) ·
C4 lead-like ideal (10–30 HA, HBD+HBA ≤ 11, LogP < 5, < 5 rings, ≤ 2 fused) ·
C5 PAINS-clean + no acid halides / aldehydes / diazo / imines / polycyclic > 2 fused / long alkyl ·
C6 Tanimoto < 0.85 to Naar SPR / TEP fragments / prior_art_canonical ·
C7 predicted soluble (ESOL log S > -5 for T2 SILVER; T3 BRONZE borderline — DMSO @ 10 mM still works)

## Tier breakdown

| Tier | Count in this 20 | Definition |
|---|---:|---|
| T2 SILVER | 13 (ranks 5-17) | Hard ✓ + lead-like ✓ + soluble + Boltz Kd ≤ 10 µM |
| T3 BRONZE | 7 (ranks 18-24) | Hard ✓ + lead-like ✓ + Kd ≤ 50 µM, borderline aqueous solubility |

## Why these 20 specifically

**Chemotype mix:** 14 FM001452 + 5 FM002150 + 1 opv1. FM002150 family
provides the second-most-represented scaffold (after FM001452) — adds
intra-set diversity for the experimental program SAR.

**Cost diversity:** 6 picks at $125 (cheapest tier) — useful for
cost-bounded experimental program submissions.

**Risk profile:** 5 picks at low/low chemistry+supplier risk; 4 at
high-chemistry-risk (urea-derived FM001452 variants — flagged in
top5to24.csv `muni_chem_risk` column).

## Submission instructions

1. **Hackathon-day submission (today, 7 PM):** the 4 top picks via
   `submission_top4.md` — judges-facing.
2. **Experimental program first batch (Sept 1 deadline):** these 20 via
   the experimental program's submission portal at
   `https://tbxtchallenge.org/?utm_source=luma#prizes`. CFF-format
   compound entries can be generated from `top5to24.csv`. The portal
   accepts up to 96 compounds across 3 batches per team — these 20
   would consume ~21% of that budget. Optionally extend with ranks 25+
   from `all_candidates_tiered.csv` (113 more candidates available).

## Honest expectations (same as top 4)

- Realistic SPR Kd: 28-265 µM range (Boltz over-predicts 6-25×).
- ~1-3 of the 24 may land below 5 µM at SPR — lottery odds.
- 1 µM tier ($100K) is a plausible long-shot for the strongest 4-5
  picks across the 24.
- 300 nM tier ($250K) requires SAR follow-up; not expected from a
  single screen.

For deeper context (per-pick rationale + chemotype family analysis +
tier definitions), see:
- `top5to24_rationale.md` (this set's per-pick context)
- `tiered/TIERED_CANDIDATES_RATIONALE.md` (all 137 candidates + 7-criterion filter chain explanation)
