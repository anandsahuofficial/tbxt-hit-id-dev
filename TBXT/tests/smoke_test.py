"""
TBXT smoke test — exercises the full toolchain end-to-end on 1 compound in ~30 sec.
If this passes, the team member's machine is genuinely ready for production runs.

Tests:
  1. Core imports (rdkit, vina, meeko, openmm, openff, biopython, pdbfixer, xgboost)
  2. RDKit: SMILES → 3D conformer
  3. Meeko: 3D mol → PDBQT
  4. Vina: dock 1 ligand at site F (exhaustiveness=1, ~3 sec)
  5. GNINA: re-score the docked pose with CNN (subprocess, ~5 sec on GPU; ~15 sec on CPU)
  6. QSAR: load trained model + predict pKd from SMILES
  7. Receptor + grid file existence

Exits 0 on success, non-zero with a clear failure message on first error.
Run as:  python tests/smoke_test.py
"""
import os
import subprocess
import sys
import time
from pathlib import Path

# Project root resolution — works from any directory the script lives at
TBXT_ROOT = Path(__file__).resolve().parents[1]
DATA = TBXT_ROOT / "data"
RECEPTOR_PDBQT = DATA / "dock" / "receptor" / "6F59_apo.pdbqt"
GRID_DEFS = DATA / "dock" / "grid_definitions.json"
GNINA_BIN = TBXT_ROOT / "bin" / "gnina"
QSAR_RF = DATA / "qsar" / "model_rf.pkl"

# Use a small known compound — the smallest TEP fragment at site F
TEST_SMILES = "O=C(O)COCc1ccccc1"   # FM002150 / benzyloxyacetic acid (HA=12)
TEST_ID = "smoke_FM002150"


def step(name):
    print(f"\n[\033[36m{name}\033[0m]", flush=True)


def fail(msg):
    print(f"\n\033[31m✗ FAILED:\033[0m {msg}", flush=True)
    sys.exit(1)


def ok(msg):
    print(f"  \033[32m✓\033[0m {msg}", flush=True)


def main():
    t0 = time.time()
    print(f"TBXT smoke test")
    print(f"  Project root: {TBXT_ROOT}")
    print(f"  Test compound: {TEST_ID}  SMILES={TEST_SMILES}")

    # ── 1. Core imports ─────────────────────────────────────────────────────
    step("1. Core library imports")
    try:
        from rdkit import Chem, RDLogger
        from rdkit.Chem import AllChem
        ok(f"rdkit ({Chem.__name__})")
        RDLogger.DisableLog("rdApp.*")
    except Exception as e:
        fail(f"rdkit import: {e}")
    try:
        from meeko import MoleculePreparation, PDBQTWriterLegacy
        ok("meeko")
    except Exception as e:
        fail(f"meeko import: {e}")
    try:
        from vina import Vina
        ok(f"vina")
    except Exception as e:
        fail(f"vina import: {e}")
    try:
        import openmm; ok(f"openmm {openmm.__version__}")
    except Exception as e:
        fail(f"openmm import: {e}")
    try:
        import openff.toolkit; ok(f"openff-toolkit {openff.toolkit.__version__}")
    except Exception as e:
        fail(f"openff-toolkit import: {e}")
    try:
        from Bio.PDB import PDBParser; ok("biopython")
    except Exception as e:
        fail(f"biopython import: {e}")
    try:
        from pdbfixer import PDBFixer; ok("pdbfixer")
    except Exception as e:
        fail(f"pdbfixer import: {e}")
    try:
        import xgboost; ok(f"xgboost {xgboost.__version__}")
    except Exception as e:
        fail(f"xgboost import: {e}")

    # ── 2. Receptor + grid files exist ──────────────────────────────────────
    step("2. Receptor + grid file existence")
    if not RECEPTOR_PDBQT.exists():
        fail(f"missing receptor: {RECEPTOR_PDBQT}")
    ok(f"receptor PDBQT present: {RECEPTOR_PDBQT.name} ({RECEPTOR_PDBQT.stat().st_size} bytes)")
    if not GRID_DEFS.exists():
        fail(f"missing grid definitions: {GRID_DEFS}")
    ok(f"grid definitions present: {GRID_DEFS.name}")
    if not GNINA_BIN.exists():
        fail(f"missing GNINA binary: {GNINA_BIN}")
    if not os.access(GNINA_BIN, os.X_OK):
        fail(f"GNINA binary not executable: {GNINA_BIN}")
    ok(f"GNINA binary present + executable: {GNINA_BIN}")

    # ── 3. RDKit: SMILES → 3D ───────────────────────────────────────────────
    step("3. RDKit: SMILES → 3D conformer")
    mol = Chem.MolFromSmiles(TEST_SMILES)
    if mol is None: fail("RDKit could not parse SMILES")
    mol = Chem.AddHs(mol)
    if AllChem.EmbedMolecule(mol, randomSeed=42, useRandomCoords=True) != 0:
        fail("RDKit ETKDG embedding failed")
    AllChem.UFFOptimizeMolecule(mol, maxIters=200)
    ok(f"3D conformer: {mol.GetNumAtoms()} atoms, {mol.GetNumBonds()} bonds")

    # ── 4. Meeko: 3D mol → PDBQT ────────────────────────────────────────────
    step("4. Meeko: 3D mol → PDBQT")
    prep = MoleculePreparation()
    setups = prep.prepare(mol)
    if not setups: fail("Meeko returned no setups")
    pdbqt_str, ok_flag, err_msg = PDBQTWriterLegacy.write_string(setups[0])
    if not ok_flag: fail(f"Meeko PDBQT writer: {err_msg}")
    smoke_dir = TBXT_ROOT / "tests" / "smoke_out"
    smoke_dir.mkdir(parents=True, exist_ok=True)
    lig_pdbqt = smoke_dir / f"{TEST_ID}.pdbqt"
    lig_pdbqt.write_text(pdbqt_str)
    ok(f"ligand PDBQT written: {lig_pdbqt} ({lig_pdbqt.stat().st_size} bytes)")

    # ── 5. Vina: 1-compound dock at site F (exhaustiveness=1) ──────────────
    step("5. Vina: dock 1 compound at site F")
    import json
    grids = json.loads(GRID_DEFS.read_text())
    g = grids["F"]
    cx, cy, cz = g["center_xyz_A"]
    sx, sy, sz = g["box_size_A"]
    v = Vina(sf_name="vina", verbosity=0)
    v.set_receptor(str(RECEPTOR_PDBQT))
    v.compute_vina_maps(center=[cx, cy, cz], box_size=[sx, sy, sz])
    v.set_ligand_from_file(str(lig_pdbqt))
    t_dock_0 = time.time()
    v.dock(exhaustiveness=1, n_poses=3)
    dock_time = time.time() - t_dock_0
    energies = v.energies(n_poses=3)
    if energies is None or len(energies) == 0: fail("Vina returned no poses")
    best = float(min(e[0] for e in energies))
    if best > 0:
        fail(f"Vina best score is positive ({best:.2f}) — pocket grid or receptor problem")
    pose_pdbqt = smoke_dir / f"{TEST_ID}_pose.pdbqt"
    v.write_poses(str(pose_pdbqt), n_poses=3, overwrite=True)
    ok(f"Vina dock complete in {dock_time:.1f}s; best score = {best:.2f} kcal/mol")
    ok(f"pose written: {pose_pdbqt}")

    # ── 6. GNINA: re-score with CNN ─────────────────────────────────────────
    step("6. GNINA: dock + CNN scoring")
    env = os.environ.copy()
    conda_lib = Path(os.environ.get("CONDA_PREFIX", "")) / "lib"
    if conda_lib.exists():
        env["LD_LIBRARY_PATH"] = f"{conda_lib}:" + env.get("LD_LIBRARY_PATH", "")
    cmd = [
        str(GNINA_BIN),
        "-r", str(RECEPTOR_PDBQT),
        "-l", str(lig_pdbqt),
        "--center_x", str(cx), "--center_y", str(cy), "--center_z", str(cz),
        "--size_x", str(sx),   "--size_y", str(sy),   "--size_z", str(sz),
        "--cnn_scoring", "rescore",
        "--exhaustiveness", "1",
        "--num_modes", "3",
        "-o", str(smoke_dir / f"{TEST_ID}_gnina_pose.pdbqt"),
    ]
    t_g0 = time.time()
    res = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=120)
    g_time = time.time() - t_g0
    if res.returncode != 0:
        fail(f"GNINA failed (rc={res.returncode}): {res.stderr[-500:]}")
    # Parse the per-mode table from stdout
    cnn_pose_seen = False
    for line in res.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 5 and parts[0] == "1":
            try:
                _, vina_aff, _, cnn_pose, cnn_pkd = parts[:5]
                ok(f"GNINA dock complete in {g_time:.1f}s")
                ok(f"  pose 1: vina={float(vina_aff):.2f} cnn_pose={float(cnn_pose):.3f} cnn_pKd={float(cnn_pkd):.2f}")
                cnn_pose_seen = True
                break
            except (ValueError, IndexError):
                pass
    if not cnn_pose_seen:
        print("GNINA stdout (last 30 lines):")
        for l in res.stdout.splitlines()[-30:]:
            print(f"  {l}")
        fail("GNINA produced no parseable mode table")

    # ── 7. QSAR: load model + predict ───────────────────────────────────────
    step("7. QSAR: load model + predict on 1 compound")
    if not QSAR_RF.exists():
        fail(f"missing QSAR model: {QSAR_RF}")
    import pickle
    import numpy as np
    from rdkit.Chem import Descriptors, Lipinski
    from rdkit.Chem.rdFingerprintGenerator import GetMorganGenerator
    rf = pickle.load(open(QSAR_RF, "rb"))
    mfg = GetMorganGenerator(radius=2, fpSize=2048)
    m_pred = Chem.MolFromSmiles(TEST_SMILES)
    fp = mfg.GetFingerprint(m_pred)
    fp_arr = np.frombuffer(fp.ToBitString().encode(), dtype=np.uint8) - ord("0")
    descs = np.array([
        Descriptors.MolWt(m_pred), Descriptors.MolLogP(m_pred),
        Lipinski.NumHDonors(m_pred), Lipinski.NumHAcceptors(m_pred),
        Descriptors.TPSA(m_pred), Lipinski.NumRotatableBonds(m_pred),
        m_pred.GetRingInfo().NumRings(), m_pred.GetNumHeavyAtoms(),
    ], dtype=np.float32)
    X = np.hstack([fp_arr, descs]).reshape(1, -1)
    pkd = float(rf.predict(X)[0])
    ok(f"QSAR pKd prediction: {pkd:.2f}  (= Kd ≈ {10**(-pkd)*1e6:.0f} µM)")

    # ── done ────────────────────────────────────────────────────────────────
    elapsed = time.time() - t0
    print(f"\n\033[32m=== ALL SMOKE-TEST CHECKS PASSED ===\033[0m  total {elapsed:.1f}s")
    print(f"  Output dir: {smoke_dir}")
    print(f"  Vina best:  {best:.2f} kcal/mol")
    print(f"  QSAR pKd:   {pkd:.2f}")
    sys.exit(0)


if __name__ == "__main__":
    main()
