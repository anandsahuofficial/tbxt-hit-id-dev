#!/usr/bin/env bash
# One-time helper: configure SSH access to Hugging Face for the uploader side.
# Run this ONCE on your machine (the laptop/HPC node that will push bundles).
#
# What it does:
#   1. Verifies / creates an SSH ed25519 key
#   2. Verifies git-lfs is installed
#   3. Tests SSH connectivity to hf.co
#   4. Prints the public key for you to paste into HF settings
#   5. Optionally clones the target dataset repo so it's ready for repack/push
#
# Usage:
#   bash scripts/team/setup_hf_ssh_once.sh
#
# Override target repo (default: anandsahuofficial/tbxt-hackathon-bundles):
#   HF_USER=<user> HF_REPO=<repo> bash scripts/team/setup_hf_ssh_once.sh

set -euo pipefail

HF_USER="${HF_USER:-anandsahuofficial}"
HF_REPO="${HF_REPO:-tbxt-hackathon-bundles}"
HF_SSH_REMOTE="git@hf.co:datasets/${HF_USER}/${HF_REPO}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT_ROOT="$(cd "$HERE/../.." && pwd)"
HF_LOCAL_CLONE="${HF_LOCAL_CLONE:-$TBXT_ROOT/tbxt_hf_local}"

log()  { printf "\n[\033[36mhf-ssh\033[0m %s] %s\n" "$(date +%H:%M:%S)" "$*"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$*"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$*"; }
err()  { printf "\n[\033[31mERROR\033[0m] %s\n" "$*" >&2; exit 1; }

# ─── Step 1: SSH key ────────────────────────────────────────────────────────
log "Step 1: SSH key"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ] && [ -f "${SSH_KEY}.pub" ]; then
  ok "ed25519 SSH key already exists at $SSH_KEY"
else
  warn "no ed25519 key found. Generating one (no passphrase, press Enter at prompts)..."
  ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)-hf" -f "$SSH_KEY" -N ""
  ok "generated $SSH_KEY"
fi

# ─── Step 2: git-lfs ────────────────────────────────────────────────────────
log "Step 2: git-lfs"
if ! command -v git-lfs >/dev/null; then
  warn "git-lfs not installed. Installing into your shell hooks requires:"
  cat <<EOF

  # Debian/Ubuntu/WSL2:
    sudo apt-get install -y git-lfs

  # Fedora/RHEL:
    sudo dnf install -y git-lfs

  # macOS:
    brew install git-lfs

  Then re-run this script.
EOF
  exit 1
fi
git lfs install --skip-repo
ok "git-lfs $(git lfs version | awk '{print $1}') ready"

# ─── Step 3: SSH connectivity test ──────────────────────────────────────────
log "Step 3: testing SSH to hf.co"
ssh_output="$(ssh -T -o StrictHostKeyChecking=accept-new -o BatchMode=yes git@hf.co 2>&1 || true)"
echo "$ssh_output"
if echo "$ssh_output" | grep -qE "^Hi |successfully authenticated"; then
  ok "SSH is authenticated to HF"
  hf_ssh_ok="true"
else
  hf_ssh_ok="false"
  warn "SSH not yet authenticated. You need to add your public key to HF first."
fi

# ─── Step 4: print public key for HF UI paste ──────────────────────────────
if [ "$hf_ssh_ok" = "false" ]; then
  log "Step 4: paste this public key into HF"
  echo
  echo "    1. Open: https://huggingface.co/settings/keys"
  echo "    2. Click 'Add SSH key'"
  echo "    3. Title:  $(hostname)-tbxt"
  echo "    4. Paste this public key:"
  echo
  echo "    ─── BEGIN ────────────────────────────────────────────"
  cat "${SSH_KEY}.pub"
  echo "    ─── END ──────────────────────────────────────────────"
  echo
  echo "    5. Save, then re-run this script to confirm SSH works."
  exit 0
fi

# ─── Step 5: clone the dataset repo (idempotent) ────────────────────────────
log "Step 5: local clone of the HF dataset repo"
if [ -d "$HF_LOCAL_CLONE/.git" ]; then
  ok "already cloned at $HF_LOCAL_CLONE"
  ( cd "$HF_LOCAL_CLONE" && git remote -v | head -1 )
else
  if git clone "$HF_SSH_REMOTE" "$HF_LOCAL_CLONE" 2>/dev/null; then
    ok "cloned to $HF_LOCAL_CLONE"
  else
    warn "clone failed. Likely the repo doesn't exist yet."
    cat <<EOF

Create it now:
    1. https://huggingface.co/new-dataset
    2. Owner: $HF_USER
    3. Name:  $HF_REPO
    4. Visibility: Public
    5. Save, then re-run this script.

If the owner/repo names differ, override before running:
    HF_USER=<user> HF_REPO=<repo> bash scripts/team/setup_hf_ssh_once.sh
EOF
    exit 1
  fi
fi

# Make sure git-lfs tracks our common big-file extensions
( cd "$HF_LOCAL_CLONE" && {
    if [ ! -f .gitattributes ] || ! grep -q "tar.gz" .gitattributes 2>/dev/null; then
      log "  configuring .gitattributes for LFS tracking"
      git lfs track "*.tar.gz"
      git add .gitattributes 2>/dev/null || true
      git commit -m "Track *.tar.gz via git-lfs" 2>/dev/null || true
      git push 2>/dev/null || true
    fi
} )

cat <<EOF

================================================================================
  ✅ HF SSH setup ready.

  Local clone:  $HF_LOCAL_CLONE
  Remote:       $HF_SSH_REMOTE

  To push a fresh bundle:
      bash scripts/team/repack_and_upload_hf.sh

  To override the target repo at upload time:
      HF_USER=<user> HF_REPO=<repo> bash scripts/team/repack_and_upload_hf.sh
================================================================================
EOF
