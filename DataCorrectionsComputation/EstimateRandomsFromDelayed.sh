#!/usr/bin/env bash
## AUTHOR: Robert Twyman
## AUTHOR: Kris Thielemans
## Copyright (C) 2020-2021 University College London
## Licensed under the Apache License, Version 2.0

## This script estimates the background randoms from Delayed coincidences projection data.


if [ $# != 2 ]; then
	echo "Usage: EstimateRandomsFromDelayed.sh OutputFilename delayed_sinogram"
	exit 1
fi 

## PARAMETERS
OutputFilename=$1 
delayed_sinogram=$2 ## INPUT: Delayed coincidences sinogram

## factors are a temporary file created by find_ML_singles_from_delayed [deleted by cleanup]
factors=singles_from_delayed
num_iterations=10

echo "Estimating the randoms from the delayed sinogram:"
echo "   ${delayed_sinogram}"

echo "find_ML_singles_from_delayed"
find_ML_singles_from_delayed ${factors} ${delayed_sinogram} ${num_iterations} < /dev/null

echo "construct_randoms_from_singles"
construct_randoms_from_singles ${OutputFilename} ${factors} ${delayed_sinogram} ${num_iterations}

cleanup=1
if [ $cleanup == 1 ]; then
	rm "fansums_for_"*
	rm ${factors}"_"*
fi

echo "Estimated Randoms sinogram and saved as:" ${OutputFilename}
exit 0
