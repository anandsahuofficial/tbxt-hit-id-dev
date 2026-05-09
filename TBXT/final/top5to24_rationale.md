# Top 5-24 — Rationale (20 additional submissions)

**Submission:** TBXT Hit Identification Hackathon · 2026-05-09 · Pillar VC, Boston
**Project lead:** Anand Sahu

These 20 compounds are the team's additional submissions beyond the
hackathon-judging top 4. Together with `top4.csv`, this forms the
**24-compound team submission**. All 20 here also strictly satisfy every
organizer constraint (same 7-criterion filter chain as top 4) and are
**ready for the experimental prize program first batch** (Sept 1
deadline; up to 96 compounds across 3 batches).

## Selection rule

Ranks 5-24 of the 137-compound tiered candidate pool, sorted strict-first
(tier order: T2 SILVER → T3 BRONZE) then by Boltz Kd ascending. See
`tiered/TIERED_CANDIDATES_RATIONALE.md` for the per-tier definitions
and the full 137-row CSV at `all_candidates_tiered.csv`.

## Headline (20 picks, all 100%-onepot non-covalent)

| Rank | ID | Site | Boltz Kd Jack/SCC µM | $ | risks | Tier | One-line |
|---:|---|:---:|---:|---:|:---:|:---:|---|
| 5 | `FM002150_analog_0082` | F | 4.74 / — | $250 | med/low | T2 SILVER | Same FM002150 family as #1; alternate substituent |
| 6 | `FM001452_analog_0040` | F | 5.87 / 5.65 | $1000 | low/high | T2 SILVER | High supplier risk + price; flag as backup |
| 7 | `FM001452_analog_0009` | F | 6.25 / 7.72 | $375 | high/med | T2 SILVER | Strong dual-engine Boltz; high chem risk (urea) |
| 8 | `FM001452_analog_0008` | F | 6.32 / 6.99 | $375 | high/med | T2 SILVER | Sibling of #7 in same chemotype |
| 9 | `FM001452_analog_0005` | F | 6.76 / 8.08 | $250 | med/low | T2 SILVER | Lowest chem-risk variant of family at this Kd |
| 10 | `FM001452_analog_0004` | F | 7.00 / 6.99 | $250 | med/med | T2 SILVER | Tight dual-engine agreement (1.0×) |
| 11 | `FM001452_analog_0020` | F | 7.00 / — | **$125** | **low/low** | T2 SILVER | **Cleanest risks + cheapest in mid-tier** |
| 12 | `FM002150_analog_0080` | F | 7.64 / — | $250 | med/low | T2 SILVER | Best aqueous solubility (logS -3.98 = ~104 µM) |
| 13 | `FM002150_analog_0053` | F | 8.20 / — | $590 | med/med | T2 SILVER | FM002150 backup; medium across all dimensions |
| 14 | `FM002150_analog_0056` | F | 8.34 / — | $885 | high/med | T2 SILVER | Higher-risk FM002150 alternate |
| 15 | `FM001452_analog_0155` | F | 8.47 / 8.45 | **$125** | **low/low** | T2 SILVER | **Tied for cleanest+cheapest** |
| 16 | `FM001452_analog_0162` | F | 9.51 / 8.77 | $125 | low/med | T2 SILVER | Cheapest at the 9-µM tier |
| 17 | `FM001452_analog_0001` | F | 9.30 / 9.91 | $295 | low/med | T2 SILVER | Most soluble compound in T2 (logS -3.78) |
| 18 | `FM001452_analog_0030` | F | 5.97 / 5.86 | $540 | low/low | T3 BRONZE | T3 entry but stronger Boltz than several T2; clean risks |
| 19 | `opv1_000076` | F | — / — (gnina 6.32) | $375 | high/low | T3 BRONZE | v1 onepot enumeration alternate; gnina-only Kd |
| 20 | `FM001452_analog_0032` | F | 6.34 / 6.48 | $590 | med/low | T3 BRONZE | T3 due to logS borderline; otherwise clean |
| 21 | `FM001452_analog_0029` | F | 7.46 / 7.53 | $295 | low/low | T3 BRONZE | Clean low/low risks; cheap; T3 only on solubility |
| 22 | `FM001452_analog_0059` | F | 7.86 / 7.60 | $590 | med/low | T3 BRONZE | T3 chemotype backup |
| 23 | `FM002150_analog_0027` | F | 10.34 / — | $885 | high/med | T3 BRONZE | FM002150 family fallback at higher Kd |
| 24 | `FM001452_analog_0015` | F | 10.25 / 11.56 | $1000 | low/high | T3 BRONZE | Last position; high supplier risk |

## What this set adds beyond the top 4

- **Chemotype mix:** 14 FM001452 family + 5 FM002150 family + 1 opv1 (v1 onepot enumeration). The FM002150 family (4 compounds: ranks 5, 12, 13, 14, 23) is the second-most-represented chemotype after FM001452 — provides scaffold diversification within the catalog-resident pool.

- **Boltz Kd range:** 4.7-10.6 µM (Jack). All 20 within ~3× of the top 4 (which span 3.2-8.3 µM). Realistic spread: 28-265 µM at SPR after 6-25× over-prediction correction.

- **Cost diversity:** 6 picks at $125 (cheapest tier) — `FM001452_analog_0020`, `_0155`, `_0162`. Useful for cost-bounded experimental program submissions.

- **Risk profile spread:** 5 picks with low/low chemistry+supplier risks (the cleanest of the bunch); the rest are medium across one or both. Only 4 high-chemistry-risk picks (urea-derived FM001452 variants).

## Per-tier reasoning

**Why T2 SILVER first (ranks 5-17, 13 compounds):** All 13 pass every
hard criterion AND every lead-like ideal AND have predicted aqueous
solubility (ESOL log S > -5 for direct use in 50 µM aqueous buffer per
the experimental program spec). These are the "strongly compliant"
backups.

**Then T3 BRONZE (ranks 18-24, 7 compounds):** Pass every hard criterion
AND every lead-like ideal AND have Boltz Kd ≤ 50 µM. T3 vs T2 differ
only on aqueous solubility (logS ≤ -5 = borderline aqueous, fine for
DMSO @ 10 mM stock). FM001452_analog_0030 (rank 18) is in T3 only
because of logS — it has stronger Boltz Kd (5.97 µM) than several T2
picks. Listed among the additional submissions for full coverage.

**Excluded T4 RELAXED (32 candidates):** These pass hard constraints
but slip on lead-like ideals (e.g., > 2 fused rings or LogP slightly
≥ 5). Not in this 20 because the 7 T3 picks are stronger across more
dimensions; T4 reserved as deeper backup if any of these 24 fail wet-lab
QC.

## Submission instructions for the team

These 20 are in `top5to24.csv` with all per-criterion data + Boltz +
muni onepot data. Sub-team members responsible for the additional
submissions can:

1. Read this file + `top5to24.csv` for the 20-pick context
2. Submit them to whatever portal organizers provide for the experimental
   program (post-hackathon; intent deadline June 1, first batch Sept 1)
3. The hackathon-day live demo focuses on `top4.csv` only (see
   `submission_top4.md` + `slide_top4.md`)

For deeper backup beyond these 20, use `all_candidates_tiered.csv`
ranks 25+ (still 113 compounds remain in T2 SILVER + T3 BRONZE +
T4 RELAXED tiers).

## Honest expectations (same as top 4)

- Public Boltz over-predicts by 6-25× at µM regime. Realistic SPR: 28-265 µM range for the bulk of these 20.
- ~1-3 of the 24 may land below 5 µM at SPR (lottery odds; not
  guaranteed). The 1 µM experimental tier ($100K) is plausible long-shot
  for the strongest 4-5 picks across the 24.
- 300 nM tier ($250K) requires SAR follow-up rounds — would not be
  expected from a single-batch screen.
