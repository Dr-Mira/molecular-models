# 3D Printed Molecular Models for Chemistry Education

Molecular structures calculated with quantum mechanics, optimized and tested for 3D printing.

## Overview
This project provides a searchable database of scientific-grade, 3D-printable molecular models. Designed for educators, students, and chemistry enthusiasts, these models offer physical intuition that standard plastic kits often lack, preserving accurate bond angles and relative atomic sizes.

## Features
- **Scientific Accuracy**: Geometries optimized using MMFF (Merck Molecular Force Field) and DFT (Density Functional Theory) refinement.
- **CPK Standards**: Color-coded according to typical CPK conventions for easy identification.
- **Ready to Print**: Optimized for consumer FDM printers (tested on Bambu Lab P1S).
- **Free Library**: Browse the collection and download models via MakerWorld.

## Methods
Molecular geometries were obtained through a two-stage optimization pipeline implemented in a custom Python script. Starting from SMILES notation, the script generates ~2,000 conformers using the Merck Molecular Force Field (MMFF94) [1] to broadly sample the conformational space. The top 5 lowest-energy conformers from this classical screening are then refined using density functional theory (DFT) at the ωB97X-D/def2-SVP level [2]. The lowest-energy DFT-optimized structure is selected as the final geometry. Atoms are rendered as spheres scaled to van der Waals radii [3], and bond orders correspond to the dominant resonance contributor as encoded in the input SMILES. Each model is visually verified against PubChem [4], exported as STL, and manually colored with the CPK convention in a slicer. Running on an Intel Core i7-8700 utilizing all six cores, the pipeline averaged approximately 6 hours per molecule.

### Force Fields
The initial conformational search relies on MMFF94, a well-established classical force field parameterized against high-level ab initio data for a broad range of organic and drug-like molecules [1]. MMFF94 describes the potential energy surface through analytical terms for bond stretching, angle bending, torsional rotation, van der Waals interactions, and electrostatics. Its parameters were derived by fitting to HF/6-31G* geometries and MP2-level energetics, which gives it reliable accuracy for conformer ranking at a fraction of the cost of quantum mechanical methods [5]. This makes it well suited for rapidly screening thousands of candidate geometries before passing a small subset to DFT refinement.

### Density Functional Theory
Final geometry optimizations are performed with the ωB97X-D functional [6] paired with the def2-SVP basis set [7], executed through the Psi4 electronic structure package [2]. ωB97X-D is a range-separated hybrid functional that includes an empirical dispersion correction, making it particularly effective for capturing both covalent bonding and non-covalent intramolecular interactions that influence molecular conformation. The def2-SVP basis set provides a balanced trade-off between computational cost and accuracy for geometry optimizations of this kind. This level of theory has been widely benchmarked and shown to produce reliable equilibrium geometries for organic molecules [8].

## Printing Notes
- **Material**: Optimized/tested for print with Bambu PLA and Elegoo PLA+.
- **Style**: Ball-and-stick type (easiest to color, rigid, aesthetic).
- **Orientation**: Oriented for optimal strength/waste/time compromise.
- **Supports**: Removable with care. Suggest using PETG as a support interface.

## References
1. Halgren, T. A. Merck Molecular Force Field. I. Basis, Form, Scope, Parameterization, and Performance of MMFF94. *J. Comput. Chem.* **1996**, *17*, 490–519.
2. Smith, D. G. A.; Burns, L. A.; Simmonett, A. C.; Parrish, R. M.; Schieber, M. C.; *et al.* Psi4 1.4: Open-Source Software for High-Throughput Quantum Chemistry. *J. Chem. Phys.* **2020**, *152*, 184108.
3. Bondi, A. Van der Waals Volumes and Radii. *J. Phys. Chem.* **1964**, *68*, 441–451.
4. PubChem, National Library of Medicine, National Center for Biotechnology Information. [https://pubchem.ncbi.nlm.nih.gov/](https://pubchem.ncbi.nlm.nih.gov/)
5. Halgren, T. A.; Nachbar, R. B. Merck Molecular Force Field. IV. Conformational Energies and Geometries for MMFF94. *J. Comput. Chem.* **1996**, *17*, 587–615.
6. Chai, J.-D.; Head-Gordon, M. Long-Range Corrected Hybrid Density Functionals with Damped Atom–Atom Dispersion Corrections. *Phys. Chem. Chem. Phys.* **2008**, *10*, 6615–6620.
7. Weigend, F.; Ahlrichs, R. Balanced Basis Sets of Split Valence, Triple Zeta Valence and Quadruple Zeta Valence Quality for H to Rn: Design and Assessment of Accuracy. *Phys. Chem. Chem. Phys.* **2005**, *7*, 3297–3305.
8. Goerigk, L.; Grimme, S. A Thorough Benchmark of Density Functional Methods for General Main Group Thermochemistry, Kinetics, and Noncovalent Interactions. *Phys. Chem. Chem. Phys.* **2011**, *13*, 6670–6688.
