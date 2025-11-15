#! /bin/sh

input_hv="../VoxelisedSimulation/OSEM_5.hv"
input_v="../VoxelisedSimulation/OSEM_5.v"
cp $input_hv ./OSEM_5.hv
cp $input_v ./OSEM_5.v

list_image_info OSEM_5.hv

stir_math --including-first --times-scalar 1 output.hv OSEM_5.hv

list_image_info output.hv

stir_write_pgm --slice_index 20 output output.hv # Writes PGM for for a single slice of an image