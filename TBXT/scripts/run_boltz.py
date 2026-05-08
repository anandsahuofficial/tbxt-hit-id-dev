"""
Boltz-2 co-folding for TBXT G177D + ligand pairs.

Input: SMILES CSV with columns id, smiles
Output:
  data/boltz/<id>.yaml          — Boltz input
  data/boltz/runs/<id>/         — co-folded structure(s) + confidence + affinity
  data/boltz/boltz_summary.csv  — per-compound: pLDDT, ipTM, predicted affinity, etc.
"""
import argparse
import csv
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

DOCK = Path(__file__).resolve().parents[1] / "data/dock"
BOLTZ_OUT = Path(__file__).resolve().parents[1] / "data/boltz"
BOLTZ_OUT.mkdir(exist_ok=True)
(BOLTZ_OUT / "yaml").mkdir(exist_ok=True)
(BOLTZ_OUT / "runs").mkdir(exist_ok=True)

# TBXT G177D DBD — extracted directly from 6F59 chain A (PDB residues 41–224, 178 aa).
# Verified G→D at position 177.
TBXT_G177D_DBD = (
    "ELRVGLEESELWLRFKELTNEMIVTKNGRRMFPVLKVNVSGLDPNAMYSFLLDFVAADNHRWKYVNGEWVP"
    "QAPSCVYIHPDSPNFGAHWMKAPVSFSKVKLTNKLNGGGQIMLNSLHKYEPRIHIVRVGDPQRMITSHCFP"
    "ETQFIAVTAYQNEEITALKIKYNPFAKAFLDAKERS"
)

YAML_TEMPLATE = """version: 1
sequences:
  - protein:
      id: A
      sequence: {sequence}
      msa: empty
  - ligand:
      id: L
      smiles: '{smiles}'
properties:
  - affinity:
      binder: L
"""


def write_yaml(cid, smiles):
    yaml = YAML_TEMPLATE.format(sequence=TBXT_G177D_DBD, smiles=smiles)
    path = BOLTZ_OUT / "yaml" / f"{cid}.yaml"
    path.write_text(yaml)
    return path


def run_boltz(yaml_path, out_dir):
    cmd = [
        "boltz", "predict", str(yaml_path),
        "--out_dir", str(out_dir),
        "--accelerator", "gpu",
        "--devices", "1",
        "--diffusion_samples", "3",          # 3 diffusion samples per ligand (more = better but slower)
        "--recycling_steps", "3",
        "--sampling_steps", "200",
        "--output_format", "pdb",
        "--write_full_pae",
        "--seed", "42",
        "--override",
    ]
    print(f"  Running: {' '.join(cmd[:6])} ...")
    rc = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
    return rc


def parse_results(out_dir, cid):
    """Boltz writes results to <out_dir>/boltz_results_<cid>/predictions/<cid>/."""
    pred_dir = out_dir / f"boltz_results_{cid}" / "predictions" / cid
    if not pred_dir.exists(): return None
    info = {"cid": cid, "pred_dir": str(pred_dir)}

    # Average confidence across the diffusion samples
    conf_files = sorted(pred_dir.glob(f"confidence_{cid}_model_*.json"))
    confs = []
    for f in conf_files:
        try:
            confs.append(json.loads(f.read_text()))
        except Exception:
            pass
    if confs:
        # Take model_0 (top-ranked by Boltz)
        d = confs[0]
        info["pLDDT"] = round(d.get("complex_plddt", 0), 4)
        info["pTM"] = round(d.get("ptm", 0), 4)
        info["ipTM"] = round(d.get("iptm", 0), 4)
        info["confidence"] = round(d.get("confidence_score", 0), 4)
        info["lig_iptm"] = round(d.get("ligand_iptm", 0), 4)
        info["n_models"] = len(confs)
        # Best across models for ipTM
        info["ipTM_best"] = round(max(c.get("iptm", 0) for c in confs), 4)
        info["confidence_best"] = round(max(c.get("confidence_score", 0) for c in confs), 4)

    # Affinity: <cid>_affinity.json (one per ligand, single file)
    aff_file = pred_dir / f"affinity_{cid}.json"
    if aff_file.exists():
        try:
            d = json.loads(aff_file.read_text())
            # affinity_pred_value is log10(Kd in µM). Convert to Kd µM for readability.
            log_kd_uM = d.get("affinity_pred_value")
            if log_kd_uM is not None:
                info["affinity_log_kd_uM"] = round(log_kd_uM, 3)
                info["affinity_kd_uM"] = round(10 ** log_kd_uM, 3)
                info["affinity_pkd"] = round(6.0 - log_kd_uM, 3)  # pKd in M
            info["affinity_prob_binder"] = round(d.get("affinity_probability_binary", 0), 4)
        except Exception as e:
            info["affinity_err"] = str(e)

    info["n_pdbs"] = len(list(pred_dir.glob("*.pdb")))
    return info


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--smiles-csv", required=True)
    p.add_argument("--out-dir", default=str(BOLTZ_OUT / "runs"))
    p.add_argument("--limit", type=int, default=0)
    args = p.parse_args()

    rows = list(csv.DictReader(open(args.smiles_csv)))
    if args.limit: rows = rows[:args.limit]
    print(f"Co-folding {len(rows)} compounds with TBXT G177D ({len(TBXT_G177D_DBD)} aa)")

    out_root = Path(args.out_dir)
    summary = []
    for i, row in enumerate(rows, 1):
        cid = row["id"]
        smiles = row["smiles"]
        print(f"\n[{i}/{len(rows)}] {cid} : {smiles}")
        yaml_path = write_yaml(cid, smiles)
        out_dir = out_root / cid
        out_dir.mkdir(parents=True, exist_ok=True)

        t0 = time.time()
        rc = run_boltz(yaml_path, out_dir)
        elapsed = time.time() - t0
        if rc.returncode != 0:
            print(f"  FAIL ({elapsed:.0f}s):")
            print(f"  stderr: {rc.stderr[-500:]}")
            summary.append({"cid": cid, "status": "fail", "elapsed_s": round(elapsed, 1),
                            "err": rc.stderr[-500:]})
            continue

        info = parse_results(out_dir, Path(yaml_path).stem)
        if info is None:
            print(f"  No predictions parsed ({elapsed:.0f}s)")
            summary.append({"cid": cid, "status": "no_predictions", "elapsed_s": round(elapsed, 1)})
            continue
        info["status"] = "ok"
        info["elapsed_s"] = round(elapsed, 1)
        info["smiles"] = smiles
        print(f"  OK ({elapsed:.0f}s): pLDDT={info.get('pLDDT', 'NA')}, "
              f"ipTM={info.get('ipTM', 'NA')}, "
              f"affinity={info.get('affinity_kd_uM', 'NA')} µM, "
              f"prob_binder={info.get('affinity_prob_binder', 'NA')}")
        summary.append(info)

    cols = ["cid", "status", "smiles", "pLDDT", "pTM", "ipTM", "ipTM_best",
            "lig_iptm", "confidence", "confidence_best",
            "affinity_log_kd_uM", "affinity_kd_uM", "affinity_pkd",
            "affinity_prob_binder", "elapsed_s", "n_pdbs", "n_models", "pred_dir"]
    out_csv = BOLTZ_OUT / "boltz_summary.csv"
    with open(out_csv, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for r in summary:
            w.writerow({k: r.get(k, "") for k in cols})
    print(f"\nWrote {out_csv}")


if __name__ == "__main__":
    main()
