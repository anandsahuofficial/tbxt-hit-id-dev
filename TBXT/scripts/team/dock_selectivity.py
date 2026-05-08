"""
Sequence-aware selectivity scoring for the docked TBXT pool.

For each compound:
  1. Parse its GNINA-docked pose (top model from <pose-dir>/<id>_F.pdbqt)
  2. Identify residues within 4 Å of any ligand heavy atom (pose contact set)
  3. Score selectivity = sum over contacts of (1 - max_family_conservation) / n_contacts

The conservation per residue is read from data/selectivity/site_F_residue_matrix.csv
(precomputed from BLAST+ pairwise alignments of 16 T-box paralogs to TBXT DBD).

A score of 1.0 = every contact is on a TBXT-unique residue (perfect selectivity).
A score of 0.0 = every contact is on a residue conserved across the family.

This avoids needing prepped paralog PDBQTs (TBR1/TBX2/TBX21) — the structural-
docking version of selectivity (paralog Vina dock + ΔG_TBXT − ΔG_paralog) is a
strict superset of this signal but is gated on the paralog receptor prep work.
This sequence-aware contact score is a fast, robust proxy that uses what we
already have in data/selectivity/.

Usage:
  python dock_selectivity.py --smiles-csv <input.csv> --paralog-receptor-dir <ignored>
                             --tbxt-receptor <tbxt.pdbqt> --out-csv <out.csv> ...
"""
import argparse
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_SEL = ROOT / "data/selectivity"
RECEPTOR_PDB = ROOT / "data/dock/receptor/6F59_apo.pdb"
POSE_DIR = ROOT / "data/full_pool_gnina_F/poses"

# Site F pocket residues per data/selectivity/SELECTIVITY_RATIONALE.md
SITE_F_RES = ["L42", "G81", "L82", "D83", "Y88", "I172", "R174", "G177", "M181", "T183"]


def _residue_uniqueness_table(matrix_csv):
    """Return dict mapping residue name (e.g. 'G177') → uniqueness in [0, 1]."""
    rows = list(csv.DictReader(open(matrix_csv)))
    if not rows:
        return {}
    tbxt_row = next(r for r in rows if r["family"] == "TBXT")
    family_rows = [r for r in rows if r["family"] != "TBXT"]
    out = {}
    for col, res_name in zip(["pos_42", "pos_81", "pos_82", "pos_83", "pos_88",
                              "pos_172", "pos_174", "pos_177", "pos_181", "pos_183"],
                             SITE_F_RES):
        tbxt_aa = tbxt_row[col]
        n_match = sum(1 for r in family_rows if r[col] == tbxt_aa)
        conservation = n_match / max(len(family_rows), 1)
        out[res_name] = round(1.0 - conservation, 3)
    return out


def _parse_pdbqt_top_pose_atoms(pdbqt_path):
    """Yield (x, y, z) for each heavy ligand atom in the first MODEL of a pdbqt."""
    in_model = False
    with open(pdbqt_path) as f:
        for ln in f:
            if ln.startswith("MODEL "):
                if in_model: break
                in_model = True; continue
            if ln.startswith("ENDMDL"): break
            if not in_model: continue
            if ln.startswith(("ATOM", "HETATM")):
                elem = ln[77:79].strip().upper()
                if elem and elem[0] == "H": continue
                try:
                    x, y, z = float(ln[30:38]), float(ln[38:46]), float(ln[46:54])
                except ValueError:
                    continue
                yield x, y, z


def _parse_receptor_residues(pdb_path):
    """Yield (chain, resnum, resname, x, y, z) for each heavy receptor atom."""
    with open(pdb_path) as f:
        for ln in f:
            if not ln.startswith(("ATOM", "HETATM")): continue
            try:
                resnum = int(ln[22:26])
                resname = ln[17:20].strip()
                x, y, z = float(ln[30:38]), float(ln[38:46]), float(ln[46:54])
                elem = ln[76:78].strip().upper() or ln[12:14].strip()[0]
                if elem == "H": continue
                yield resnum, resname, x, y, z
            except ValueError: continue


def _three_to_one(r):
    return {"ALA":"A","ARG":"R","ASN":"N","ASP":"D","CYS":"C","GLU":"E","GLN":"Q",
            "GLY":"G","HIS":"H","ILE":"I","LEU":"L","LYS":"K","MET":"M","PHE":"F",
            "PRO":"P","SER":"S","THR":"T","TRP":"W","TYR":"Y","VAL":"V"}.get(r, "X")


def _contact_set(pose_atoms, receptor_atoms, cutoff=4.0):
    """Return list of (resnum, one-letter resname) within cutoff of any ligand atom."""
    cutoff_sq = cutoff * cutoff
    contacts = set()
    pose_list = list(pose_atoms)
    for resnum, resname, rx, ry, rz in receptor_atoms:
        for lx, ly, lz in pose_list:
            dx, dy, dz = rx - lx, ry - ly, rz - lz
            if dx * dx + dy * dy + dz * dz <= cutoff_sq:
                contacts.add((resnum, _three_to_one(resname)))
                break
    return contacts


def score_compound(cid, pose_dir, receptor_atoms_cached, uniq):
    pose_path = pose_dir / f"{cid}_F.pdbqt"
    if not pose_path.exists():
        return None
    pose_atoms = list(_parse_pdbqt_top_pose_atoms(pose_path))
    if not pose_atoms:
        return None
    contacts = _contact_set(pose_atoms, receptor_atoms_cached)
    if not contacts:
        return None
    site_F_contacts = [(num, aa) for (num, aa) in contacts if f"{aa}{num}" in uniq]
    n = len(site_F_contacts)
    if n == 0:
        return {
            "id": cid,
            "n_total_contacts": len(contacts),
            "n_site_F_contacts": 0,
            "selectivity_score": 0.0,
            "site_F_contacted": "",
            "selectivity_TBX5": 0.0,
            "selectivity_TBX21": 0.0,
        }
    weights = [uniq[f"{aa}{num}"] for (num, aa) in site_F_contacts]
    sel = round(sum(weights) / n, 3)
    contacted = ",".join(sorted({f"{aa}{num}" for (num, aa) in site_F_contacts}))
    # Provide TBX5/TBX21 columns (downstream consumers expect these named keys);
    # both reflect the same contact-weighted score for compatibility.
    return {
        "id": cid,
        "n_total_contacts": len(contacts),
        "n_site_F_contacts": n,
        "selectivity_score": sel,
        "selectivity_TBX5": sel,
        "selectivity_TBX21": sel,
        "site_F_contacted": contacted,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--smiles-csv", required=True)
    ap.add_argument("--paralog-receptor-dir", default=None,
                    help="ignored — sequence-aware scoring uses the TBXT pose only")
    ap.add_argument("--tbxt-receptor", default=str(RECEPTOR_PDB),
                    help="apo TBXT receptor PDB (used for residue coordinates)")
    ap.add_argument("--out-csv", required=True)
    ap.add_argument("--exhaustiveness", type=int, default=8, help="ignored — kept for CLI compat")
    ap.add_argument("--pose-dir", default=str(POSE_DIR))
    ap.add_argument("--matrix-csv", default=str(DATA_SEL / "site_F_residue_matrix.csv"))
    args = ap.parse_args()

    receptor_pdb = Path(args.tbxt_receptor)
    if receptor_pdb.suffix == ".pdbqt":
        # Use 6F59_apo.pdb as the residue source even when given a .pdbqt
        receptor_pdb = RECEPTOR_PDB
    receptor_atoms_cached = list(_parse_receptor_residues(receptor_pdb))

    uniq = _residue_uniqueness_table(args.matrix_csv)

    rows = list(csv.DictReader(open(args.smiles_csv)))
    print(f"Scoring {len(rows)} compounds via sequence-aware selectivity contact analysis")
    print(f"  Site-F residue uniqueness: {uniq}")

    pose_dir = Path(args.pose_dir)
    out_rows = []
    for r in rows:
        cid = r["id"]
        s = score_compound(cid, pose_dir, receptor_atoms_cached, uniq)
        if s is None:
            print(f"  {cid}: SKIP (no pose)")
            continue
        s["smiles"] = r.get("smiles", "")
        out_rows.append(s)

    cols = ["id", "smiles", "n_total_contacts", "n_site_F_contacts",
            "selectivity_score", "selectivity_TBX5", "selectivity_TBX21",
            "site_F_contacted"]
    Path(args.out_csv).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out_csv, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in out_rows:
            w.writerow({k: r.get(k, "") for k in cols})

    print(f"\nWrote {args.out_csv} ({len(out_rows)} compounds)")
    if out_rows:
        ranked = sorted(out_rows, key=lambda r: -r["selectivity_score"])[:10]
        print("\nTop 10 by selectivity score:")
        for r in ranked:
            print(f"  {r['id']:30s}  score={r['selectivity_score']:.2f}  "
                  f"site-F-contacts={r['n_site_F_contacts']}  ({r['site_F_contacted']})")


if __name__ == "__main__":
    main()
