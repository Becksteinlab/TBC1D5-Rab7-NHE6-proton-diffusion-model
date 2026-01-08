# TBC1D5-Rab7-NHE6 Proton Diffusion Model

This repository contains computational models and analyses for studying proton diffusion in the TBC1D5-Rab7-NHE6 protein complex. The project investigates how protons released from NHE6 (Na+/H+ exchanger 6) diffuse through the complex to reach the pH sensor site in TBC1D5 (Rab7 GTPase-activating protein).

## Overview

The TBC1D5-Rab7-NHE6 complex is involved in pH sensing and regulation. This project models:
- **Proton emission**: Protons are released from the outward-facing proton binding site of NHE6 (residue D260)
- **Proton diffusion**: Protons diffuse through the protein complex
- **pH sensing**: Protons reach the allosteric pH sensor site in TBC1D5 (residue H207)

## Directory Structure


### `model_processing/`
Contains notebooks and scripts for processing the structural model:

- **`trim_af_model.ipynb`**: Processes AlphaFold model by removing poorly modeled loop regions
  - Input: AlphaFold model with low confidence regions
  - Output: Trimmed model (`NHE6_TBC1D5_GTP_MG_noloops18plus_score40plus.pdb`)

- **`align_center.ipynb`**: Aligns and centers the structural model
  - Reorients the model for analysis
  - Output: `rotated.pdb`

- **PDB files**:
  - `PDBmodel_0.pdb`: Original AF3 model
  - `NHE6_TBC1D5_GTP_MG_noloops18plus_score40plus.pdb`: Trimmed AlphaFold model
  - `rotated.pdb`: Aligned and centered model

### `proton_pathway/`
Contains analysis of the putative proton diffusion pathway through the protein complex:

- **`diffusion_pathway.ipynb`**: Identifies the minimum-length pathway for proton diffusion
  - Uses HOLLOW casting to define the cavity/pathway
  - Finds shortest path from NHE6 D260 (D292' in rotated model) to TBC1D5 H207 (H207')
  - Uses graph-based approach with nearest neighbor analysis
  - Uses Dijkstra's algorithm for path finding

- **`hollow.pdb`**: Hollow casting of the protein cavity
- **`path.pdb`**: Coordinates of the identified diffusion pathway
- **`constraint.txt`**, **`atom_based_constraint.txt`**: Constraint files for hollow casting
- **`RUN_hollow.sh`**: Shell script for running hollow casting analysis

### `diffusion/`
Contains Jupyter notebooks implementing analytical solutions for proton diffusion in different geometries:

- **`Diffusion1D_cylindrical.ipynb`**: Models proton diffusion in 1D cylindrical geometry
  - Solves Laplace's equation for steady-state concentration profiles
  - Assumes rotational symmetry and no radial dependence
  - Boundary conditions: constant flux at z=0, bulk concentration at z=L
  - Analytical solution: linear concentration profile
  - Includes discussion of the thermodynamics of Na+, K+, and H+ transport under realistic concentrations in the cytosol and endosome.
  - Shows that under plausible assumptions, proton transport is likely not thermodynamically limited; under assumption of kinetical limitations, the local pH near H207 may be sufficiently acidic to change its protonation state and thus couple proton efflux from NHE to Rab7 signaling.

- **`Diffusion3D_spherical.ipynb`**: Models proton diffusion in 3D hemispherical geometry
  - Solves Laplace's equation in spherical coordinates with radial symmetry
  - Models protons emitted from a sphere of radius r₀ diffusing outward
  - Boundary conditions: constant flux density at inner sphere, bulk concentration at outer boundary
  - Analytical solution: 1/r concentration profile
  - Investigates effects of reduced diffusion coefficients
  - The hemispherical model does not generate a sufficiently acidic local pH near H207.


## Key Residues

- **NHE6 proton binding site**: D260 (D292' in rotated model)
- **TBC1D5 pH sensor**: H207 (H207' in rotated model)
- **Note**: Primed residue numbers refer to the AlphaFold model, unprimed are canonical UniProt sequence numbers

## Methods

### Diffusion Modeling
- Steady-state solutions to Laplace's equation (∇²c = 0)
- Fick's law: j = -D∇c
- Boundary conditions: constant flux at source, bulk concentration at sink
- Parameters include:
  - Diffusion coefficient D (with reduced values for protein environment)
  - Proton emission rate k₀
  - Bulk pH (typically pH 7.2)

### Pathway Analysis
- Uses hollow casting to identify protein cavities
- Graph-based path finding using nearest neighbor networks
- Minimum distance path calculation via Dijkstra's algorithm

## Dependencies

- [HOLLOW](https://github.com/Becksteinlab/hollow) 
  - Bosco K. Ho and Franz Grusewitz. HOLLOW: Generating accurate representations of channel and interior surfaces in molecular structures. BMC Struct Biol, 8 (49), 2008. doi: 10.1186/1472-6807-8-49
  - Use the patched version from https://github.com/Becksteinlab/hollow and install in a Python 2.7 environment.
  - Only needed for creating a casting of the cavities and tunnels that is then used to find a putative diffusion path. The casting is already included in the repository so it is _not_ needed for running the notebooks.
- Python packages in notebooks (required Python ≥ 3.10)
  - `MDAnalysis`: For structural analysis
  - `networkx`: For graph-based path finding
  - `numpy`, `scipy`: Numerical computations
  - `matplotlib`: Plotting
  - `sympy`: Symbolic mathematics

## Usage

1. **Process the structural model**:
   - Run `model_processing/trim_af_model.ipynb` to trim the AlphaFold model
   - Run `model_processing/align_center.ipynb` to align and center the model

2. **Identify the proton pathway**:
   - *optional*: Run `proton_pathway/RUN_hollow.sh` to create the casting (optional because casting `hollow.pdb` is already included)
   - Run `proton_pathway/diffusion_pathway.ipynb` to find the diffusion pathway

3. **Model proton diffusion**:
   - Run `diffusion/Diffusion1D_cylindrical.ipynb` for 1D cylindrical model
   - Run `diffusion/Diffusion3D_spherical.ipynb` for 3D spherical model

## License
All content licensed under MIT.

