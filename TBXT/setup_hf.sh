#!/usr/bin/env bash
# TBXT Hackathon — one-shot setup script (Hugging Face Hub variant).
#
# This is a parallel script to setup.sh. The original setup.sh pulls bundles
# from Google Drive; this one pulls from a public Hugging Face dataset repo.
# Drop-in compatible with the rest of the workflow — the only difference is
# WHERE the env / data / supplement tarballs come from.
#
# Why HF Hub?  No 24-h per-file download quota (unlike Drive's ~750 GB/day),
# CDN-backed, scriptable upload via `hf upload`, atomic multi-file commits.
#
# Usage:
#   bash setup_hf.sh                       # default: install at $HOME/Hackathon/TBXT
#   bash setup_hf.sh /opt/work/Hackathon   # custom: install at /opt/work/Hackathon/TBXT
#   bash setup_hf.sh --update              # re-extract only bundles whose SHA changed
#   bash setup_hf.sh --force               # re-extract everything regardless of SHA
#   TBXT_ROOT=/data/h/Hackathon bash setup_hf.sh
#
# Override the HF source repo (default = anandsahuofficial/tbxt-hackathon-bundles):
#   HF_USER=someuser HF_REPO=my-bundles bash setup_hf.sh
#
# For PRIVATE HF repos, set HF_TOKEN (Hugging Face access token):
#   HF_TOKEN=hf_xxx bash setup_hf.sh
#
# After this finishes:
#   1. The conda env tbxt is unpacked at ~/miniconda3/envs/tbxt
#   2. Project root is at $TBXT_ROOT/Hackathon/TBXT (or wherever you chose)
#   3. The team bundles are unpacked into the project
#   4. tests/smoke_test.py validates the whole pipeline runs end-to-end
#
# Requirements (commonly available on Linux): bash, curl OR wget, tar, sha256sum, git
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
DOWNLOAD_CACHE="${TBXT_DOWNLOAD_CACHE:-$HOME/.tbxt_hf_cache}"

# Hugging Face dataset source (override via env vars if needed).
HF_USER="${HF_USER:-anandsahuofficial}"
HF_REPO="${HF_REPO:-tbxt-hackathon-bundles}"
HF_BRANCH="${HF_BRANCH:-main}"
HF_BASE_URL="https://huggingface.co/datasets/${HF_USER}/${HF_REPO}/resolve/${HF_BRANCH}"
# Optional token for private repos. If unset, anonymous public download is used.
HF_TOKEN="${HF_TOKEN:-}"

REPO_URL="git@github.com:anandsahuofficial/Hackathon.git"
REPO_HTTPS="https://github.com/anandsahuofficial/Hackathon.git"
BRANCH="TBXT"

# ─── Helpers ────────────────────────────────────────────────────────────────
log() { printf "\n[\033[36msetup-hf\033[0m %s] %s\n" "$(date +%H:%M:%S)" "$*"; }
err() { printf "\n[\033[31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

hf_dl() {
  # Downloads <filename> from the configured HF dataset repo.
  # Args: <filename-on-hf> <local-out-path> [<expected_sha>]
  # Resumable. Idempotent if SHA matches.
  local filename="$1"; local out="$2"; local expected_sha="${3:-}"

  # Detect a previously-cached HTML error page (e.g. 404 from a wrong path)
  # and delete it so we retry. HF normally returns binary; HTML means the
  # URL is wrong, the repo is private without a token, or HF is rate-limited.
  if [ -f "$out" ]; then
    local _hdr
    _hdr=$(head -c 2 "$out" 2>/dev/null || echo "")
    if [ "$_hdr" = "<!" ] || [ "$_hdr" = "<h" ] || [ "$_hdr" = "<H" ]; then
      log "  WARN: cached file is HTML (prior failed download) — deleting and retrying"
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

  log "  downloading: $filename  ←  ${HF_USER}/${HF_REPO}"
  local url="${HF_BASE_URL}/${filename}"
  local auth_header=()
  if [ -n "$HF_TOKEN" ]; then
    auth_header=(-H "Authorization: Bearer ${HF_TOKEN}")
  fi

  if command -v curl >/dev/null; then
    curl -L -C - -o "$out" "$url" --fail --retry 3 --retry-delay 5 "${auth_header[@]}"
  elif command -v wget >/dev/null; then
    local wget_auth=()
    [ -n "$HF_TOKEN" ] && wget_auth=(--header="Authorization: Bearer ${HF_TOKEN}")
    wget --continue -O "$out" "$url" "${wget_auth[@]}"
  else
    err "Need either wget or curl to download files."
  fi

  # Defensive: detect if HF returned an HTML error page with HTTP 200.
  # This shouldn't happen for valid public files, but covers misconfigs.
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

[ERROR] Hugging Face returned an HTML page instead of the file.
        URL:      ${url}
        Saved to: ${out} (deleted)
        Snippet:  ${snippet}

Likely causes:
  1. Repo or filename is wrong:
     ${HF_BASE_URL}/${filename}
  2. The repo is private and HF_TOKEN is not set or lacks read access:
     export HF_TOKEN=hf_xxx ; bash setup_hf.sh
  3. HF rate-limited the IP. Retry in a few minutes (limit is ~5K req/h).
  4. Network/DNS issue reaching huggingface.co.

To override the source repo:
  HF_USER=<user> HF_REPO=<repo> bash setup_hf.sh
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

# ─── Step 3: download bundles from HF ───────────────────────────────────────
mkdir -p "$DOWNLOAD_CACHE"
log "Downloading bundles to $DOWNLOAD_CACHE  (source: ${HF_USER}/${HF_REPO})"

# In --update mode, force re-fetch of CHECKSUMS to detect changes upstream
if [ "$UPDATE_MODE" = "true" ] || [ "$FORCE_MODE" = "true" ]; then
  rm -f "$DOWNLOAD_CACHE/CHECKSUMS.sha256"
fi

hf_dl "CHECKSUMS.sha256"          "$DOWNLOAD_CACHE/CHECKSUMS.sha256"
# MANIFEST is informational; HF version is optional, so download is best-effort
hf_dl "MANIFEST_data_bundle.txt"  "$DOWNLOAD_CACHE/MANIFEST_data_bundle.txt" || true

# Parse expected SHAs from CHECKSUMS.sha256 (format: "<hash>  <filename>")
ENV_SHA=$(grep -E "tbxt_env\.tar\.gz$"          "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
DATA_SHA=$(grep -E "tbxt_data_bundle\.tar\.gz$" "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
SUPP_SHA=$(grep -E "tbxt_data_supplement\.tar\.gz$" "$DOWNLOAD_CACHE/CHECKSUMS.sha256" | awk '{print $1}')
[ -n "$ENV_SHA" ]  || err "Could not parse env tarball SHA from CHECKSUMS.sha256"
[ -n "$DATA_SHA" ] || err "Could not parse data tarball SHA from CHECKSUMS.sha256"

hf_dl "tbxt_data_bundle.tar.gz"  "$DOWNLOAD_CACHE/tbxt_data_bundle.tar.gz" "$DATA_SHA"
hf_dl "tbxt_env.tar.gz"          "$DOWNLOAD_CACHE/tbxt_env.tar.gz"         "$ENV_SHA"

# Supplement is optional — only download if listed in CHECKSUMS
if [ -n "$SUPP_SHA" ]; then
  hf_dl "tbxt_data_supplement.tar.gz" "$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz" "$SUPP_SHA"
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
# Helper: returns 0 if local SHA matches CHECKSUMS SHA for the named tarball
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
    log "HF env SHA changed (or missing local) — will re-download + re-extract"
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
    log "HF data bundle SHA changed — will re-download + re-extract"
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
    log "HF supplement SHA changed — will re-extract"
    need_supp_update="true"
  fi
fi

if [ "$need_supp_update" = "false" ]; then
  log "Pose supplement already up-to-date ($n_poses pose files present)"
elif [ -f "$SUPPLEMENT_TAR" ]; then
  log "Extracting pose supplement from local cache ($(du -h "$SUPPLEMENT_TAR" | cut -f1))..."
  tar -xzf "$SUPPLEMENT_TAR" -C "$PROJECT_DIR"
  log "  ✓ extracted $(ls "$PROJECT_DIR/data/full_pool_gnina_F/poses" | wc -l) poses"
else
  log "Downloading pose supplement from HF..."
  hf_dl "tbxt_data_supplement.tar.gz" "$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz"
  tar -xzf "$DOWNLOAD_CACHE/tbxt_data_supplement.tar.gz" -C "$PROJECT_DIR"
  log "  ✓ extracted $(ls "$PROJECT_DIR/data/full_pool_gnina_F/poses" | wc -l) poses"
fi

# ─── Step 5b: post-install env patches ─────────────────────────────────────
# Idempotent: verifies imports + auto-installs the right torch variant
# for the host hardware (CUDA 12.8 if NVIDIA GPU detected, else CPU).
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
  ✅ TBXT setup complete (HF-Hub source).

  Bundles from:   ${HF_USER}/${HF_REPO}
  Project root:   $PROJECT_DIR
  Conda env:      $ENV_DIR

  Next step — verify the install end-to-end:
    cd $PROJECT_DIR
    bash smoke_test.sh

  Then find your task assignment:
    cat $PROJECT_DIR/dashboard/MEMBERS.md
================================================================================
EOF
