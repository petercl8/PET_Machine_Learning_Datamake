# PET Machine Learning Datamake: Installation and Reproducibility Guide

This document describes the software stack and operational workflow used to generate the PET machine-learning dataset. The project depends on a Linux environment with Geant4, ROOT, GATE, STIR, and access to the XCAT phantom generator, together with the PET Machine Learning Datamake workflow for simulation, correction, reconstruction, and post-processing.

## 1. Project overview

The dataset-generation workflow is organized around the scripts in the `VoxelisedSimulation` directory. The main execution path is:

1. source the project environment script;
2. configure the required paths and parameters in __MAIN_SCRIPT.sh
3. if simulating multiple XCAT phantoms sequentially, configure __RunMultiplePhantoms.sh
4. run either __MAIN_SCRIPT.sh (single phantom) or __RunMultiplePhantoms.sh (multiple phantoms)
5. script will: generate phantoms, run the GATE simulation, convert ROOT outputs to Interfile format, correct data, and perform reconstructiosn
6. post-process generated outputs into ML-ready NumPy arrays.

The repository includes both the simulation pipeline and the post-processing notebook used for dataset construction and analysis.

## 2. Required software and supported versions

The workflow was developed and validated with the following software stack:

- Ubuntu/Linux environment
- ROOT 6.30
- Geant4 11.0
- GATE 9.2
- STIR 6.0
- parallelproj 1.8.0
- XCAT (licensed; required for XCAT-based phantom generation)
- Xmedcon 0.21.2
- JupyterLab / Python environment for post-processing

Later versions may work, but compatibility was validated with the versions listed above.

## 3. Project environment setup

The repository includes a shell script that sets the project paths required by the simulation and reconstruction scripts.

From the project root, source the environment script:

```bash
source /path/to/PET_Machine_Learning_Datamake/this_SGC.sh
```

This script sets the project path variables and adds the project directory to `PATH` so that the repository scripts can be found by the shell.

Run the scripts (__MAIN_SCRIPT.sh or __RunMultiplePhantoms.sh) from within ./VoxelisedSimulation

For XCAT-based phantom generation, ensure that the XCAT installation path is configured correctly in __MAIN_SCRIPT.sh. In particular, set `XCAT_PATH` before running the pipeline.

## 4. Dependency installation

### 4.1 Geant4 11.0

The maintained Geant4 installation guide is:

- https://geant4.web.cern.ch/documentation/dev/ig_html/InstallationGuide/

A representative installation workflow is:

```bash
sudo apt-get install build-essential checkinstall
sudo apt-get install libmotif-dev
```

Optional packages may include:

```bash
sudo apt install libvtk9.1-qt
sudo apt install libvtk9-qt-dev
```

Then build Geant4 from source:

```bash
mkdir -p ~/software/geant4
cd ~/software/geant4
# extract the Geant4 11.0 source archive here and rename geant4-source
mkdir geant4-build geant4-install
cd geant4-build

cmake \
  -DCMAKE_INSTALL_PREFIX=/home/$USER/software/geant4/geant4-install \
  -DGEANT4_BUILD_MULTITHREADED=OFF \
  -DGEANT4_INSTALL_DATA=ON \
  -DGEANT4_USE_QT=ON \
  -DGEANT4_USE_OPENGL_X11=ON \
  -DGEANT4_USE_RAYTRACER_X11=ON \
  ../geant4-source

make -j$(nproc)
sudo make install
```

Next, set Geant4 paths:
```bash
source /home/$USER/software/geant4/geant4-install/share/Geant4/geant4make/geant4make.sh
```

Validate the installation with the standard Geant4 example suite. A minimal check is to build and run the basic B1 example:

```bash
cd /home/$USER/software/geant4/geant4-source/examples/basic/B1
mkdir build
cd build
cmake ..
make -j$(nproc)
./exampleB1
```

This confirms that the Geant4 install is functional. A version check may also be performed with:

```bash
geant4-config --version
```

After confirming installation, update the Bash environment variables. To make these paths available in future shells, add this line to `~/.bashrc` and restart the terminal:

```bash
source /home/$USER/software/geant4/geant4-install/bin/geant4.sh
```


### 4.2 ROOT

Install ROOT 6.30 using the official binary or package-compatible distribution installation. After installation, source the ROOT environment. This should also be added to `~/.bashrc` to be run whenever the terminal starts.

```bash
source /home/$USER/software/root/bin/thisroot.sh
```

### 4.3 GATE 9.2

Install the required build dependencies and compile GATE 9.2 from source. The project was validated using GATE 9.2, and compatibility with newer versions should not be assumed without additional testing.

Typical system dependencies include:

```bash
sudo apt-get install build-essential checkinstall
sudo apt-get install cvs subversion git-core mercurial
sudo apt-get install cmake-curses-gui
sudo apt-get install libxmu-dev

# Option A (recommended)
sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools

# Option B
sudo apt-get install libxcb-cursor0
# then install Qt5 from the online installer:
# https://www.qt.io/download-qt-installer
```

A typical build layout is:

```bash
mkdir -p ~/software/gate-9.2
cd ~/software/gate-9.2
# extract GATE source into gate-source
mkdir gate-build gate-install
cd gate-build
```

Then configure the build:

```bash
ccmake ../gate-source
```

Set the installation prefix to the local `gate-install` directory and enable the appropriate build options, including `BUILD_TESTING=ON`.

If configuration issues arise, a command-line configure can be used, for example:

```bash
cmake \
  -DCMAKE_INSTALL_PREFIX=/home/$USER/software/gate-9.2/gate-install \
  -DBUILD_TESTING=ON \
  /home/$USER/software/gate-9.2/gate-source
```

Then compile and install:

```bash
make -j$(nproc)
make install
```

After installation, add the GATE binaries to the PATH. This should also be added to `~/.bashrc` to be run whenever the terminal starts. After install all the packages above, your `~/.bashrc` should contain the following lines:

```bash
source /home/peter/software/geant4/geant4-install/bin/geant4.sh
source /home/peter/software/root/bin/thisroot.sh
export PATH=/home/peter/software/gate/gate-install/bin:$PATH
export PATH=$PATH:/home/peter/software/gate/gate-install/bin
```

### 4.4 STIR 6.0

Install STIR 6.0 according to the official STIR wiki (https://stir.sourceforge.net/) and build instructions. Ensure that the STIR binaries are available in the shell environment when running the reconstruction and correction scripts.

### 4.5 parallelproj 1.8.0

parallelproj is optional but recommended for accelerating forward and backprojection steps used in iterative reconstruction and data correction. It can be enabled or disabled in the main project script. Installation instructions are available at:

- https://parallelproj.readthedocs.io/en/v1.8.0/index.html

### 4.6 XCAT

A licensed XCAT installation is required for generating anthropomorphic XCAT phantoms. Installation instructions are provided with the licensed software package. The project scripts require the XCAT path to be defined before phantom generation.

### 4.7 Xmedcon

Install the format conversion utility used for file conversion:

```bash
sudo apt install xmedcon
```

## 5. Dataset-generation workflow

Once the required dependencies are installed and the project environment is sourced, the dataset generation pipeline can be run using the scripts in the `VoxelisedSimulation` directory.

The general workflow is as follows:

1. Set the scanner configuration and simulation parameters.
2. Generate the selected phantom type.
3. Run the pipeline for the selected phantom sections.
8. Compile the outputs into the ML-ready dataset.

The central driver scripts (__MAIN_SCRIPT.sh for running a single phantom or __RunMultiplePhantoms.sh for running multiple XCAT phantoms) are the main simulation entry point in `VoxelisedSimulation`.

## 6. Verification of a successful run

A successful dataset-generation run should produce the expected simulation outputs, including:

- activity maps;
- attenuation maps;
- annihilation maps;
- prompt and delayed data (ROOT files);
- Fourier-rebinned sinograms;
- reconstruction outputs (FORE and 3D OSEM);
- log files

## 7. Post-processing and dataset assembly

The project includes a Jupyter notebook for post-processing. The notebook contains code for:

- reading Interfile outputs;
- display and visualization of sinograms and reconstructions;
- IQA metric calculations;
- dataset assembly into NumPy arrays;
- partitioning into train/validation/test splits;
- ROI analysis.

For Jupyter-based post-processing, install JupyterLab if needed:

```bash
sudo apt update
sudo apt install python3-pip
pip3 install jupyterlab
```

Then open the notebook and run the cells in order. If the project Python dependencies are not already available in the environment, make sure the import cell is executed before the post-processing steps begin.

To reproduce the author's data splits, edit the cell labeled `Make XCAT Files` and set the following values:

```python
make_XCAT_files = True
phantoms_dir_path = "/path/to/phantoms"
save_dir_path = "/path/to/output/splits"
phantom_list = train_codes  # or validation_codes, test_codes
```

Run the cell to generate the requested split.

## 8. Summary

The key reproducibility requirement is not simply that the software be installed, but that the environment be configured with the same versions and project-path settings used in the original development workflow. In particular, the user must ensure that:

- Geant4, ROOT, GATE, STIR, and parallelproj are installed with compatible versions;
- the project shell environment is sourced;
- XCAT_PATH is configured for XCAT phantom generation;
- the main simulation script is run
- the generated outputs are post-processed with the provided notebook.

This is the workflow used to generate the provided PET machine-learning dataset, both pre-run Interfile data and post-processed NumPy splits.