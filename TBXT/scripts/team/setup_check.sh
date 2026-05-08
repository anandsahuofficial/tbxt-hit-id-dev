#!/usr/bin/env bash
# Verify a team member's environment is correctly set up.
# Run after Task 0 (env distribution).
# Expected output: "all 12 checks passed" or specific failure messages.
set -uo pipefail

PASSED=0
FAILED=0
TBXT="$HOME/tbxt"
[ -d "$TBXT" ] || TBXT="$HOME/Hackathon/TBXT"

echo "Checking environment..."
echo "  Workspace: $TBXT"
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

# Activate env
source "$HOME/miniconda3/envs/tbxt/bin/activate" 2>/dev/null || \
    source "$HOME/miniconda3/etc/profile.d/conda.sh" 2>/dev/null && conda activate tbxt

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
    echo "  - If 'Conda env tbxt activated' failed: source ~/miniconda3/envs/tbxt/bin/activate"
    echo "  - If GNINA imports failed: export LD_LIBRARY_PATH=\$CONDA_PREFIX/lib:\$LD_LIBRARY_PATH"
    echo "  - If receptor PDBQT missing: run python scripts/prep_receptor.py"
    echo "  - If GNINA binary missing: re-download via tbxt_data_bundle.tar.gz from Drive"
    exit 1
fi
