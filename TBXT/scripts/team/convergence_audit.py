"""
Convergence audit: cross-compare top picks across variants.

Reads each variant's top-50 list from report/variants/<VARIANT_NAME>/*.json
and produces:
  - report/convergence_summary.csv: per-compound row with rank-in-variant for
    each variant + a "robustness score" (fraction of variants where it's top-N)
  - prints the "robust set" (compounds in top-4 of >= 4 of 5 variants)

Use this as the single defensible argument for judges:
    "Our 4 picks survive across N independent methodological perturbations."
"""
import argparse
import csv
import json
from pathlib import Path
from collections import defaultdict


def load_variant_top(variant_dir, top_n=50):
    """Load top-N IDs from any *.json in this variant's report dir."""
    top_ids = []
    if not variant_dir.exists():
        return top_ids
    for jf in sorted(variant_dir.glob("*.json")):
        try:
            d = json.load(open(jf))
        except Exception:
            continue
        ids = d.get("metrics", {}).get("top_50_ids") \
              or [r["id"] for r in d.get("metrics", {}).get("top_50_results", [])]
        if ids:
            top_ids = list(ids[:top_n])
            break
    return top_ids


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--variants-root", default="TBXT/report/variants")
    ap.add_argument("--baseline", default="TBXT/report/task10_trial1.json",
                    help="baseline top picks for comparison")
    ap.add_argument("--top-n", type=int, default=50)
    ap.add_argument("--robust-cutoff", type=int, default=4,
                    help="compound is 'robust' if in top-4 of >= N variants")
    ap.add_argument("--out", default="TBXT/report/convergence_summary.csv")
    args = ap.parse_args()

    root = Path(args.variants_root)

    # Baseline (current pipeline) top
    baseline_top = []
    if Path(args.baseline).exists():
        try:
            d = json.load(open(args.baseline))
            baseline_top = d.get("metrics", {}).get("top_50_ids", [])[:args.top_n]
        except Exception:
            pass

    # Discover variants
    variants = {}
    if root.exists():
        for vd in sorted(root.iterdir()):
            if vd.is_dir():
                top = load_variant_top(vd, args.top_n)
                if top:
                    variants[vd.name] = top
    if baseline_top:
        variants = {"baseline": baseline_top, **variants}

    if not variants:
        print(f"No variant top-N lists found at {root}")
        return

    print(f"Loaded {len(variants)} variants:")
    for name, top in variants.items():
        print(f"  {name:35s} top-{len(top)}")

    # Score each compound across variants
    appearances = defaultdict(dict)  # cid -> {variant_name: rank}
    top4_counts = defaultdict(int)
    for vname, top in variants.items():
        for i, cid in enumerate(top, 1):
            appearances[cid][vname] = i
            if i <= 4:
                top4_counts[cid] += 1

    # Sort by top-4 count descending, then by mean rank
    def sort_key(item):
        cid, ranks = item
        mean_rank = sum(ranks.values()) / max(len(ranks), 1)
        return (-top4_counts[cid], mean_rank)

    sorted_appearances = sorted(appearances.items(), key=sort_key)

    cols = ["id", "n_variants_present", "n_top4", "mean_rank"] + list(variants.keys())
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    with open(args.out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for cid, ranks in sorted_appearances:
            row = [cid, len(ranks), top4_counts[cid],
                   round(sum(ranks.values()) / len(ranks), 1)]
            for vname in variants.keys():
                row.append(ranks.get(vname, ""))
            w.writerow(row)
    print(f"\nWrote {args.out}")

    # Robust set
    robust = [cid for cid, n in top4_counts.items() if n >= args.robust_cutoff]
    print(f"\n=== Robust picks (top-4 in ≥ {args.robust_cutoff} of {len(variants)} variants) ===")
    if not robust:
        print("  NONE — picks shift across variants; review composite formula")
    for cid in robust[:20]:
        ranks_str = ", ".join(f"{v}:{appearances[cid].get(v, '–')}"
                              for v in variants.keys())
        print(f"  {cid:35s}  top-4 in {top4_counts[cid]}/{len(variants)} variants  ({ranks_str})")


if __name__ == "__main__":
    main()
