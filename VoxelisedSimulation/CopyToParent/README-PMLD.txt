These files are copied to the parent directory (VoxelisedSimulation):


XCAT_phantom_act_3mmVox.hv and XCAT_phantom_atn_3mmVox.hv: Header files for the generated XCAT phantom. Need to be edited to have the correct number of slices [3] if scanner is changed. If changing the voxel size or number, /SubScripts/CreateXCATImages/XCAT_V2_LINUX/general.samp_3mmVox.par must also be edited accordingly.

xcat2.cfg: XCAT validation key. Needs to be in the PWD when XCAT is called or it will not be seen.