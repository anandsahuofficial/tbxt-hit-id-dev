#!/usr/bin/env bash
# Repack the tbxt conda env + (optionally) the data supplement, refresh
# CHECKSUMS.sha256, and atomically push everything to the Hugging Face dataset
# repo used by setup_hf.sh.
#
# Usage:
#   bash scripts/team/repack_and_upload_hf.sh                # repack env + push everything
#   bash scripts/team/repack_and_upload_hf.sh --supplement   # also rebuild supplement
#   bash scripts/team/repack_and_upload_hf.sh --no-env       # skip env repack, just refresh CHECKSUMS + upload
#
# Requirements:
#   - conda-pack       (one-time:  conda install -n base -c conda-forge conda-pack)
#   - hf CLI           (one-time:  pip install -U huggingface_hub)
#   - HF auth          (one-time:  hf auth login   ← paste a write token)
#
# Override the target repo (default = anandsahuofficial/tbxt-hackathon-bundles):
#   HF_USER=someuser HF_REPO=my-bundles bash scripts/team/repack_and_upload_hf.sh

set -euo pipefail

REBUILD_ENV="true"
REBUILD_SUPPLEMENT="false"
for arg in "$@"; do
  case "$arg" in
    --no-env)        REBUILD_ENV="false" ;;
    --supplement)    REBUILD_SUPPLEMENT="true" ;;
    --help)          echo "Usage: $0 [--no-env] [--supplement]"; exit 0 ;;
    *)               echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

HF_USER="${HF_USER:-anandsahuofficial}"
HF_REPO="${HF_REPO:-tbxt-hackathon-bundles}"

# Resolve TBXT root regardless of where the script is invoked from
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT_ROOT="$(cd "$HERE/../.." && pwd)"
DRIVE_DIR="$TBXT_ROOT/tbxt_drive_local"   # we keep using this dir name; "drive_local" is just historical
mkdir -p "$DRIVE_DIR"

log()  { printf "\n[\033[36mrepack\033[0m %s] %s\n" "$(date +%H:%M:%S)" "$*"; }
err()  { printf "\n[\033[31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

# ─── Pre-flight ────────────────────────────────────────────────────────────
command -v conda-pack >/dev/null \
  || err "conda-pack not found. Install: conda install -n base -c conda-forge conda-pack"
if ! command -v hf >/dev/null; then
  if command -v huggingface-cli >/dev/null; then
    HF_BIN="huggingface-cli"
  else
    err "hf CLI not found. Install: pip install -U huggingface_hub"
  fi
else
  HF_BIN="hf"
fi

# ─── Step 1: repack the tbxt env ───────────────────────────────────────────
if [ "$REBUILD_ENV" = "true" ]; then
  log "Repacking tbxt env -> $DRIVE_DIR/tbxt_env.tar.gz (this takes ~5-10 min)"
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
  conda activate base
  conda-pack -n tbxt -o "$DRIVE_DIR/tbxt_env.tar.gz" --force \
    --ignore-missing-files --ignore-editable-packages
  log "  ✓ repacked $(du -h "$DRIVE_DIR/tbxt_env.tar.gz" | cut -f1)"
else
  log "Skipping env repack (--no-env)"
  [ -f "$DRIVE_DIR/tbxt_env.tar.gz" ] || err "No existing env tarball at $DRIVE_DIR/tbxt_env.tar.gz"
fi

# ─── Step 2: rebuild supplement (poses + ligands) if requested ─────────────
if [ "$REBUILD_SUPPLEMENT" = "true" ]; then
  log "Rebuilding pose supplement -> $DRIVE_DIR/tbxt_data_supplement.tar.gz"
  ( cd "$TBXT_ROOT" && tar -czf "$DRIVE_DIR/tbxt_data_supplement.tar.gz" \
      data/full_pool_gnina_F/poses data/full_pool_gnina_F/ligands )
  log "  ✓ supplement: $(du -h "$DRIVE_DIR/tbxt_data_supplement.tar.gz" | cut -f1)"
fi

# ─── Step 3: refresh CHECKSUMS.sha256 ──────────────────────────────────────
log "Refreshing CHECKSUMS.sha256"
( cd "$DRIVE_DIR" && {
    : > CHECKSUMS.sha256
    [ -f tbxt_data_supplement.tar.gz ] && sha256sum tbxt_data_supplement.tar.gz >> CHECKSUMS.sha256
    [ -f tbxt_env.tar.gz ]              && sha256sum tbxt_env.tar.gz              >> CHECKSUMS.sha256
    [ -f tbxt_data_bundle.tar.gz ]      && sha256sum tbxt_data_bundle.tar.gz      >> CHECKSUMS.sha256
} )
cat "$DRIVE_DIR/CHECKSUMS.sha256"

# ─── Step 4: upload everything to HF in one atomic commit ──────────────────
log "Uploading to ${HF_USER}/${HF_REPO}  (atomic; resumable)"
$HF_BIN upload "${HF_USER}/${HF_REPO}" "$DRIVE_DIR" . \
  --repo-type dataset \
  --include="*.tar.gz" --include="CHECKSUMS.sha256" --include="MANIFEST_data_bundle.txt" \
  --commit-message "Refresh bundles ($(date -u +%Y-%m-%dT%H:%MZ))"

log "Done. Members can pull the new bundles with:"
echo "    bash setup_hf.sh --update"
