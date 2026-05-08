#!/usr/bin/env bash
# Verify a team member's environment is correctly set up.
# Run after Task 0 (env distribution) — invoked at the end of setup_hf.sh / setup.sh.
#
# Auto-detects the TBXT project path from the script location (resolves
# correctly whether the project is at $HOME/Hackathon/TBXT, /projectnb/.../Hackathon/TBXT,
# or anywhere else). Honors $CONDA_DIR (defaults to $HOME/miniconda3) so the
# same script works on laptops and on HPC nodes with project-space conda.
#
# Activates the env via direct `source $ENV_DIR/bin/activate` — no
# `conda activate <name>` or conda hooks needed.
set -uo pipefail

PASSED=0
FAILED=0

# Auto-detect TBXT project root from the script's own location.
# This script lives at $TBXT/scripts/team/setup_check.sh — going up two
# parents gives us $TBXT. Override with $TBXT_PROJECT_DIR if needed.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TBXT="${TBXT_PROJECT_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Conda location: honor $CONDA_DIR (HPC sets it to /projectnb/.../miniconda3
# because /usr3/graduate is quota-limited). Default for laptops: ~/miniconda3.
CONDA_DIR="${CONDA_DIR:-$HOME/miniconda3}"
ENV_NAME="${ENV_NAME:-tbxt}"
ENV_DIR="$CONDA_DIR/envs/$ENV_NAME"

echo "Checking environment..."
echo "  Workspace:  $TBXT"
echo "  Conda env:  $ENV_DIR"
echo

check() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  ✅ $name"
        PASSED=$((PASSED + 1))
    else
        echo "  ❌ $name"
        FAILED=$((FAILED + 1))
    fi
}

# Activate env DIRECTLY via the conda-shipped activate script
# (`source $CONDA_DIR/bin/activate $ENV_NAME`). Works for both
# `conda create`d envs (no env-local bin/activate) and conda-pack'd envs.
# Does not depend on conda's shell hooks being initialized.
if [ -d "$ENV_DIR" ] && [ -x "$CONDA_DIR/bin/activate" ]; then
    source "$CONDA_DIR/bin/activate" "$ENV_NAME"
    export LD_LIBRARY_PATH="$ENV_DIR/lib:${LD_LIBRARY_PATH:-}"
elif [ -f "$ENV_DIR/bin/activate" ]; then
    # Fallback: conda-pack'd env with its own bin/activate
    source "$ENV_DIR/bin/activate"
    export LD_LIBRARY_PATH="$ENV_DIR/lib:${LD_LIBRARY_PATH:-}"
fi

# 12 checks
check "Workspace dir exists"           [ -d "$TBXT" ]
check "Conda env tbxt activated"       [ -n "${CONDA_PREFIX:-}" ]
check "RDKit imports"                  python -c "from rdkit import Chem"
check "Vina imports"                   python -c "import vina"
check "Meeko imports"                  python -c "from meeko import MoleculePreparation"
check "OpenBabel imports"              python -c "from openbabel import openbabel"
check "OpenMM imports"                 python -c "import openmm"
check "OpenFF imports"                 python -c "import openff.toolkit"
check "PDBFixer imports"               python -c "from pdbfixer import PDBFixer"
check "BioPython imports"              python -c "from Bio.PDB import PDBParser"
check "GNINA binary exists"            [ -x "$TBXT/bin/gnina" ]
check "Receptor PDBQT exists"          [ -f "$TBXT/data/dock/receptor/6F59_apo.pdbqt" ]

echo
TOTAL=$((PASSED + FAILED))
if [ "$FAILED" -eq 0 ]; then
    echo "all $TOTAL checks passed"
    exit 0
else
    echo "$PASSED/$TOTAL passed; $FAILED failed"
    echo
    echo "Common fixes:"
    echo "  - If 'Conda env tbxt activated' failed: source $ENV_DIR/bin/activate"
    echo "  - If GNINA imports failed: export LD_LIBRARY_PATH=\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH"
    echo "  - If receptor PDBQT missing: run python scripts/prep_receptor.py"
    echo "  - If GNINA binary missing: re-extract from tbxt_data_bundle.tar.gz"
    echo "  - If running on HPC and paths look wrong, set TBXT_PROJECT_DIR + CONDA_DIR"
    exit 1
fi
