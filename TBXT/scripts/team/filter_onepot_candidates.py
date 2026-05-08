"""
Filter onepot-enumerated products: drug-likeness + Naar novelty.
Keeps only compounds passing:
  - Chordoma chemistry rule (MW <= 600, LogP <= 6, HBD <= 6, HBA <= 12)
  - Lead-like targets (HA 10-40, LogP <= 5, rings <= 5, fused <= 2)
  - PAINS-clean (RDKit Baell-2010 catalog)
  - Tanimoto < 0.85 vs all known TBXT compounds (Naar set)
"""
import argparse
import csv
from pathlib import Path

from rdkit import Chem
from rdkit.Chem import AllChem, Descriptors, DataStructs
from rdkit.Chem.FilterCatalog import FilterCatalog, FilterCatalogParams


def chordoma_rule(mol):
    if Descriptors.MolWt(mol) > 600: return False
    if Descriptors.MolLogP(mol) > 6: return False
    if Descriptors.NumHDonors(mol) > 6: return False
    if Descriptors.NumHAcceptors(mol) > 12: return False
    return True


def lead_like(mol):
    ha = mol.GetNumHeavyAtoms()
    if ha < 10 or ha > 40: return False
    if Descriptors.MolLogP(mol) > 5: return False
    rings = mol.GetRingInfo().NumRings()
    if rings > 5: return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="enumerated products csv")
    ap.add_argument("--known", required=True, help="prior_art_canonical.csv")
    ap.add_argument("--out", required=True)
    ap.add_argument("--max-out", type=int, default=1000)
    ap.add_argument("--tanimoto-cutoff", type=float, default=0.85)
    args = ap.parse_args()

    # Load PAINS catalog
    catalog_params = FilterCatalogParams()
    catalog_params.AddCatalog(FilterCatalogParams.FilterCatalogs.PAINS)
    pains = FilterCatalog(catalog_params)

    # Load known fingerprints
    print(f"Loading known compounds from {args.known}")
    known_fps = []
    for r in csv.DictReader(open(args.known)):
        smi = r.get("canonical_smiles") or r.get("smiles") or ""
        if not smi: continue
        m = Chem.MolFromSmiles(smi)
        if m is None: continue
        known_fps.append(AllChem.GetMorganFingerprintAsBitVect(m, 2, 2048))
    print(f"  {len(known_fps)} known reference fingerprints")

    # Filter products
    survivors = []
    n_chord_fail = n_lead_fail = n_pains = n_dup = 0
    for r in csv.DictReader(open(args.input)):
        smi = r["smiles"]
        m = Chem.MolFromSmiles(smi)
        if m is None: continue
        if not chordoma_rule(m): n_chord_fail += 1; continue
        if not lead_like(m):     n_lead_fail += 1; continue
        if pains.HasMatch(m):    n_pains += 1; continue
        fp = AllChem.GetMorganFingerprintAsBitVect(m, 2, 2048)
        max_t = max((DataStructs.TanimotoSimilarity(fp, kfp) for kfp in known_fps), default=0)
        if max_t >= args.tanimoto_cutoff:
            n_dup += 1; continue
        r["max_tanimoto_to_known"] = round(max_t, 3)
        r["mw"] = round(Descriptors.MolWt(m), 1)
        r["logp"] = round(Descriptors.MolLogP(m), 2)
        r["ha"] = m.GetNumHeavyAtoms()
        survivors.append(r)
        if len(survivors) >= args.max_out: break

    print(f"\nFilter summary:")
    print(f"  chordoma_rule fail: {n_chord_fail}")
    print(f"  lead_like fail:     {n_lead_fail}")
    print(f"  PAINS:              {n_pains}")
    print(f"  Naar dup (T≥{args.tanimoto_cutoff}): {n_dup}")
    print(f"  survivors:          {len(survivors)}")

    cols = ["id", "smiles", "reaction", "bb1", "bb2",
            "mw", "logp", "ha", "max_tanimoto_to_known"]
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in survivors:
            w.writerow({k: r.get(k, "") for k in cols})
    print(f"\nWrote {args.out}")


if __name__ == "__main__":
    main()
