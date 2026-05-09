# Team Picks — 5 Groups × 4 Molecules = 20 Unique Picks

**Date:** 2026-05-09 · **Submission:** 7 PM today

5 sub-teams × 4 picks = **20 unique submissions** for our team.
Lead anchor (group E) is the locked `final_4_picks.csv`; groups A-D
draw 16 distinct picks from the top-50 candidate pool to maximize
chemotype, site, and synthesis-tractability coverage.

---

## Group allocations (one row per pick)

### 🅔 GROUP E — LEAD ANCHOR (locked, final_4_picks.csv)

| ID | Site | Boltz Kd | onepot sim | Chemotype | Why |
|---|:---:|---:|---:|---|---|
| `Z795991852_analog_0021` | A | **0.46 µM** | 41% | quinazolinone_chromene | Best Boltz Kd; Mark multiseed Vina -8.50 ± 0.01 |
| `gen_0004` | F | 3.78 µM | 53% | novel_BRICS | Same chemotype as gen_0025 but onepot CORE-reachable; T-0 swap |
| `gen_0007` | F | 2.43 µM | 42% | novel_BRICS | Only pick with negative alchemical FEP ΔΔG (-3.97) |
| `Z795991852_analog_0087` | F | 2.04 µM | **86%** | quinazolinone_chromene | Wildcard — highest catalog similarity; lowest CNN-pKd σ |

### 🅐 GROUP A — BEST CONSENSUS (all 5-source compounds)

| ID | Site | Boltz Kd | onepot sim | Chemotype |
|---|:---:|---:|---:|---|
| `Z795991852_analog_0039` | F | **0.34 µM** | 40% | quinazolinone_chromene |
| `Z795991852_analog_0041` | F | 1.43 µM | 50% | quinazolinone_chromene |
| `Z795991852_analog_0038` | A | 1.54 µM | n/a | quinazolinone_chromene |
| `Z795991852_analog_0050` | F | 1.58 µM | 43% | quinazolinone_chromene |

**Pitch:** Every pick wins across 5 independent variant sources. Most defensible scientifically.

### 🅑 GROUP B — CATALOG-FRIENDLY (≥70% onepot.ai similarity)

| ID | Site | Boltz Kd | onepot sim | Chemotype |
|---|:---:|---:|---:|---|
| `Z795991852_analog_0052` | F | n/a | **79%** | quinazolinone_chromene |
| `Z795991852_analog_0008` | F | n/a | 78% | quinazolinone_chromene (CF Labs reference scaffold) |
| `Z795991852_analog_0002` | F | n/a | 77% | quinazolinone_chromene |
| `gen_0032` | F | 2.92 µM | 73% | novel_BRICS |

**Pitch:** Lowest synthesis risk; most likely to be in onepot's actual 3.4B catalog.

### 🅒 GROUP C — NOVEL CHEMISTRY (non-Z chemotypes)

| ID | Site | Boltz Kd | onepot sim | Chemotype |
|---|:---:|---:|---:|---|
| `gen_0051` | F | 2.23 µM | 64% | novel_BRICS |
| `gen_0043` | A | 2.47 µM | n/a | novel_BRICS |
| `FM001452_analog_0130` | F | 1.19 µM | 71% | anilino_benzyl_ether |
| `gen_0003` | A | 1.94 µM | n/a | novel_BRICS |

**Pitch:** Fresh chemotypes; IP novelty argument; covers both site F and site A with non-Z scaffolds.

### 🅓 GROUP D — SITE DIVERSITY (site A + 1 site G)

| ID | Site | Boltz Kd | onepot sim | Chemotype |
|---|:---:|---:|---:|---|
| `Z795991852_analog_0048` | A | **0.65 µM** | 53% | quinazolinone_chromene |
| `Z795991852_analog_0044` | A | 0.93 µM | 53% | quinazolinone_chromene |
| `Z795991852_analog_0085` | A | n/a | 40% | quinazolinone_chromene |
| `Z795991852_analog_0053` | G | 2.89 µM | 58% | quinazolinone_chromene |

**Pitch:** Pure site-A + site-G. Hedges single-site bet beyond the lead's 1 site-A pick.

---

## Coverage summary across all 20 picks

**Sites:** 12 site F · 7 site A · 1 site G

**Chemotypes:** 13 quinazolinone_chromene · 6 novel_BRICS · 1 anilino_benzyl_ether

**Best Boltz Kd:** `Z795991852_analog_0039` (group A) at **0.34 µM** — strongest of any pick

**Best onepot match:** `Z795991852_analog_0087` (group E) at **86%** + 3 picks at ≥77% in group B

---

## Top-50 candidate pool (full reference)

The complete 50-row ranked pool with every signal column is at:
**`TBXT/report/team_top50_with_groups.csv`** (group assignment in last column).

Rank columns: `n_sources` (votes across 8 ranking sources, max 5),
`v3_local_rank`, `v3_scc_rank`, `v5_g_rank`, `v1_onepot_rank`,
`orig_F_rank`, `jack_boltz_rank`, `site_A_rank`. Lower is better.

Score columns: `jack_boltz_kd_uM`, `jack_boltz_prob_binder`,
`onepot_sim_pct`, `v3_local_vina_min`, `v3_local_pose`, `v3_local_pkd`,
`v5_g_vina`, `v5_g_pose`, `v5_g_pkd`.

---

## How each group should pitch their submission

Each group should adapt the per-pick paragraphs from `report/SUBMISSION.md` (lead's text) replacing the lead's IDs with their own. Key argument anchors per group:

- **Group A**: "We selected the 4 compounds with the strongest cross-variant convergence (5 of 5 sources voted them top-10)."
- **Group B**: "We selected for synthesis tractability — every pick has ≥73% similarity to a molecule already in the onepot 3.4B catalog."
- **Group C**: "We selected for IP novelty — non-Z chemotypes offer freedom-to-operate without ceding binding evidence (Boltz Kd 1-3 µM range)."
- **Group D**: "We selected for site diversity — 3 site-A binders + 1 site-G to hedge against the dominant site-F bet of the rest of the team."
- **Group E (lead)**: as written in `report/SUBMISSION.md`.

---

## On-day workflow per sub-team

1. Each group submits independently via whatever portal organizers announce at 1:30 PM.
2. Use the per-group paragraph above as the rationale headline.
3. SMILES are in `team_top50_with_groups.csv` — copy from there.
4. **Don't coordinate further** beyond agreeing on these 20 picks. A judge may give partial credit for diversity of thought across the team.

## Caveats every group should know (also in lead's SUBMISSION.md)

- All Boltz Kd predictions are likely **6-25× over-optimistic** at the µM regime per public benchmark. Realistic SPR: 20-60 µM.
- Rowan ADMET shows **DILI 0.95-1.00 across all picks** — out-of-distribution prediction; chordoma tolerates higher tox.
- gen_0007 (group E) has **42% top onepot similarity** — genuinely novel chemistry; backed by alchemical FEP -3.97 kcal/mol.
- Site-G picks (group D's analog_0053) score equally well at site F — they're promiscuous, not site-selective.
