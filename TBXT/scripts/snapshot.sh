#!/usr/bin/env bash
# Snapshot the analysis state for reproducibility / disaster-recovery on the day.
# Run before May 9 doors open AND right before lock-down at 6:00 pm.
set -euo pipefail

TBXT="/home/anandsahu/Hackathon/TBXT"
TS="${1:-T-0}"  # default tag; pass a custom tag like "post-onday-3pm" to override
SNAP_DIR="$TBXT/data/snapshots/$TS"

if [ -d "$SNAP_DIR" ]; then
    echo "Snapshot $TS already exists. Use a different tag or rm -rf $SNAP_DIR" >&2
    exit 1
fi

mkdir -p "$SNAP_DIR"
echo "Snapshotting to $SNAP_DIR..."

# Copy: scripts (always small), key analysis outputs.
# Skip: bin/gnina (2 GB), receptor PDBs (regeneratable), naar/ raw XLSX (regeneratable from Zenodo).
cp -r "$TBXT/scripts" "$SNAP_DIR/scripts"
cp -r "$TBXT/data/qsar" "$SNAP_DIR/qsar"
cp -r "$TBXT/data/analogs" "$SNAP_DIR/analogs"
cp -r "$TBXT/data/generative" "$SNAP_DIR/generative"
cp -r "$TBXT/data/selectivity" "$SNAP_DIR/selectivity"
cp -r "$TBXT/data/tep" "$SNAP_DIR/tep"
cp -r "$TBXT/data/dock" "$SNAP_DIR/dock"  # includes ensemble + validation + grids
cp -r "$TBXT/data/boltz" "$SNAP_DIR/boltz" 2>/dev/null || true
cp -r "$TBXT/data/full_pool_gnina_F" "$SNAP_DIR/full_pool_gnina_F" 2>/dev/null || true
cp -r "$TBXT/data/tier_a" "$SNAP_DIR/tier_a" 2>/dev/null || true
cp -r "$TBXT/data/slides" "$SNAP_DIR/slides" 2>/dev/null || true
cp "$TBXT/data/full_pool_input.csv" "$SNAP_DIR/" 2>/dev/null || true
cp "$TBXT"/{PROGRESS.md,STRATEGIES.md,START.md,organizer_questions.md} "$SNAP_DIR/"
cp "$TBXT/resources/ABOUT.md" "$SNAP_DIR/ABOUT.md"

# Strip the heaviest noise: GNINA pose files (regenerable; one per dock)
rm -rf "$SNAP_DIR/dock/validation_F_gnina/poses" \
       "$SNAP_DIR/dock/validation_A_gnina/poses" \
       "$SNAP_DIR/full_pool_gnina_F/poses" 2>/dev/null || true
rm -rf "$SNAP_DIR/dock/validation_F/poses" \
       "$SNAP_DIR/dock/validation_A/poses" 2>/dev/null || true
rm -rf "$SNAP_DIR/dock/ensemble_F"/*/poses \
       "$SNAP_DIR/analogs/ensemble_smoke_F"/*/poses 2>/dev/null || true

# Generate checksum manifest
echo "  Computing manifest..."
(cd "$SNAP_DIR" && find . -type f -not -path '*/__pycache__/*' \
    -exec sha256sum {} \;) > "$SNAP_DIR/MANIFEST.sha256"

# Record env state
echo "  Recording env..."
{
    echo "# Conda env: tbxt"
    /home/anandsahu/miniconda3/envs/tbxt/bin/conda list -n tbxt 2>&1
    echo
    echo "# Python pip freeze (combined)"
    /home/anandsahu/miniconda3/envs/tbxt/bin/pip freeze 2>&1
} > "$SNAP_DIR/env.txt"

# Report
SIZE=$(du -sh "$SNAP_DIR" | cut -f1)
NFILES=$(find "$SNAP_DIR" -type f | wc -l)
echo
echo "Snapshot complete: $SNAP_DIR"
echo "  Size: $SIZE"
echo "  Files: $NFILES"
echo "  MANIFEST: $SNAP_DIR/MANIFEST.sha256"
