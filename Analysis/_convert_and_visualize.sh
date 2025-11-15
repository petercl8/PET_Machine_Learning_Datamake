#! /bin/sh

# Use Medcon/XMedcon to convert intf to various other file formats (incl. nifti)

##--------------##
## Input Images ##
##--------------##

#input_image="../VoxelisedSimulation/female_pt176_act_1_8.h33"    # Attenuation, pre-GATE
#input_image="../VoxelisedSimulation/Output/images/Phantomtests-for_meeting-MuMap.hdr" # Attenuation, post-GATE
#input_image="/home/peter/software/XCAT/atn_map_SliceForNEMA.h33"
#input_image="./female_pt71_atn_1.h33"

#input_image="../VoxelisedSimulation/DatasetDir/QA-Radial-60s/act_map_PhantomRadial.h33"
#input_image="../VoxelisedSimulation/DatasetDir/QA-Square-straight/act_map_PhantomSquare.h33"
#input_image="../VoxelisedSimulation/DatasetDir/QA-Square/oblique_image_PhantomSquare.hv"
#input_image="../VoxelisedSimulation/DatasetDir/QA-Square-rotated/oblique_image_PhantomSquareRotated.hv"
#input_image="../VoxelisedSimulation/DatasetDir/QA-Square-rotated/act_map_PhantomSquareRotated.h33"
#input_image="../VoxelisedSimulation/DatasetDir/XCAT-temp/atten_map_9.h33"
#input_image="../VoxelisedSimulation/PhantomNEMA_act_GATE.h33"
#input_image="../VoxelisedSimulation/male_pt80_atn_1_GATE.h33"
#input_image="../VoxelisedSimulation/Output/images/Phantom1-MuMap.hdr" # Attenuation, post-GATE
#input_image="../VoxelisedSimulation/DatasetDir/NEMA-MaxStepSize/

##---------##
## Convert ##
##---------##
#medcon -f $input_image -con    anlz
#medcon -f $input_image3 -c intf
#medcon -f $input_image -c dicom ## Doesn't seem to work when opened with 3D Slicer

#medcon -f $input_image1 -c nifti
#medcon -f $input_image2 -c nifti
#medcon -f $input_image3 -c nifti
#medcon -f $input_image -c nifti
#medcon -f $input_image -c intf

medcon -f $input_image -c nifti

##-----------##
## Visualize ##
##-----------##
xmedcon $input_image
