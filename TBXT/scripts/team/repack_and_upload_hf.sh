#!/usr/bin/env bash
# Repack the tbxt conda env + (optionally) the data supplement, refresh
# CHECKSUMS.sha256, and atomically push everything to the Hugging Face
# dataset repo via git+LFS over SSH.
#
# Auth model: SSH to hf.co (same model as GitHub). No token required.
# One-time setup:  bash scripts/team/setup_hf_ssh_once.sh
#
# Usage:
#   bash scripts/team/repack_and_upload_hf.sh                # repack env + push everything
#   bash scripts/team/repack_and_upload_hf.sh --supplement   # also rebuild the pose supplement
#   bash scripts/team/repack_and_upload_hf.sh --no-env       # skip env repack, refresh CHECKSUMS + push
#
# Override the target repo (default = anandsahuofficial/tbxt-hackathon-bundles):
#   HF_USER=<user> HF_REPO=<repo> bash scripts/team/repack_and_upload_hf.sh

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
HF_SSH_REMOTE="git@hf.co:datasets/${HF_USER}/${HF_REPO}"

# Resolve TBXT root regardless of where the script is invoked from
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT_ROOT="$(cd "$HERE/../.." && pwd)"
HF_LOCAL_CLONE="${HF_LOCAL_CLONE:-$TBXT_ROOT/tbxt_hf_local}"

log()  { printf "\n[\033[36mrepack\033[0m %s] %s\n" "$(date +%H:%M:%S)" "$*"; }
err()  { printf "\n[\033[31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

# ─── Pre-flight ────────────────────────────────────────────────────────────
command -v git >/dev/null \
  || err "git not found"
command -v git-lfs >/dev/null \
  || err "git-lfs not found. Install (Debian/WSL): sudo apt-get install -y git-lfs"
if [ "$REBUILD_ENV" = "true" ]; then
  if ! command -v conda-pack >/dev/null; then
    # Try sourcing base conda; conda-pack is typically there
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
      source "$HOME/miniconda3/etc/profile.d/conda.sh" 2>/dev/null || true
      conda activate base 2>/dev/null || true
    fi
  fi
  command -v conda-pack >/dev/null \
    || err "conda-pack not found. Install: conda install -n base -c conda-forge conda-pack  (or run with --no-env if you don't need to repack)"
fi

# ─── Step 0: ensure the HF repo is cloned locally via SSH ───────────────────
if [ ! -d "$HF_LOCAL_CLONE/.git" ]; then
  log "Cloning $HF_SSH_REMOTE -> $HF_LOCAL_CLONE"
  git clone "$HF_SSH_REMOTE" "$HF_LOCAL_CLONE" \
    || err "Clone failed. Run 'bash scripts/team/setup_hf_ssh_once.sh' to configure SSH access."
else
  log "Pulling latest from HF (in case of upstream commits)..."
  ( cd "$HF_LOCAL_CLONE" && git pull --rebase --quiet ) \
    || err "Pull failed in $HF_LOCAL_CLONE — resolve manually then re-run"
fi

# Ensure git-lfs is initialized + tracks *.tar.gz
( cd "$HF_LOCAL_CLONE" && {
    git lfs install --local --skip-smudge >/dev/null
    if [ ! -f .gitattributes ] || ! grep -q "\*\.tar\.gz" .gitattributes 2>/dev/null; then
      git lfs track "*.tar.gz"
      git add .gitattributes
      git commit -m "Track *.tar.gz via git-lfs" --quiet || true
    fi
} )

# HF caps single LFS files at 5 GB unless the repo is configured for large
# files via 'hf lfs-enable-largefiles'. This is a local git config change
# (multipart transfer agent), no network/auth. Idempotent.
if ! grep -q "lfs-multipart-upload" "$HF_LOCAL_CLONE/.git/config" 2>/dev/null; then
  if command -v hf >/dev/null; then
    log "Enabling HF large-file (>5 GB) support on the local clone"
    hf lfs-enable-largefiles "$HF_LOCAL_CLONE" >/dev/null
  else
    log "WARN: 'hf' CLI not found. Files >5 GB will fail to push."
    log "      Install once:  pip install huggingface_hub"
    log "      Then re-run this script."
  fi
fi

# Stage existing bundles from the legacy local cache (do this BEFORE the env
# check so --no-env can find a previously-staged or legacy-cache copy).
LEGACY_CACHE="$TBXT_ROOT/tbxt_drive_local"
for f in tbxt_env.tar.gz tbxt_data_bundle.tar.gz tbxt_data_supplement.tar.gz; do
  if [ ! -f "$HF_LOCAL_CLONE/$f" ] && [ -f "$LEGACY_CACHE/$f" ]; then
    log "Staging $f from legacy cache ($(du -h "$LEGACY_CACHE/$f" | cut -f1))"
    cp "$LEGACY_CACHE/$f" "$HF_LOCAL_CLONE/$f"
  fi
done

# ─── Step 1: repack the tbxt env ───────────────────────────────────────────
if [ "$REBUILD_ENV" = "true" ]; then
  log "Repacking tbxt env -> $HF_LOCAL_CLONE/tbxt_env.tar.gz (~5-10 min)"
  source "$HOME/miniconda3/etc/profile.d/conda.sh"
  conda activate base
  conda-pack -n tbxt -o "$HF_LOCAL_CLONE/tbxt_env.tar.gz" --force \
    --ignore-missing-files --ignore-editable-packages
  log "  ✓ repacked $(du -h "$HF_LOCAL_CLONE/tbxt_env.tar.gz" | cut -f1)"
else
  log "Skipping env repack (--no-env)"
  [ -f "$HF_LOCAL_CLONE/tbxt_env.tar.gz" ] \
    || err "No existing env tarball at $HF_LOCAL_CLONE/tbxt_env.tar.gz; remove --no-env or stage one first"
fi

# ─── Step 2: rebuild supplement (poses + ligands) if requested ─────────────
if [ "$REBUILD_SUPPLEMENT" = "true" ]; then
  log "Rebuilding pose supplement -> $HF_LOCAL_CLONE/tbxt_data_supplement.tar.gz"
  ( cd "$TBXT_ROOT" && tar -czf "$HF_LOCAL_CLONE/tbxt_data_supplement.tar.gz" \
      data/full_pool_gnina_F/poses data/full_pool_gnina_F/ligands )
  log "  ✓ supplement: $(du -h "$HF_LOCAL_CLONE/tbxt_data_supplement.tar.gz" | cut -f1)"
fi

# ─── Step 3: refresh CHECKSUMS.sha256 ──────────────────────────────────────
log "Refreshing CHECKSUMS.sha256 in clone"
( cd "$HF_LOCAL_CLONE" && {
    : > CHECKSUMS.sha256
    [ -f tbxt_data_supplement.tar.gz ] && sha256sum tbxt_data_supplement.tar.gz >> CHECKSUMS.sha256
    [ -f tbxt_env.tar.gz ]              && sha256sum tbxt_env.tar.gz              >> CHECKSUMS.sha256
    [ -f tbxt_data_bundle.tar.gz ]      && sha256sum tbxt_data_bundle.tar.gz      >> CHECKSUMS.sha256
} )
cat "$HF_LOCAL_CLONE/CHECKSUMS.sha256"

# ─── Step 4: commit + push (atomic git LFS over SSH) ───────────────────────
log "Committing and pushing to HF (LFS auto-handles large files)"
( cd "$HF_LOCAL_CLONE" && {
    git add -A
    if git diff --cached --quiet; then
      log "  no changes to push"
    else
      git commit -m "Refresh bundles ($(date -u +%Y-%m-%dT%H:%MZ))"
      git push
    fi
} )

cat <<EOF

================================================================================
  ✅ Bundles pushed to HF dataset: ${HF_USER}/${HF_REPO}
  Local clone:  $HF_LOCAL_CLONE

  Members can pull with:
      bash setup_hf.sh --update
================================================================================
EOF
