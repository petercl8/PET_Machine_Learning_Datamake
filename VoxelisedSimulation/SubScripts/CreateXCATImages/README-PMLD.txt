We have modified CreateXCATImage.sh to do a number of things:

1) Generate a phantom section with the default standardized uptake values (SUVs). This is phantom 1.
2) Use a STIR utility to look at the total activity
3) Modify the activity levels the to-be-generated generated phantom section (phantom 2)
4) Generate the phantom with the modified activity levels
5) Compare the total activity of phantom 1 with phantom 2.
6) If phantom 2 is outside of the user-defined variation, complete steps 3-5 again until phantom 2 has an acceptable activity level.

This last step is useful to avoid accidentally setting a very large organ to a very large activity, resulting in a very long simulation time.