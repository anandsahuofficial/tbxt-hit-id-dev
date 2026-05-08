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

# ─── Args parsing ──────────────────────────────────────────────────────────
# --update      : re-download CHECKSUMS, re-extract any bundle whose SHA changed
# --force       : re-extract every bundle regardless of SHA
# <positional>  : custom TBXT_ROOT
UPDATE_MODE="false"
FORCE_MODE="false"
POSITIONAL_ARG=""
for arg in "$@"; do
  case "$arg" in
    --update)  UPDATE_MODE="true" ;;
    --force)   FORCE_MODE="true" ;;
    --help)    echo "Usage: $0 [--update|--force] [TBXT_ROOT]"; exit 0 ;;
    -*)        echo "Unknown flag: $arg" >&2; exit 1 ;;
    *)         POSITIONAL_ARG="$arg" ;;
  esac
done

# ─── Configuration ─────────────────────────────────────────────────────────
TBXT_ROOT="${TBXT_ROOT:-${POSITIONAL_ARG:-$HOME}}"
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
# Supplement: docked poses + ligands needed by task5/6/8/9 (~2 MB).
ID_SUPPLEMENT="${ID_SUPPLEMENT:-1aOFQDBWWR3534j1pJO8fd3MNDKiN0mne}"
REPO_URL="git@github.com:anandsahuofficial/Hackathon.git"
REPO_HTTPS="https://github.com/anandsahuofficial/Hackathon.git"
BRANCH="TBXT"

# ─── Helpers ────────────────────────────────────────────────────────────────
log() { printf "\n[\033[36msetup\033[0m %s] %s\n" "$(date +%H:%M:%S)" "$*"; }
err() { printf "\n[\033[31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

drive_dl() {
  # Downloads a Drive file by ID to a local path. Resumable. Idempotent if SHA matches.
  local id="$1"; local out="$2"; local expected_sha="${3:-}"

  # Detect a previously-cached HTML quota-error page and delete it so we retry.
  if [ -f "$out" ]; then
    local _hdr
    _hdr=$(head -c 2 "$out" 2>/dev/null || echo "")
    if [ "$_hdr" = "<!" ] || [ "$_hdr" = "<h" ] || [ "$_hdr" = "<H" ]; then
      log "  WARN: cached file is HTML (prior quota error) — deleting and retrying"
      rm -f "$out"
    fi
  fi

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

  # Detect Google Drive quota / login HTML page returned with HTTP 200.
  # curl --fail does not catch this (status is 200, body is HTML). Symptom:
  # tiny file starting with "<!DOCTYPE" or "<html" / "<HTML". Bail with help.
  if [ -f "$out" ]; then
    local fsize
    fsize=$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out" 2>/dev/null || echo 0)
    if [ "$fsize" -lt 102400 ]; then
      local first2
      first2=$(head -c 2 "$out" 2>/dev/null || echo "")
      if [ "$first2" = "<!" ] || [ "$first2" = "<h" ] || [ "$first2" = "<H" ]; then
        local snippet
        snippet=$(head -c 400 "$out" | tr '\n' ' ' | head -c 200)
        rm -f "$out"
        cat >&2 <<EOF

[ERROR] Drive returned an HTML page instead of the tarball.
        File ID: ${id}
        Saved to: ${out} (deleted)
        Snippet: ${snippet}

This is almost certainly Google Drive's 24-hour download-quota cap
("Quota exceeded — you cannot view or download this file right now").
Public "anyone with link" files cap at ~750 GB/day cumulative across
all downloaders.

Workarounds (in order of speed):
  1. Wait ~24 h and retry.
  2. Ask the file owner (Anand) to right-click the file in Drive
     → "Make a copy" (creates a new file ID with a fresh quota counter)
     → share the new ID; pass it via env on retry, e.g.:
         ID_ENV=<newid> bash setup.sh
  3. Use TBXT_DOWNLOAD_CACHE pointing to a USB / scp-shared local copy
     of the tarball:
         export TBXT_DOWNLOAD_CACHE=/path/to/local/cache
         bash setup.sh
EOF
        exit 1
      fi
    fi
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

# In --update mode, force re-fetch of CHECKSUMS to detect changes on Drive
if [ "$UPDATE_MODE" = "true" ] || [ "$FORCE_MODE" = "true" ]; then
  rm -f "$DOWNLOAD_CACHE/CHECKSUMS.sha256"
fi

drive_dl "$ID_CHECKSUMS" "$DOWNLOAD_CACHE/CHECKSUMS.sha256"
drive_dl "$ID_MANIFEST"  "$DOWNLOAD_CACHE/MANIFEST_data_bundle.txt"

# Parse expected SHAs from CHECKSUMS.sha256 (format: "<hash>  <filename>")
ENV_SHA=$(grep -E "tbxt_env\.tar\.gz$"          "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
DATA_SHA=$(grep -E "tbxt_data_bundle\.tar\.gz$" "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
SUPP_SHA=$(grep -E "tbxt_data_supplement\.tar\.gz$" "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
[ -n "$ENV_SHA" ]  || err "Could not parse env tarball SHA from CHECKSUMS.sha256"
[ -n "$DATA_SHA" ] || err "Could not parse data tarball SHA from CHECKSUMS.sha256"

drive_dl "$ID_DATA" "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz" "$DATA_SHA"
drive_dl "$ID_ENV"  "$DOWNLOAD_CACHE/tbxt_env.tar.gz"         "$ENV_SHA"

# Download supplement if listed in CHECKSUMS (and we have the Drive ID).
# Skip silently if either is missing — downstream step 5a handles fallback.
if [ -n "$SUPP_SHA" ] && [ -n "$ID_SUPPLEMENT" ]; then
  drive_dl "$ID_SUPPLEMENT" "$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz" "$SUPP_SHA"
fi

log "Verifying checksums..."
# Build a filtered CHECKSUMS containing only files that actually exist locally,
# so sha256sum -c doesn't fail on optional files (supplement) we may not have.
TMP_CHECKSUMS="$DOWNLOAD_CACHE/.CHECKSUMS.filtered"
> "$TMP_CHECKSUMS"
while IFS= read -r line; do
  fname=$(echo "$line" | awk '{print $2}')
  [ -z "$fname" ] && continue
  [ -f "$DOWNLOAD_CACHE/$fname" ] && echo "$line" >> "$TMP_CHECKSUMS"
done < "$DOWNLOAD_CACHE/CHECKSUMS.sha256"
(cd "$DOWNLOAD_CACHE" && sha256sum -c "$(basename "$TMP_CHECKSUMS")") || err "Checksum verification failed"
rm -f "$TMP_CHECKSUMS"

# ─── Step 4: unpack the conda env ───────────────────────────────────────────
# Helper: returns 0 if local SHA matches Drive SHA for the named tarball
sha_matches() {
  local local_path="$1" name="$2"
  [ -f "$local_path" ] || return 1
  local expected
  expected=$(grep -E "[[:space:]]+${name}\$" "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
  [ -n "$expected" ] || return 1
  local actual
  actual=$(sha256sum "$local_path" | awk '{print $1}')
  [ "$expected" = "$actual" ]
}

# Decide whether to (re-)extract env: missing, --force, or --update with SHA change
need_env_update="false"
if [ ! -x "$ENV_DIR/bin/python" ]; then
  need_env_update="true"
elif [ "$FORCE_MODE" = "true" ]; then
  need_env_update="true"
elif [ "$UPDATE_MODE" = "true" ]; then
  if [ -f "$DOWNLOAD_CACHE/tbxt_env.tar.gz" ] && sha_matches "$DOWNLOAD_CACHE/tbxt_env.tar.gz" "tbxt_env.tar.gz"; then
    log "Env tarball SHA matches local cache — skipping re-extract"
  else
    log "Drive env SHA changed (or missing local) — will re-download + re-extract"
    rm -f "$DOWNLOAD_CACHE/tbxt_env.tar.gz"
    need_env_update="true"
  fi
fi

if [ "$need_env_update" = "true" ]; then
  log "Unpacking conda env to $ENV_DIR (may overwrite existing)..."
  rm -rf "$ENV_DIR"
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
else
  log "Conda env $ENV_NAME already up-to-date at $ENV_DIR"
fi

# ─── Step 5: unpack data bundle into project ────────────────────────────────
need_data_update="false"
if [ ! -x "$PROJECT_DIR/bin/gnina" ] || [ ! -f "$PROJECT_DIR/data/dock/receptor/6F59_apo.pdbqt" ]; then
  need_data_update="true"
elif [ "$FORCE_MODE" = "true" ]; then
  need_data_update="true"
elif [ "$UPDATE_MODE" = "true" ]; then
  if sha_matches "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz" "tbxt_data_bundle.tar.gz"; then
    log "Data bundle SHA matches local cache — skipping re-extract"
  else
    log "Drive data bundle SHA changed — will re-download + re-extract"
    rm -f "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz"
    need_data_update="true"
  fi
fi

if [ "$need_data_update" = "true" ]; then
  log "Extracting data bundle to $PROJECT_DIR..."
  tar -xzf "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz" -C "$PROJECT_DIR"
  chmod +x "$PROJECT_DIR/bin/gnina"
else
  log "Data bundle already up-to-date at $PROJECT_DIR"
fi

# ─── Step 5a: unpack supplement (poses + ligands for task5/6/8/9) ──────────
SUPPLEMENT_TAR="$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz"
if [ -d "$PROJECT_DIR/data/full_pool_gnina_F/poses" ]; then
  n_poses=$(ls "$PROJECT_DIR/data/full_pool_gnina_F/poses" | wc -l)
else
  n_poses=0
fi

need_supp_update="false"
if [ "$n_poses" -lt 100 ]; then
  need_supp_update="true"
elif [ "$FORCE_MODE" = "true" ]; then
  need_supp_update="true"
elif [ "$UPDATE_MODE" = "true" ] && [ -f "$SUPPLEMENT_TAR" ]; then
  if ! sha_matches "$SUPPLEMENT_TAR" "tbxt_data_supplement.tar.gz"; then
    log "Drive supplement SHA changed — will re-extract"
    need_supp_update="true"
  fi
fi

if [ "$need_supp_update" = "false" ]; then
  log "Pose supplement already up-to-date ($n_poses pose files present)"
elif [ -f "$SUPPLEMENT_TAR" ]; then
  log "Extracting pose supplement from local cache ($(du -h "$SUPPLEMENT_TAR" | cut -f1))..."
  tar -xzf "$SUPPLEMENT_TAR" -C "$PROJECT_DIR"
  log "  ✓ extracted $(ls "$PROJECT_DIR/data/full_pool_gnina_F/poses" | wc -l) poses"
elif [ -n "$ID_SUPPLEMENT" ]; then
  log "Downloading pose supplement from Drive..."
  drive_dl "$ID_SUPPLEMENT" "$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz"
  tar -xzf "$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz" -C "$PROJECT_DIR"
  log "  ✓ extracted $(ls "$PROJECT_DIR/data/full_pool_gnina_F/poses" | wc -l) poses"
else
  log "WARN: pose supplement not available — task5/6/8/9 will fail until poses are generated."
  log "      Run task2 first to regenerate poses, or set ID_SUPPLEMENT in setup.sh."
fi

# ─── Step 5b: post-install env patches ─────────────────────────────────────
# Older Drive bundles ship torchvision==0.24.1 (CUDA wheel) ABI-broken against
# torch 2.8.0 (CPU). The new bundle (post 2026-05-08) ships matched wheels,
# but this step is idempotent: it verifies imports + auto-installs the right
# variant for your hardware (CUDA 12.8 if NVIDIA GPU detected, else CPU).
log "Verifying torch/torchvision/openff imports..."
set +u
source "$CONDA_DIR/etc/profile.d/conda.sh"; conda activate "$ENV_NAME"

# Detect GPU
has_gpu="false"
if command -v nvidia-smi >/dev/null && nvidia-smi >/dev/null 2>&1; then
  has_gpu="true"
fi

# Check if imports work + cuda matches hardware
needs_patch="false"
if ! python -c "import torchvision; from openff.toolkit import Molecule" 2>/dev/null; then
  needs_patch="true"
elif [ "$has_gpu" = "true" ] && ! python -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
  needs_patch="true"
  log "  Hardware has GPU but torch is CPU-only — upgrading to CUDA 12.8"
fi

if [ "$needs_patch" = "true" ]; then
  if [ "$has_gpu" = "true" ]; then
    log "  Installing torch==2.8.0+cu128 + torchvision==0.23.0+cu128 (GPU)..."
    pip install --quiet --force-reinstall --no-deps "torch==2.8.0" "torchvision==0.23.0" \
      --index-url https://download.pytorch.org/whl/cu128
  else
    log "  Installing torch==2.8.0+cpu + torchvision==0.23.0+cpu (CPU)..."
    pip install --quiet --force-reinstall --no-deps "torch==2.8.0" "torchvision==0.23.0" \
      --index-url https://download.pytorch.org/whl/cpu
  fi
  if python -c "import torchvision; from openff.toolkit import Molecule" 2>/dev/null; then
    log "  ✓ torchvision/openff imports OK"
    if [ "$has_gpu" = "true" ]; then
      python -c "import torch; print(f'  ✓ torch.cuda.is_available() = {torch.cuda.is_available()}, device = {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"none\"}')"
    fi
  else
    log "  ⚠ patch did not fully resolve imports — see report below"
  fi
else
  log "  ✓ torch/torchvision/openff imports already OK (no patch needed)"
fi
set -u

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
