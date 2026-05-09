---
marp: true
theme: default
paginate: true
---

# TBXT — Top 5-24 (additional 20 picks)

**Experimental program first batch** (Sept 1 deadline)

Anand Sahu — TBXT Hackathon, 2026-05-09

These 20 compounds + the top 4 (`slide_top4.md`) = **24-compound team submission**

---

## Why these 20

- All 20 pass the **same 7-criterion filter chain** as top 4
- Ranks 5-24 of the 137-candidate tiered pool
- Sorted: tier first (T2 SILVER → T3 BRONZE) then Boltz Kd ascending
- Chemotype mix: 14 FM001452 + 5 FM002150 + 1 opv1

---

## T2 SILVER picks (ranks 5-17, 13 compounds)

All pass hard ✓ + lead-like ✓ + soluble + Boltz Kd ≤ 10 µM

| Rank | ID | Boltz Kd µM | $ | risks |
|---:|---|---:|---:|:---:|
| 5 | `FM002150_analog_0082` | 4.74 | $250 | med/low |
| 6 | `FM001452_analog_0040` | 5.87 / 5.65 | $1000 | low/high |
| 7 | `FM001452_analog_0009` | 6.25 / 7.72 | $375 | high/med |
| 8 | `FM001452_analog_0008` | 6.32 / 6.99 | $375 | high/med |
| 9 | `FM001452_analog_0005` | 6.76 / 8.08 | $250 | med/low |
| 10 | `FM001452_analog_0004` | 7.00 / 6.99 | $250 | med/med |
| **11** | `FM001452_analog_0020` | **7.00** | **$125** | **low/low** |
| 12 | `FM002150_analog_0080` | 7.64 | $250 | med/low |

---

## T2 SILVER picks (continued, ranks 13-17)

| Rank | ID | Boltz Kd µM | $ | risks |
|---:|---|---:|---:|:---:|
| 13 | `FM002150_analog_0053` | 8.20 | $590 | med/med |
| 14 | `FM002150_analog_0056` | 8.34 | $885 | high/med |
| **15** | `FM001452_analog_0155` | **8.47 / 8.45** | **$125** | **low/low** |
| 16 | `FM001452_analog_0162` | 9.51 / 8.77 | $125 | low/med |
| 17 | `FM001452_analog_0001` | 9.30 / 9.91 | $295 | low/med |

**Bold picks** = best of class on $-and-risk dimension.

---

## T3 BRONZE picks (ranks 18-24, 7 compounds)

All pass hard + lead-like + Kd ≤ 50 µM, borderline aqueous solubility (DMSO @ 10 mM still works).

| Rank | ID | Boltz Kd µM | $ | risks |
|---:|---|---:|---:|:---:|
| **18** | `FM001452_analog_0030` | **5.97 / 5.86** | $540 | **low/low** |
| 19 | `opv1_000076` | (gnina 6.32) | $375 | high/low |
| 20 | `FM001452_analog_0032` | 6.34 / 6.48 | $590 | med/low |
| 21 | `FM001452_analog_0029` | 7.46 / 7.53 | $295 | low/low |
| 22 | `FM001452_analog_0059` | 7.86 / 7.60 | $590 | med/low |
| 23 | `FM002150_analog_0027` | 10.34 | $885 | high/med |
| 24 | `FM001452_analog_0015` | 10.25 / 11.56 | $1000 | low/high |

**Pick #18** is in T3 only because of solubility; its Boltz Kd is stronger than several T2 picks.

---

## Submission strategy

| Submission | Where | When | What |
|---|---|---|---|
| Hackathon judging | Live demo at Pillar VC | Today 7 PM | Top 4 (`top4.csv`) |
| Experimental program first batch | tbxtchallenge.org portal | Sept 1, 2026 | These 20 + top 4 = 24 total |

**Budget for experimental program:** 96 compounds across 3 batches per team. 24 = ~25% — leaves room for 2 more batches if these advance.

---

## Honest expectations

- Realistic SPR: 28-265 µM range (Boltz over-predicts 6-25×)
- ~1-3 of 24 may land below 5 µM at SPR (lottery odds)
- 1 µM tier ($100K): plausible long-shot for top picks
- 300 nM tier ($250K): requires SAR follow-up; not single-batch territory

---

## See also

- `top5to24_rationale.md` — per-pick rationale for these 20
- `tiered/TIERED_CANDIDATES_RATIONALE.md` — full tier definitions + 7-criterion filter
- `all_candidates_tiered.csv` — all 137 organizer-compliant candidates
- `top5to24.csv` — these 20 with all per-criterion data + SMILES
