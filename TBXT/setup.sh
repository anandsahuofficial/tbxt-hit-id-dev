#!/usr/bin/env bash
# TBXT Hackathon — one-shot setup script for team members.
#
# Usage:
#   bash setup.sh                       # default: install at $HOME/Hackathon/TBXT
#   bash setup.sh /opt/work/Hackathon   # custom: install at /opt/work/Hackathon/TBXT
#   TBXT_ROOT=/data/h/Hackathon bash setup.sh
#
# After this finishes:
#   1. The conda env tbxt is unpacked at ~/miniconda3/envs/tbxt
#   2. Project root is at $TBXT_ROOT/Hackathon/TBXT (or wherever you chose)
#   3. The team Drive bundle is unpacked into the project
#   4. tests/smoke_test.py validates the whole pipeline runs end-to-end
#
# Requirements (commonly available on Linux): bash, wget OR curl, tar, sha256sum, git
# If miniconda is not installed, this script will install it.

set -euo pipefail

# ─── Configuration ─────────────────────────────────────────────────────────
TBXT_ROOT="${TBXT_ROOT:-${1:-$HOME}}"
CLONE_DIR="$TBXT_ROOT/Hackathon"
PROJECT_DIR="$CLONE_DIR/TBXT"
CONDA_DIR="${CONDA_DIR:-$HOME/miniconda3}"
ENV_NAME="tbxt"
ENV_DIR="$CONDA_DIR/envs/$ENV_NAME"
DOWNLOAD_CACHE="${TBXT_DOWNLOAD_CACHE:-$HOME/.tbxt_drive_cache}"

# Drive file IDs (public — anyone-with-link)
ID_ENV="1G88JAl11RxbzrA_YJinC-ihF556oWYOo"
ID_DATA="1bIt-i083BhIqO83vGx2mHjFokUGhedQG"
ID_CHECKSUMS="12K_DjcSEeaGojCHCEgMxYGQByIx48mQY"
ID_MANIFEST="1Ob6cBitmqw3XcYIXnT1r7204niNUa5F8"
REPO_URL="git@github.com:anandsahuofficial/Hackathon.git"
REPO_HTTPS="https://github.com/anandsahuofficial/Hackathon.git"
BRANCH="TBXT"

# ─── Helpers ────────────────────────────────────────────────────────────────
log() { printf "\n[\033[36msetup\033[0m %s] %s\n" "$(date +%H:%M:%S)" "$*"; }
err() { printf "\n[\033[31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

drive_dl() {
  # Downloads a Drive file by ID to a local path. Resumable. Idempotent if SHA matches.
  local id="$1"; local out="$2"; local expected_sha="${3:-}"
  if [ -f "$out" ] && [ -n "$expected_sha" ]; then
    local cur_sha
    cur_sha=$(sha256sum "$out" | awk '{print $1}')
    if [ "$cur_sha" = "$expected_sha" ]; then
      log "  cached + verified: $out"
      return 0
    fi
  fi
  log "  downloading: $(basename "$out")"
  local url="https://drive.usercontent.google.com/download?id=${id}&export=download&authuser=0&confirm=t"
  if command -v curl >/dev/null; then
    curl -L -C - -o "$out" "$url" --fail --retry 3 --retry-delay 5
  elif command -v wget >/dev/null; then
    wget --continue -O "$out" "$url"
  else
    err "Need either wget or curl to download files."
  fi
}

# ─── Step 0: prerequisites ──────────────────────────────────────────────────
log "Checking prerequisites..."
for cmd in bash tar sha256sum; do
  command -v "$cmd" >/dev/null || err "Missing required command: $cmd"
done
command -v wget >/dev/null || command -v curl >/dev/null || err "Need wget or curl"
command -v git  >/dev/null || err "git is required (apt install git, etc.)"

# ─── Step 1: install miniconda if not present ───────────────────────────────
if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  log "Miniconda not found at $CONDA_DIR — installing..."
  miniconda_installer="/tmp/Miniconda3-installer.sh"
  if [ ! -f "$miniconda_installer" ]; then
    if command -v curl >/dev/null; then
      curl -L "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -o "$miniconda_installer"
    else
      wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "$miniconda_installer"
    fi
  fi
  bash "$miniconda_installer" -b -p "$CONDA_DIR"
  log "Miniconda installed at $CONDA_DIR"
else
  log "Miniconda already present at $CONDA_DIR"
fi

# ─── Step 2: clone / update the repo ────────────────────────────────────────
log "Setting up repo at $CLONE_DIR..."
mkdir -p "$TBXT_ROOT"
if [ ! -d "$CLONE_DIR/.git" ]; then
  if ! git clone "$REPO_URL" "$CLONE_DIR" 2>/dev/null; then
    log "  SSH clone failed, trying HTTPS..."
    git clone "$REPO_HTTPS" "$CLONE_DIR"
  fi
else
  log "  repo exists; pulling latest"
  (cd "$CLONE_DIR" && git fetch --all --quiet && git checkout "$BRANCH" --quiet && git pull --quiet) || true
fi
(cd "$CLONE_DIR" && git checkout "$BRANCH" 2>/dev/null) || true
[ -d "$PROJECT_DIR" ] || err "PROJECT_DIR ($PROJECT_DIR) not found after clone"

# ─── Step 3: download Drive bundle ──────────────────────────────────────────
mkdir -p "$DOWNLOAD_CACHE"
log "Downloading bundles to $DOWNLOAD_CACHE..."
drive_dl "$ID_CHECKSUMS" "$DOWNLOAD_CACHE/CHECKSUMS.sha256"
drive_dl "$ID_MANIFEST"  "$DOWNLOAD_CACHE/MANIFEST_data_bundle.txt"

# Parse expected SHAs from CHECKSUMS.sha256 (format: "<hash>  <filename>")
ENV_SHA=$(grep -E "tbxt_env\.tar\.gz$"          "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
DATA_SHA=$(grep -E "tbxt_data_bundle\.tar\.gz$" "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
[ -n "$ENV_SHA" ]  || err "Could not parse env tarball SHA from CHECKSUMS.sha256"
[ -n "$DATA_SHA" ] || err "Could not parse data tarball SHA from CHECKSUMS.sha256"

drive_dl "$ID_DATA" "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz" "$DATA_SHA"
drive_dl "$ID_ENV"  "$DOWNLOAD_CACHE/tbxt_env.tar.gz"         "$ENV_SHA"

log "Verifying checksums..."
(cd "$DOWNLOAD_CACHE" && sha256sum -c CHECKSUMS.sha256) || err "Checksum verification failed"

# ─── Step 4: unpack the conda env ───────────────────────────────────────────
if [ -x "$ENV_DIR/bin/python" ]; then
  log "Conda env $ENV_NAME already unpacked at $ENV_DIR"
else
  log "Unpacking conda env to $ENV_DIR..."
  mkdir -p "$ENV_DIR"
  tar -xzf "$DOWNLOAD_CACHE/tbxt_env.tar.gz" -C "$ENV_DIR"
  # Activate and conda-unpack
  set +u
  source "$CONDA_DIR/etc/profile.d/conda.sh"; conda activate "$ENV_NAME"
  if command -v conda-unpack >/dev/null; then
    conda-unpack
  else
    log "WARNING: conda-unpack not found in env; paths inside env may be hardcoded"
  fi
  set -u
fi

# ─── Step 5: unpack data bundle into project ────────────────────────────────
if [ -x "$PROJECT_DIR/bin/gnina" ] && [ -f "$PROJECT_DIR/data/dock/receptor/6F59_apo.pdbqt" ]; then
  log "Data bundle already extracted into $PROJECT_DIR"
else
  log "Extracting data bundle to $PROJECT_DIR..."
  tar -xzf "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz" -C "$PROJECT_DIR"
  chmod +x "$PROJECT_DIR/bin/gnina"
fi

# ─── Step 6: verify ─────────────────────────────────────────────────────────
log "Running setup_check.sh..."
set +u
source "$CONDA_DIR/etc/profile.d/conda.sh"; conda activate "$ENV_NAME"
set -u
cd "$PROJECT_DIR"
bash scripts/team/setup_check.sh

# ─── Done ───────────────────────────────────────────────────────────────────
cat <<EOF

================================================================================
  ✅ TBXT setup complete.

  Project root:   $PROJECT_DIR
  Conda env:      $ENV_DIR

  Next step — verify the install end-to-end:
    cd $PROJECT_DIR
    bash smoke_test.sh

  Then find your task assignment:
    cat $PROJECT_DIR/dashboard/MEMBERS.md
================================================================================
EOF
