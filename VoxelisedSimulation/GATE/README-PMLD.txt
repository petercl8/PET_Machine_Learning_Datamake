This directory contains GATE macros and .dat files.

Files:
------
AttenuationConv_SGTC_original.dat: The original XCAT linear attenuation coefficient -> GATE material mapping provided by the STIR-GATE-Connection

AttenuationConv_TrueScale.dat: A more precise XCAT LAC -> GATE material map using more materials and more accurate conversion 
    ranges for 511 keV photons, directly derived from the XCAT attenuation file.
    Since there are more materials it might slightly slow down the simulation, but this is probably negligible.

AttenuationConv_XCATScale.dat: For an unknown reason, our version of XCAT produces attenuation maps with LAC values that are too low. 
    Despite extensive debugging, we could not correct this. Therefore, a this separate attenuation conversion file is used for XCAT phantoms, 
    correctly map XCAT attenuation files to GATE materials. The attenuation file exported by GATE is used in the reconstruction process.

GateMaterials.db: The file initializing all possible GATE materials for use in the simulation. A few metals have been added from the SGC default.

MainGATE-D690.mac: The GATE macro for the D690 scanner with its geometry and digitizer included. Also includes parameters for visualization, disabled by 
default for faster simulation times.

MainGATE-mMR_cylindricalPET.mac: The mMR scanner built with cylindricalPET geometry. STIR currently cannot properly unlist any ROOT files created with this due to the gaps between crystals.

MainGATE-mMR_ecat.mac: The mMR scanner built with ecat geometry. STIR might need to be compiled with ecat compatibility to read the ROOT file.

SetupDmap.mac: Used to run a short simulation and generate a Dmap, which is required for the ImageRegionalizedVolume method of volume paramterization.AAA-Scripts-msc/GATESubMacros/README.md