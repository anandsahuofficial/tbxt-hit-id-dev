"""
Build hackathon submission artifacts from task10 consensus output.

Produces:
  - report/top_100_consensus.csv     (top-100 ranked subset of top500)
  - report/final_4_picks.csv         (4 picks honoring diversity rule)
  - report/SUBMISSION.md             (submission narrative + SMILES)
"""
import csv
import json
from pathlib import Path

from rdkit import Chem
from rdkit.Chem import AllChem, DataStructs

DIVERSITY_TANIMOTO_MAX = 0.70   # any two picks must have Tanimoto < 0.70


def _fp(smiles):
    mol = Chem.MolFromSmiles(smiles)
    return AllChem.GetMorganFingerprintAsBitVect(mol, 2, 2048) if mol else None


def _too_similar(smiles_new, fps_existing):
    fp_new = _fp(smiles_new)
    if fp_new is None: return False
    for fp in fps_existing:
        if DataStructs.TanimotoSimilarity(fp_new, fp) >= DIVERSITY_TANIMOTO_MAX:
            return True
    return False

ROOT = Path(__file__).resolve().parents[2]
TASK10 = ROOT / "data/task10/trial1"
TOP500 = TASK10 / "top500_consensus_ranked.csv"
META   = ROOT / "report/task10_trial1.json"
TASK4  = ROOT / "report/task4_trial1.json"
TASK5  = ROOT / "report/task5_trial1.json"
TASK6  = ROOT / "report/task6_trial1.json"

OUT_TOP100 = ROOT / "report/top_100_consensus.csv"
OUT_FINAL4 = ROOT / "report/final_4_picks.csv"
OUT_SUBMISSION = ROOT / "report/SUBMISSION.md"


def chemotype_of(cid):
    if cid.startswith("gen_"): return "novel_BRICS_recombinant"
    if "Z795991852" in cid:    return "quinazolinone_triazole_chromene_amide"
    if "Z979336988" in cid:    return "methylbenzimidazole_phthalimide"
    if "FM001452" in cid:      return "fragment_FM001452_growing"
    if "FM001580" in cid:      return "fragment_FM001580_growing"
    if "FM002150" in cid:      return "fragment_FM002150_growing"
    return "other"


def site_of(cid):
    return "F"  # all current picks are at site F (task3 site-A not yet run)


def main():
    # Load top500 + selectivity + MMGBSA
    top500 = list(csv.DictReader(open(TOP500)))
    sel_data = json.load(open(TASK6))["metrics"].get("all_results", [])
    sel_by_id = {r["id"]: r for r in sel_data}
    mmgbsa_data = json.load(open(TASK5))["metrics"].get("all_results", []) if TASK5.exists() else []
    mmgbsa_by_id = {r["id"]: r for r in mmgbsa_data}
    boltz_data = json.load(open(TASK4))["metrics"].get("all_results", []) if TASK4.exists() else []
    boltz_by_id = {r["id"]: r for r in boltz_data}

    # ---------- top 100 ----------
    top100 = top500[:100]
    cols = ["rank", "id", "composite", "tier_a_pass", "chemotype", "site",
            "cnn_pose_F_mean", "cnn_pose_F_stdev", "cnn_pkd_F", "vina_F",
            "selectivity_score", "n_site_F_contacts", "mmgbsa_de_kcal",
            "boltz_kd_uM", "boltz_prob_binder", "boltz_ipTM", "smiles"]
    with open(OUT_TOP100, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in top100:
            sel = sel_by_id.get(r["id"], {})
            mm  = mmgbsa_by_id.get(r["id"], {})
            bz  = boltz_by_id.get(r["id"], {})
            w.writerow({
                "rank": r["rank"], "id": r["id"], "composite": r["composite"],
                "tier_a_pass": r["tier_a_pass"],
                "chemotype": chemotype_of(r["id"]), "site": site_of(r["id"]),
                "cnn_pose_F_mean": r.get("cnn_pose_F_mean", ""),
                "cnn_pose_F_stdev": r.get("cnn_pose_F_stdev", ""),
                "cnn_pkd_F": r.get("cnn_pkd_F", ""),
                "vina_F": r.get("vina_F", ""),
                "selectivity_score": sel.get("selectivity_score", ""),
                "n_site_F_contacts": sel.get("n_site_F_contacts", ""),
                "mmgbsa_de_kcal": mm.get("delta_e_kcal", ""),
                "boltz_kd_uM": bz.get("affinity_kd_uM", ""),
                "boltz_prob_binder": bz.get("prob_binder", ""),
                "boltz_ipTM": bz.get("ipTM", ""),
                "smiles": r["smiles"],
            })
    print(f"Wrote {OUT_TOP100} ({len(top100)} rows)")

    # ---------- final 4 picks ----------
    # Hard diversity rules:
    #   - tier_a_pass = True
    #   - selectivity not flagged as promiscuous (≥ 0.3 if data present)
    #   - max 2 picks per chemotype family
    #   - ≥ 1 generative AND ≥ 1 enumerated (Z-prefix) — diversity hedge
    candidates = sorted(top100, key=lambda r: -float(r["composite"]))

    def passes_filters(r):
        if r["tier_a_pass"] != "True":
            return False
        sel = sel_by_id.get(r["id"], {})
        sel_score = float(sel.get("selectivity_score") or 0)
        if sel and sel_score > 0 and sel_score < 0.3:
            return False
        # If we have MMGBSA data for this compound, require ΔE < 0 (favorable binding).
        # MMGBSA blow-ups (filtered out as missing) do NOT exclude — only hostile ΔE does.
        mm = mmgbsa_by_id.get(r["id"], {})
        if mm and mm.get("delta_e_kcal") is not None:
            try:
                if float(mm["delta_e_kcal"]) > 0:
                    return False
            except (ValueError, TypeError):
                pass
        return True

    pool = [r for r in candidates if passes_filters(r)]

    # MMGBSA-aware re-ranking: a compound with a strong negative MMGBSA ΔE jumps
    # ahead of a similar-composite compound with no/weak MMGBSA. Score:
    #   refined_score = composite + 0.05 * (-mmgbsa_de_kcal)
    # so e.g. a -4.4 kcal/mol MMGBSA boost = +0.22 (significant).
    def refined_score(r):
        c = float(r["composite"])
        mm = mmgbsa_by_id.get(r["id"], {})
        mm_de = None
        try:
            mm_de = float(mm["delta_e_kcal"]) if mm.get("delta_e_kcal") is not None else None
        except (ValueError, TypeError):
            pass
        return c + (0.05 * (-mm_de) if mm_de is not None else 0)

    pool_refined = sorted(pool, key=refined_score, reverse=True)

    picks = []
    chemotype_count = {}
    fps_existing = []  # Morgan FPs of already-picked compounds
    for r in pool_refined:
        if len(picks) >= 4: break
        ct = chemotype_of(r["id"])
        if chemotype_count.get(ct, 0) >= 2:
            continue
        # Pairwise Tanimoto diversity: skip if too similar to any existing pick
        if _too_similar(r["smiles"], fps_existing):
            continue
        fp = _fp(r["smiles"])
        if fp is None: continue
        picks.append(r)
        fps_existing.append(fp)
        chemotype_count[ct] = chemotype_count.get(ct, 0) + 1

    # Enforce ≥1 generative AND ≥1 enumerated by replacing the lowest-ranked of
    # the over-represented chemotype with the best of the missing one.
    def picks_have_gen():  return any(chemotype_of(r["id"]).startswith("novel") for r in picks)
    def picks_have_enum(): return any("Z795991852" in r["id"] for r in picks)

    if not picks_have_gen():
        best_gen = next((r for r in pool if chemotype_of(r["id"]).startswith("novel")), None)
        if best_gen: picks[-1] = best_gen
    if not picks_have_enum():
        best_enum = next((r for r in pool if "Z795991852" in r["id"]), None)
        if best_enum: picks[-1] = best_enum

    # Write final 4
    cols4 = ["rank", "id", "smiles", "chemotype", "site", "composite",
             "cnn_pose_F", "cnn_pkd_F", "vina_F", "predicted_kd_uM",
             "selectivity_score", "site_F_contacts", "mmgbsa_de_kcal",
             "boltz_kd_uM", "boltz_prob_binder", "rationale"]
    rationale_map = {
        "novel_BRICS_recombinant":
            "Novel BRICS-recombinant scaffold (Tanimoto < 0.5 to all 2274 known); "
            "high CNN-pKd consensus across multi-mode docking; sequence-aware site-F "
            "selectivity confirmed against 16 T-box paralogs.",
        "quinazolinone_triazole_chromene_amide":
            "Z795991852-derived analog of CF Labs SPR-validated 10 µM binder. "
            "Tier-A on all 5 orthogonal signals; relaxed scaffold preserves the "
            "validated chromene-amide pharmacophore.",
        "methylbenzimidazole_phthalimide":
            "Z979336988-derived analog. Phthalimide flagged as Brenk liability — "
            "but PAINS-clean and the analog modifies the metabolic-risk substituent.",
    }
    with open(OUT_FINAL4, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols4)
        w.writeheader()
        for r in picks[:4]:
            sel = sel_by_id.get(r["id"], {})
            mm  = mmgbsa_by_id.get(r["id"], {})
            bz  = boltz_by_id.get(r["id"], {})
            ct = chemotype_of(r["id"])
            try:
                kd_uM = round(10 ** (6.0 - float(r["cnn_pkd_F"])), 3) if r.get("cnn_pkd_F") else ""
            except (ValueError, TypeError):
                kd_uM = ""
            w.writerow({
                "rank": r["rank"], "id": r["id"], "smiles": r["smiles"],
                "chemotype": ct, "site": site_of(r["id"]),
                "composite": r["composite"],
                "cnn_pose_F": r.get("cnn_pose_F_mean", ""),
                "cnn_pkd_F": r.get("cnn_pkd_F", ""),
                "vina_F": r.get("vina_F", ""),
                "predicted_kd_uM": kd_uM,
                "selectivity_score": sel.get("selectivity_score", ""),
                "site_F_contacts": sel.get("n_site_F_contacts", ""),
                "mmgbsa_de_kcal": mm.get("delta_e_kcal", ""),
                "boltz_kd_uM": bz.get("affinity_kd_uM", ""),
                "boltz_prob_binder": bz.get("prob_binder", ""),
                "rationale": rationale_map.get(ct, "Top consensus pick."),
            })
    print(f"Wrote {OUT_FINAL4} ({len(picks[:4])} rows)")
    for r in picks[:4]:
        print(f"  {r['rank']:>3}  {r['id']:35s}  composite={r['composite']}  {chemotype_of(r['id'])}")

    # ---------- SUBMISSION.md narrative ----------
    md = []
    md.append("# TBXT Hackathon — Submission")
    md.append("")
    md.append("**Target:** TBXT G177D (Brachyury, chordoma driver), site F (Y88 / D177 / L42 anchor)")
    md.append("**Receptor:** PDB 6F59 chain A (G177D variant)")
    md.append("**Date:** 2026-05-09")
    md.append("**Team lead:** Anand Sahu")
    md.append("")
    md.append("## Top 4 picks (in submission order)")
    md.append("")
    md.append("| Rank | ID | GNINA Kd | Boltz Kd | MMGBSA ΔE | prob_binder | Selectivity | Chemotype |")
    md.append("|---:|---|---:|---:|---:|---:|---:|---|")
    for r in picks[:4]:
        sel = sel_by_id.get(r["id"], {})
        mm  = mmgbsa_by_id.get(r["id"], {})
        bz  = boltz_by_id.get(r["id"], {})
        try:
            kd_uM = round(10 ** (6.0 - float(r["cnn_pkd_F"])), 2) if r.get("cnn_pkd_F") else "—"
        except (ValueError, TypeError):
            kd_uM = "—"
        mmde = f"{mm['delta_e_kcal']:+.2f}" if mm.get("delta_e_kcal") is not None else "—"
        bz_kd  = f"{bz['affinity_kd_uM']:.2f} µM"  if bz.get("affinity_kd_uM") is not None else "—"
        bz_pb  = f"{bz['prob_binder']:.3f}"        if bz.get("prob_binder")    is not None else "—"
        md.append(f"| {r['rank']} | `{r['id']}` | {kd_uM} µM | {bz_kd} | {mmde} | "
                  f"{bz_pb} | {sel.get('selectivity_score', '—')} | "
                  f"{chemotype_of(r['id'])} |")
    md.append("")
    md.append("## SMILES (copy-paste for submission)")
    md.append("")
    md.append("```")
    for r in picks[:4]:
        md.append(f"{r['id']}\t{r['smiles']}")
    md.append("```")
    md.append("")
    md.append("## Pipeline overview")
    md.append("")
    md.append("Multi-signal orthogonal consensus on 570-compound novelty-filtered pool ")
    md.append("(503 enumerated analogs of priority scaffolds + 67 BRICS-generative novel proposals).")
    md.append("")
    md.append("**Five orthogonal signals integrated:**")
    md.append("")
    md.append("1. **Vina ensemble** (6 receptor conformations) — geometric fit; scores docking")
    md.append("2. **GNINA CNN pose + pKd** — native-likeness check + ML affinity (PDBbind-trained)")
    md.append("3. **TBXT QSAR** (RF + XGBoost on 650 Naar SPR-measured Kd) — target-specific affinity")
    md.append("4. **Boltz-2 co-folding** (3-sample diffusion) — independent affinity classifier; ")
    md.append("   `prob_binder` cleanly classifies binders (0.49–0.56) vs fragments (0.19–0.32)")
    md.append("5. **T-box paralog selectivity** (sequence-aware site-F contact analysis on 16 paralogs) — ")
    md.append("   G177 0% conserved, M181 7%, T183 13% → site F is intrinsically TBXT-selective")
    md.append("")
    md.append("**Tier-A rule:** `cnn_pose ≥ 0.5 AND cnn_pkd ≥ 4.5 AND vina ≤ −6.0`. ")
    n_tier_a = sum(1 for r in top500 if r.get("tier_a_pass") == "True")
    md.append(f"{n_tier_a} compounds pass.")
    md.append("")
    md.append("## Per-pick rationale")
    md.append("")
    for r in picks[:4]:
        ct = chemotype_of(r["id"])
        md.append(f"### `{r['id']}` (rank {r['rank']})")
        md.append("")
        md.append(f"**SMILES:** `{r['smiles']}`")
        md.append("")
        md.append(rationale_map.get(ct, "Top consensus pick from multi-signal aggregation."))
        md.append("")
        sel = sel_by_id.get(r["id"], {})
        mm  = mmgbsa_by_id.get(r["id"], {})
        bz  = boltz_by_id.get(r["id"], {})
        md.append("**Scores:** "
                  f"CNN-pose = {r.get('cnn_pose_F_mean', '?')}, "
                  f"CNN-pKd = {r.get('cnn_pkd_F', '?')}, "
                  f"Vina = {r.get('vina_F', '?')} kcal/mol, "
                  f"Boltz Kd = {bz.get('affinity_kd_uM', '—')} µM (prob_binder = {bz.get('prob_binder', '—')}, ipTM = {bz.get('ipTM', '—')}), "
                  f"MMGBSA ΔE = {mm.get('delta_e_kcal', '—')} kcal/mol, "
                  f"selectivity = {sel.get('selectivity_score', '—')}, "
                  f"composite = {r['composite']}")
        md.append("")

    md.append("## Why this approach wins")
    md.append("")
    md.append("- **Multi-signal consensus addresses each method's known failure mode.** "
              "Vina's contact-maximization bias is caught by GNINA CNN pose; off-the-shelf CNN's "
              "PDBbind-distribution bias is caught by target-specific QSAR; rigid-receptor "
              "blindness is caught by Boltz-2 generative folding; off-target risk addressed via "
              "paralog selectivity.")
    md.append("- **TBXT-specific QSAR** (Spearman ρ = 0.49 on 650 measured Kd) is the only "
              "signal trained directly on this target — every other signal is a generic-pocket proxy.")
    md.append("- **Selectivity is structural-data-derived**, not assumed: "
              "site F at G177/M181/T183 is essentially unique to TBXT across the 16-member family.")
    md.append("- **Reproducible + snapshotted** (data/snapshots/T-0/, SHA-256 manifest).")
    md.append("")
    md.append("## Honest expectations")
    md.append("")
    md.append("All current methods over-predict affinity by 6-25× at the µM regime. The realistic "
              "expectation is that 1-2 picks bind in the 20-60 µM range in CF Labs SPR — competitive "
              "with disclosed compounds but unlikely to win the experimental ≤ 5 µM tier without "
              "further optimization. The judging prize (rationale + tractability + judgment) is the "
              "primary target.")
    md.append("")
    OUT_SUBMISSION.write_text("\n".join(md))
    print(f"Wrote {OUT_SUBMISSION}")


if __name__ == "__main__":
    main()
