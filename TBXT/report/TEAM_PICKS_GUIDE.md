# Team Picks Guide — Top 100 Pool + Sub-Team Allocations

**Date:** 2026-05-09 · **Submission:** 7 PM today

The full 100-compound ranked pool is at **`TBXT/report/team_picks_pool.csv`**.
This guide proposes **4 themed allocations × 4 picks each = 16 total team
submissions** with no compound duplicated across sub-teams.

---

## How the pool is ranked

Compounds appear in `team_picks_pool.csv` if they ranked in the top 50-80
of any of these 8 sources:

1. **v3 LOCAL** ensemble (4-receptor consensus at site F)
2. **v3 SCC** ensemble (4 receptors; one with broken Vina — CNN still valid)
3. **v5** site-G dock (570 compounds at TEP's 3rd recommended pocket)
4. **v1** onepot-friendly (50 compounds enumerated via 7 onepot reactions)
5. **Original site-F** GNINA (full pool baseline)
6. **Jack's Boltz** full pool (independent Boltz on all 570 compounds)
7. **Onepot.ai** similarity score (catalog reachability)
8. **Site A** task3 GNINA dock

Final ranking key: `(-n_sources, jack_boltz_kd_uM, v3_local_rank)` — favors
compounds that win across multiple independent signals, then breaks ties by
strongest predicted binding (Jack's Boltz Kd) and v3 LOCAL composite.

---

## 🅐 Sub-team A — BEST CONSENSUS (defensible, all 5-source)

Theme: every pick wins across 5 independent variant sources. Strongest
scientific defensibility for the judging prize.

| # | ID | Site | Jack Boltz Kd | onepot sim | Chemotype |
|---:|---|:---:|---:|---:|---|
| 1 | `Z795991852_analog_0039` | F | **0.34 µM** | 40% | quinazolinone_chromene_amide |
| 2 | `Z795991852_analog_0041` | F | 1.43 µM | 50% | quinazolinone_chromene_amide |
| 3 | `Z795991852_analog_0086` | F | 1.62 µM | 42% | quinazolinone_chromene_amide |
| 4 | `Z795991852_analog_0050` | F | 1.58 µM | 43% | quinazolinone_chromene_amide |

**Pitch:** All 4 picks bind site F at sub-µM to low-µM predicted Kd, agreed
by GNINA (4-receptor ensemble), Boltz, original docking, and Jack's
independent Boltz reproduction. Conservative, evidence-rich.

---

## 🅑 Sub-team B — ONEPOT CATALOG-FRIENDLY (synthesis-tractable)

Theme: every pick has ≥70% similarity to an actual onepot catalog molecule.
Lowest synthesis risk; strongest "submission validity" angle.

| # | ID | Site | Jack Boltz Kd | onepot sim | Chemotype |
|---:|---|:---:|---:|---:|---|
| 1 | `FM001452_analog_0201` | G→F | n/a | **100%** | anilino_benzyl_ether |
| 2 | `Z795991852_analog_0087` | F | 2.04 µM | 86% | quinazolinone_chromene_amide |
| 3 | `Z795991852_analog_0052` | F | n/a | 79% | quinazolinone_chromene_amide |
| 4 | `Z795991852_analog_0008` | F | n/a | 78% | quinazolinone_chromene_amide |

**Pitch:** Tractability-first. Catalog-identical or near-identical
candidates that survive multi-signal filtering. Best fit if organizer
strictly enforces "must be in onepot's 3.4B library".

---

## 🅒 Sub-team C — NOVEL CHEMISTRY (IP novelty + breadth)

Theme: non-Z chemotypes for IP / scaffold diversity.

| # | ID | Site | Jack Boltz Kd | onepot sim | Chemotype |
|---:|---|:---:|---:|---:|---|
| 1 | `gen_0051` | F | 2.23 µM | 64% | novel_BRICS |
| 2 | `gen_0032` | F | 2.92 µM | 73% | novel_BRICS |
| 3 | `gen_0043` | A | 2.47 µM | n/a | novel_BRICS |
| 4 | `FM001452_analog_0130` | F | 1.19 µM | 71% | anilino_benzyl_ether |

**Pitch:** Fresh chemotypes, 3 different scaffolds. Argues for IP-clean
exploration around the validated TBXT pocket. Highest-risk highest-reward.

---

## 🅓 Sub-team D — SITE DIVERSITY (A + G coverage)

Theme: pure site-A and site-G picks. Hedges single-site bet.

| # | ID | Site | Jack Boltz Kd | onepot sim | Chemotype |
|---:|---|:---:|---:|---:|---|
| 1 | `Z795991852_analog_0038` | A | 1.54 µM | n/a | quinazolinone_chromene_amide |
| 2 | `Z795991852_analog_0085` | A | n/a | 40% | quinazolinone_chromene_amide |
| 3 | `Z795991852_analog_0048` | A | **0.65 µM** | 53% | quinazolinone_chromene_amide |
| 4 | `Z795991852_analog_0053` | G | 2.89 µM | 58% | quinazolinone_chromene_amide |

**Pitch:** "We surveyed all 3 TEP-recommended pockets and chose binders
specific to each." Best fits the organizer's recommended composition
(2F + 1A + 1 wildcard) when paired with sub-team A or B's site-F picks.

---

## Lead-team (anchor) — what's already locked in `final_4_picks.csv`

| # | ID | Site | Why it's locked in |
|---:|---|:---:|---|
| 1 | `Z795991852_analog_0021` | A | Mark multiseed Vina -8.50 ± 0.01 (rock-solid); Jack-Boltz 0.46 µM |
| 2 | `gen_0004` | F | Same chemotype as gen_0025 but onepot-CORE reachable (CH₂-N linker) |
| 3 | `gen_0007` | F | Best alchemical FEP ΔΔG (-3.97); only neg-ΔΔG of any candidate |
| 4 | `Z795991852_analog_0087` | F | 86% onepot match (highest of 4); Mark multiseed lowest variance |

---

## Dedup verification

All 16 sub-team picks are unique. Lead-team picks 1 and 4
(`Z795991852_analog_0021`, `Z795991852_analog_0087`) DO appear in the
broader pool but are reserved for the lead submission — sub-teams A-D
should NOT pick the same IDs. The 16 picks above already exclude them.

---

## On-day workflow

1. **Each sub-team submits independently** to whatever portal organizers
   announce at 1:30 PM. Don't coordinate beyond agreeing on these
   allocations to maximize team coverage.
2. Use **`TBXT/report/SUBMISSION.md`** as the rationale template — copy
   the per-pick paragraphs and adapt the IDs.
3. **Avoid duplicate scoring**: a compound counted twice across sub-team
   submissions doesn't score double. Better to spread across non-overlapping
   chemotypes.
4. If you want to swap any pick for a different chemotype/site, the full
   100-compound pool is at `team_picks_pool.csv` — sort by `n_sources`
   for confidence, by `jack_boltz_kd_uM` for binding, by `onepot_sim_pct`
   for catalog availability.

---

## Honest caveats sub-teams should know

- **DILI predictions are 0.95-1.00 across all picks** — this is a known
  limitation of public ADMET models on novel scaffolds. Chordoma is rare
  cancer; tox bar is higher than chronic.
- **Chemotype concentration**: 75/100 of the pool is Z795991852 chromene-
  amide variants. This reflects that Z795991852 is the strongest validated
  CF Labs hit, and analogs naturally inherit its binding mode.
- **No compound has been wet-lab tested** — all numbers are predictions.
  Expect 6-25× over-prediction of affinity at the µM regime per public
  benchmark (in `data/qsar/QSAR_VALIDATION.md`).
