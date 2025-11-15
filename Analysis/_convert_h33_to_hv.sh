#! /bin/sh

# Convert intf 3.3 to STIR intf. 
# Not called in any of the main scripts, but here for use if needed.
input=FOVattncylinder 
output=FOVattncylinder

sed -e "s/total number of images *:=\(.*\)/matrix size[3] := \1/i" -e "s/data offset in bytes/data offset in bytes[1]/i" -e "s#slice thickness (pixels)#scaling factor (mm/pixel) [3]#i"  -e "s/INTERFILE *:=/INTERFILE :=\nnumber of dimensions := 3/i" -e "s/short float/float/i" -e "s/.*matrix axis label.*//i" -e "s/type of data *:= *tomographic/type of data := PET/i" ${input}".h33" > ${output}".hv"