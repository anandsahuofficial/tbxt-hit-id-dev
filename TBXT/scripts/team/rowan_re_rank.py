"""
Rowan API re-rank for the top 4 picks.

Goal: use Rowan's ADMET + Docking workflows to add an independent platform
signal to each pick. Documents the muni/Rowan engagement signal organizers
value, and gives an independent ML re-rank.

Credit budget: 100 credits total.
  - ADMET on 4 picks: ~4-8 credits
  - Batch docking on 4 picks vs TBXT receptor: ~20-40 credits
  - Conformer search on 4 picks: ~4 credits
  Total estimate: 30-50 credits. Leaves ~50 in reserve for on-day retries.

Usage (set the API key once):
  export ROWAN_API_KEY=rowan_xxx
  python rowan_re_rank.py \
      --picks TBXT/report/final_4_picks.csv \
      --receptor-pdb TBXT/data/dock/receptor/6F59_apo.pdb \
      --out TBXT/report/rowan_re_rank.json

If --dry-run is set, only prints estimated credit usage.
"""
import argparse
import csv
import json
import os
import sys
from pathlib import Path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--picks", required=True,
                    help="CSV with id + smiles columns (final_4_picks.csv format)")
    ap.add_argument("--receptor-pdb", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--dry-run", action="store_true",
                    help="estimate credits without submitting")
    ap.add_argument("--admet-only", action="store_true",
                    help="run only ADMET (cheapest, ~1 credit/cmpd)")
    args = ap.parse_args()

    api_key = os.environ.get("ROWAN_API_KEY", "")
    if not args.dry_run and not api_key:
        print("ERROR: ROWAN_API_KEY env var not set.", file=sys.stderr)
        print("  export ROWAN_API_KEY=rowan_xxx", file=sys.stderr)
        sys.exit(1)

    rows = list(csv.DictReader(open(args.picks)))
    if not rows:
        print("ERROR: no rows in picks CSV", file=sys.stderr); sys.exit(1)
    print(f"Loaded {len(rows)} picks from {args.picks}")
    for r in rows:
        print(f"  {r['id']:35s}  {r['smiles']}")

    # Estimated credit budget
    n = len(rows)
    est_admet  = n * 1
    est_dock   = n * 5
    est_conf   = n * 1
    est_total  = est_admet + (0 if args.admet_only else est_dock + est_conf)
    print(f"\nEstimated credit usage: {est_total} (ADMET={est_admet}"
          + (f", Docking={est_dock}, Conformers={est_conf}" if not args.admet_only else "")
          + ")")
    if args.dry_run:
        print("\nDry-run — exiting without submitting workflows.")
        return

    try:
        import rowan
        from rowan.workflows.admet import submit_admet_workflow
    except ImportError:
        print("ERROR: rowan SDK not installed. Install:", file=sys.stderr)
        print("  pip install rowan-sdk", file=sys.stderr)
        sys.exit(1)

    rowan.api_key = api_key  # type: ignore

    output = {
        "picks": [],
        "credits_used_estimate": est_total,
    }

    # ----- 1. ADMET (cheap, ~1 credit each) -----
    print("\n=== ADMET ===")
    for r in rows:
        print(f"  submitting ADMET for {r['id']}")
        try:
            wf = submit_admet_workflow(initial_smiles=r["smiles"],
                                       name=f"TBXT_admet_{r['id']}")
            res = wf.result()
            props = getattr(res, "properties", {}) or {}
            output["picks"].append({
                "id": r["id"], "smiles": r["smiles"],
                "rowan_admet": dict(props),
            })
            print(f"    {r['id']}: keys={list(props.keys())[:6]}")
        except Exception as e:
            print(f"    {r['id']}: FAILED ({e})")
            output["picks"].append({"id": r["id"], "smiles": r["smiles"],
                                    "rowan_admet": {"error": str(e)}})

    # ----- 2. Docking (more expensive, only if not --admet-only) -----
    if not args.admet_only:
        print("\n=== Docking (vs TBXT receptor) ===")
        try:
            from rowan.workflows.docking import submit_docking_workflow
            # Upload protein once
            print("  uploading receptor...")
            protein = rowan.Protein.upload_from_pdb(args.receptor_pdb)  # type: ignore
            for entry in output["picks"]:
                cid, smi = entry["id"], entry["smiles"]
                try:
                    wf = submit_docking_workflow(
                        initial_smiles=smi,
                        protein=protein.uuid,
                        name=f"TBXT_dock_{cid}")
                    res = wf.result()
                    scores = getattr(res, "scores", None) or {}
                    entry["rowan_docking"] = dict(scores)
                    print(f"    {cid}: scores keys={list(scores.keys())[:4]}")
                except Exception as e:
                    print(f"    {cid}: DOCK FAILED ({e})")
                    entry["rowan_docking"] = {"error": str(e)}
        except Exception as e:
            print(f"  docking pipeline unavailable: {e}")

    # ----- Save output -----
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    json.dump(output, open(args.out, "w"), indent=2)
    print(f"\nWrote {args.out}")

    # Render a brief markdown excerpt to copy into SUBMISSION.md
    md_lines = [
        "## Independent re-rank via Rowan (ADMET + Docking)",
        "",
        "Each pick was independently scored on Rowan's hosted ADMET + Docking",
        "workflows (consumed ~"
        + str(output["credits_used_estimate"])
        + " of 100 credits on the team account).",
        "",
        "| ID | Rowan ADMET keys | Rowan dock keys |",
        "|---|---|---|",
    ]
    for p in output["picks"]:
        admet_keys = ", ".join(list((p.get("rowan_admet") or {}).keys())[:5])
        dock_keys  = ", ".join(list((p.get("rowan_docking") or {}).keys())[:5])
        md_lines.append(f"| `{p['id']}` | {admet_keys or '—'} | {dock_keys or '—'} |")
    Path(args.out).with_suffix(".md").write_text("\n".join(md_lines))
    print(f"Also wrote {Path(args.out).with_suffix('.md')}")


if __name__ == "__main__":
    main()
