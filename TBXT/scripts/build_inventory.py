"""
Build a clean prior-art inventory for TBXT hit-ID work:
  - Canonicalize all SMILES with RDKit
  - Compute drug-like descriptors (MW, HBD, HBA, LogP, HA, rings, fused rings, RotB, TPSA)
  - Apply hard rules from ABOUT.md (LogP <=6, HBD <=6, HBA <=12, MW <=600)
  - Apply soft "lead-like" guidance (HA 10-30, HBD+HBA <=11, LogP <5, rings <5, fused rings <=2)
  - Build Morgan fingerprints
  - For each TEP fragment, find nearest Naar neighbor (Tanimoto)
  - For the 3 known CF Labs SPR hits, find their nearest TEP-fragment & nearest Naar-other neighbors
  - Save: prior_art_canonical.csv, similarity_pairs.csv, summary.md
"""

import csv
import sys
from collections import defaultdict
from pathlib import Path

from rdkit import Chem, RDLogger, DataStructs
from rdkit.Chem import AllChem, Descriptors, Lipinski, rdMolDescriptors

RDLogger.DisableLog("rdApp.*")  # silence valence warnings on raw inputs

DATA = Path("/home/anandsahu/Hackathon/TBXT/data")
OUT = DATA

CF_HITS = {
    "Z979336988": ("F", 3.0, 30.0),       # site, SPR Kd µM, CF Kd µM
    "Z795991852": ("F", 10.0, 10.0),
    "D203-0031":  ("F or G", 2.0, 17.0),
}


def load_inputs():
    tep, sheet, zenodo = [], [], []

    with open(DATA / "tep" / "tep_fragments_full.csv") as f:
        for r in csv.DictReader(f):
            tep.append({
                "source": "tep_fragment",
                "id": r["fragment_id"],
                "pdb_id": r["pdb_id"],
                "ccd": r["ccd"],
                "site": r["site"],
                "smiles_in": r["smiles"],
                "iupac_name": r["iupac_name"],
            })

    with open(DATA / "naar" / "naar_sheet_export.csv") as f:
        for i, row in enumerate(csv.reader(f)):
            if i < 1 or not row[0] or not row[1]: continue
            sheet.append({
                "source": "naar_sheet",
                "id": row[0],
                "pdb_id": "",
                "ccd": "",
                "site": "unknown",
                "smiles_in": row[1],
                "iupac_name": "",
            })

    with open(DATA / "naar" / "naar_smiles.csv") as f:
        for i, row in enumerate(csv.reader(f)):
            if i < 2 or not row or not row[0] or not row[1]: continue
            zenodo.append({
                "source": "naar_zenodo",
                "id": row[0],
                "pdb_id": "",
                "ccd": "",
                "site": "unknown",
                "smiles_in": row[1],
                "iupac_name": "",
            })

    return tep, sheet, zenodo


def canonicalize_and_descriptors(rec):
    smi = rec["smiles_in"]
    mol = Chem.MolFromSmiles(smi)
    if mol is None:
        rec.update({
            "smiles": "", "valid": False, "mw": None, "ha": None,
            "hbd": None, "hba": None, "logp": None, "tpsa": None,
            "rotb": None, "rings": None, "fused_rings": None,
            "passes_chordoma_hard": False, "passes_lead_like": False,
        })
        return rec

    rec["smiles"] = Chem.MolToSmiles(mol)
    rec["valid"] = True
    rec["mw"] = round(Descriptors.MolWt(mol), 1)
    rec["ha"] = mol.GetNumHeavyAtoms()
    rec["hbd"] = Lipinski.NumHDonors(mol)
    rec["hba"] = Lipinski.NumHAcceptors(mol)
    rec["logp"] = round(Descriptors.MolLogP(mol), 2)
    rec["tpsa"] = round(Descriptors.TPSA(mol), 1)
    rec["rotb"] = Lipinski.NumRotatableBonds(mol)
    ri = mol.GetRingInfo()
    rec["rings"] = ri.NumRings()
    # fused rings: count pairs of rings sharing >=2 atoms
    fused = 0
    rings = ri.AtomRings()
    for i in range(len(rings)):
        for j in range(i + 1, len(rings)):
            if len(set(rings[i]) & set(rings[j])) >= 2:
                fused += 1
                break
    rec["fused_rings"] = fused

    # Chordoma Foundation hard rule: LogP<=6, HBD<=6, HBA<=12, MW<=600
    rec["passes_chordoma_hard"] = (
        rec["logp"] <= 6 and rec["hbd"] <= 6 and rec["hba"] <= 12 and rec["mw"] <= 600
    )
    # Lead-like soft rule: HA in [10,30], HBD+HBA<=11, LogP<5, rings<5, fused<=2
    rec["passes_lead_like"] = (
        10 <= rec["ha"] <= 30
        and rec["hbd"] + rec["hba"] <= 11
        and rec["logp"] < 5
        and rec["rings"] < 5
        and rec["fused_rings"] <= 2
    )
    return rec


def main():
    tep, sheet, zenodo = load_inputs()
    print(f"Loaded TEP={len(tep)}, Naar sheet={len(sheet)}, Naar zenodo={len(zenodo)}", file=sys.stderr)

    all_recs = []
    for r in tep + sheet + zenodo:
        all_recs.append(canonicalize_and_descriptors(r))

    # Dedup by canonical SMILES while keeping highest-priority annotation:
    # priority: tep_fragment > naar_sheet > naar_zenodo
    PRIORITY = {"tep_fragment": 0, "naar_sheet": 1, "naar_zenodo": 2}
    smi_to_rec = {}
    smi_to_aliases = defaultdict(list)
    for r in all_recs:
        if not r["valid"]:
            continue
        smi = r["smiles"]
        smi_to_aliases[smi].append((r["source"], r["id"]))
        prior = smi_to_rec.get(smi)
        if prior is None or PRIORITY[r["source"]] < PRIORITY[prior["source"]]:
            smi_to_rec[smi] = r
    inventory = list(smi_to_rec.values())
    # Add alias list
    for r in inventory:
        aliases = [(s, i) for (s, i) in smi_to_aliases[r["smiles"]] if (s, i) != (r["source"], r["id"])]
        r["alias_count"] = len(aliases)
        r["aliases"] = "; ".join(f"{s}:{i}" for s, i in aliases[:5])

    # Annotate CF Labs hits
    for r in inventory:
        if r["id"] in CF_HITS:
            site, hdb_kd, cf_kd = CF_HITS[r["id"]]
            r["spr_site"] = site
            r["spr_kd_hdb_uM"] = hdb_kd
            r["spr_kd_cf_uM"] = cf_kd
            r["is_cf_hit"] = True
        else:
            r["spr_site"] = ""
            r["spr_kd_hdb_uM"] = ""
            r["spr_kd_cf_uM"] = ""
            r["is_cf_hit"] = False

    print(f"Unique canonical SMILES: {len(inventory)}", file=sys.stderr)
    print(f"Invalid SMILES dropped: {sum(1 for r in all_recs if not r['valid'])}", file=sys.stderr)

    # Build Morgan fingerprints
    fps = {}
    for r in inventory:
        mol = Chem.MolFromSmiles(r["smiles"])
        fps[r["id"]] = AllChem.GetMorganFingerprintAsBitVect(mol, 2, nBits=2048)

    # For each TEP fragment, find nearest Naar neighbor
    naar_ids = [r["id"] for r in inventory if r["source"] in ("naar_sheet", "naar_zenodo")]
    naar_fps = [fps[i] for i in naar_ids]

    pairs = []
    for r in inventory:
        if r["source"] != "tep_fragment":
            continue
        sims = DataStructs.BulkTanimotoSimilarity(fps[r["id"]], naar_fps)
        # top-1
        best_i = max(range(len(sims)), key=lambda i: sims[i])
        best = inventory[next(i for i, x in enumerate(inventory) if x["id"] == naar_ids[best_i])]
        pairs.append({
            "from_kind": "tep_fragment",
            "from_id": r["id"],
            "from_site": r["site"],
            "from_smiles": r["smiles"],
            "to_kind": best["source"],
            "to_id": best["id"],
            "to_smiles": best["smiles"],
            "tanimoto": round(sims[best_i], 3),
            "to_is_cf_hit": best["is_cf_hit"],
        })

    # For each CF Labs hit, find nearest TEP fragment + nearest other Naar
    tep_ids = [r["id"] for r in inventory if r["source"] == "tep_fragment"]
    tep_fps = [fps[i] for i in tep_ids]
    other_naar_ids_for_cf = {h: [i for i in naar_ids if i != h] for h in CF_HITS}
    other_naar_fps_for_cf = {h: [fps[i] for i in other_naar_ids_for_cf[h]] for h in CF_HITS}

    for r in inventory:
        if not r["is_cf_hit"]:
            continue
        # nearest TEP
        sims_t = DataStructs.BulkTanimotoSimilarity(fps[r["id"]], tep_fps)
        bi = max(range(len(sims_t)), key=lambda i: sims_t[i])
        nearest_tep = next(x for x in inventory if x["id"] == tep_ids[bi])
        pairs.append({
            "from_kind": "cf_labs_hit",
            "from_id": r["id"],
            "from_site": r["spr_site"],
            "from_smiles": r["smiles"],
            "to_kind": "tep_fragment",
            "to_id": nearest_tep["id"],
            "to_smiles": nearest_tep["smiles"],
            "tanimoto": round(sims_t[bi], 3),
            "to_is_cf_hit": False,
        })
        # nearest other Naar
        sims_n = DataStructs.BulkTanimotoSimilarity(fps[r["id"]], other_naar_fps_for_cf[r["id"]])
        bi = max(range(len(sims_n)), key=lambda i: sims_n[i])
        nn = next(x for x in inventory if x["id"] == other_naar_ids_for_cf[r["id"]][bi])
        pairs.append({
            "from_kind": "cf_labs_hit",
            "from_id": r["id"],
            "from_site": r["spr_site"],
            "from_smiles": r["smiles"],
            "to_kind": nn["source"],
            "to_id": nn["id"],
            "to_smiles": nn["smiles"],
            "tanimoto": round(sims_n[bi], 3),
            "to_is_cf_hit": nn["is_cf_hit"],
        })

    # Write outputs
    cols = [
        "source", "id", "pdb_id", "ccd", "site", "smiles", "valid", "ha", "mw",
        "hbd", "hba", "logp", "tpsa", "rotb", "rings", "fused_rings",
        "passes_chordoma_hard", "passes_lead_like",
        "is_cf_hit", "spr_site", "spr_kd_hdb_uM", "spr_kd_cf_uM",
        "alias_count", "aliases", "iupac_name",
    ]
    with open(OUT / "prior_art_canonical.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in inventory:
            w.writerow({k: r.get(k, "") for k in cols})

    with open(OUT / "similarity_pairs.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "from_kind", "from_id", "from_site", "to_kind", "to_id",
            "tanimoto", "to_is_cf_hit", "from_smiles", "to_smiles"])
        w.writeheader()
        w.writerows(pairs)

    # Summary stats
    by_source = defaultdict(int)
    by_site = defaultdict(int)
    pass_hard = 0
    pass_lead = 0
    for r in inventory:
        by_source[r["source"]] += 1
        if r["passes_chordoma_hard"]:
            pass_hard += 1
        if r["passes_lead_like"]:
            pass_lead += 1
        if r["source"] == "tep_fragment":
            by_site[r["site"]] += 1

    print(f"\n=== Summary ===", file=sys.stderr)
    print(f"Total unique canonical compounds: {len(inventory)}", file=sys.stderr)
    print(f"  By source: {dict(by_source)}", file=sys.stderr)
    print(f"  Passing Chordoma hard rule: {pass_hard}/{len(inventory)} ({100*pass_hard/len(inventory):.1f}%)", file=sys.stderr)
    print(f"  Passing lead-like soft rule: {pass_lead}/{len(inventory)} ({100*pass_lead/len(inventory):.1f}%)", file=sys.stderr)
    print(f"  TEP fragments by site: {dict(by_site)}", file=sys.stderr)

    return inventory, pairs


if __name__ == "__main__":
    main()
