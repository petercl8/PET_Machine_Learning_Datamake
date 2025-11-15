#=======================================================
## Changes the activity values in the XCAT par file.
## Takes percent variations from the default XCAT-provided values as input and picks a number from a uniform distribution between those values. 
## Ensures that the total summed activities does not vary from the default by more than a provided amount
## Outputs a new par file with all parameters unchanged except for the new activities. Adds a line at the end with the total activity sum. 
#=======================================================

import re
import numpy as np
import matplotlib.pyplot as plt
import sys

def read_pars(par_file):
    """ Read and parse the parameter file.
        Input: 
            par_file - Absolute path to the parameter file.
        Output:
            pars - Dictionary of all variable names and values.
            act_pars - Dictionary of all activity keys and values. """
    pars = {}
    act_pars = {}
    with open(par_file, 'r') as file:
        for line in file:
            key_value = re.split(r'=', line, maxsplit=1) # Split keys and values on '='
            if len(key_value) == 2:
                key = key_value[0].strip() # assigns key after removing whitespace
                value = key_value[1]
                value = re.split(r'#', value)[0].strip() # Remove comments which occur after key-value pairs
                pars[key] = value # updates dictionary to include the new key-value pair.
                if "act" in key and "fract" not in key and "factor" not in key and "phan" not in key and "unit" not in key: # Only grab actual activity keys. This includes keys with "_act" and "_activity"
                    organ_key = key
                    act_pars[organ_key] = value
    return pars, act_pars

def sum_values(par_dict):
    """ Sum all values in a dictionary. Used to check that the sums of original and new activity values are approximately equal.
        Input: 
            par_dict - Dictionary of key/value pairs in the parameter file.
        Output:
            value_sum - The sum of all values in the dictionary. """
    value_sum = 0
    for key in par_dict:
        value_sum += float(par_dict[key])
    #print("The sum of all values is " + str(value_sum))
    return value_sum

def gen_value(og_value, organ, prev_value):
    """ Generate a random float between two extreme values, based on an input value. Used to generate new activity values.
        If two organs are symmetric, (ex. right and left lung,) refer to the assigned value of the other one to ensure they are similar.
        notes: -Ovaries have been ommitted from the list of symmetric organs as the sample parameter file had them initialized at different values.
            This could be edited later.
               -myocardium and blood have four components (LV, RV, LA, RA) and all are considered symmetric organs (given similar activities).
        Input: 
            og_value - An initial value to serve as a reference point.
            organ - The key from the activity dictionary.
            prev_value - The value of the previous key to reference in the generation of values for symmetric organs.
        Output:
            new_value - New value based on multiplicative factors chosen."""

    # Diseased organs
    if np.random.uniform(0, 1) <= fraction_diseased:
        min_value = 0
        max_value = max_SUV_diseased

    # Symmetric organs
    elif organ in ["l_kidney_cortex_activity", "r_kidney_cortex_activity", "l_kidney_medulla_activity", "r_kidney_medulla_activity", "r_renal_pelvis_activity", "l_renal_pelvis_activity", "l_lung_activity", "r_lung_activity", "myoLV_act", "myoRV_act", "myoLA_act", "myoRA_act", "bldplRV_act", "bldplRA_act", "bldplLV_act", "bldplLA_act", "coronary_vein_activity", "coronary_art_activity", "lbreast_activity", "rbreast_activity"]:
        min_value = og_value - float(passed_vars[4])*og_value
        max_value = og_value + float(passed_vars[4])*og_value

    # Organs with default values smaller than 10
    elif og_value <= 2:
        min_value = og_value - float(passed_vars[2])*og_value
        max_value = og_value + float(passed_vars[2])*og_value 

    # Organs with default values greater than 10
    else: 
        min_value = og_value - float(passed_vars[3])*og_value
        max_value = og_value + float(passed_vars[3])*og_value
    
    if min_value < 0:
        min_value = 0   
    
    new_value = round(np.random.uniform(min_value, max_value), 3)
    return new_value




def change_values(act_pars):
    """ Parse activity dictionary and randomly generate a new activity for each organ.
        Input: 
            act_pars - Original activity dictionary.
        Output:
            new_act_pars - New activity dictionary, with the same organ keys. """
    new_act_pars = {}
    prev_value = 0 # Save the previous organ's value to use with symmetric organs
    for organ in act_pars:
        og_activity = act_pars[organ]
        new_activity = gen_value(float(og_activity), organ, prev_value)
        new_act_pars[organ] = new_activity
        prev_value = new_activity
    return new_act_pars

def write_file(all_pars, act_pars, filename):
    """ Update activities in dictionary of all parameters and write all parameters to a new file.
        Input: 
            all_pars - Original dictionary of all parameters.
            act_pars - New activity dictionary.
            filename - Output filename. """
    for organ in act_pars:
        all_pars[organ] = act_pars[organ]
    f = open(filename, "w")
    for key in all_pars:
        f.write(str(key) + " = " + str(all_pars[key]) + "\n")


#==================================================================

passed_vars = sys.argv
'''
Items in the list to pass the script:
(All are floats between 0 and 1 marking the maximum/minimum percent variation from the default values in general.samp.par, setting the boundaries of random number generation.)
0 = script name (ChangeXCATPars.py)
1 = +/- variation allowed in total sum of activities [default: 0.25]
2 = +/- variation allowed in default activities smaller than 10 [default: 0.75]
3 = +/- variation allowed in default activities larger than 10 [default: 0.75]
4 = +/- difference allowed between symmetric organs (ex. left kidney and right kidney) [default: 0.1]
5 = max SUV of diseased tissue
6 = fraction o diseased organs which are diseased
7 = XCAT_PATH (path to XCAT install directory)
8 = normalize to typical whole body PET injected activity (300-400 MBq) (1) or not (0)
'''

#par_file = str(passed_vars[7]) + "/general.samp.par"
par_file = "./SubScripts/CreateXCATImages/XCAT_V2_LINUX/general.samp_3mmVox-SUVs.par"

output = "./SubScripts/CreateXCATImages/general.samp_random_act.par"

vis = 0 # Visualize distribution?
num_runs = 500 # Number of times to generate total activities within the accepted range when visualizing

par_dict, act_dict = read_pars(par_file)
original_sum = sum_values(act_dict) #1590

variation = original_sum * float(passed_vars[1])
upper_threshold = float(original_sum) + variation
lower_threshold = float(original_sum) - variation

max_SUV_diseased = float(passed_vars[5])
fraction_diseased = float(passed_vars[6])

# Change individual activity values and check if they're within the allowed range of difference in the total activity.
# Reroll the values until they're within the range.
if vis == 0:
    threshold_check = 0
    while threshold_check == 0:
        new_act_dict = change_values(act_dict)
        val_sum = sum_values(new_act_dict)
        if (val_sum < upper_threshold) and (val_sum > lower_threshold):
            threshold_check = 1
else:
    i = 0 
    val_list = []
    while i < num_runs:
        threshold_check = 0
        while threshold_check == 0:
            new_act_dict = change_values(act_dict)
            val_sum = sum_values(new_act_dict)
            if (val_sum < upper_threshold) and (val_sum > lower_threshold):
                threshold_check = 1
                val_list.append(val_sum)
        i += 1
    plt.hist(val_list, 20, color="blue")
    plt.scatter(original_sum, 15, color="red")
    plt.show()

if int(passed_vars[8]) == 1:
    norm_factor = 350000000/val_sum
    for organ in new_act_dict:
        new_act_dict[organ] = new_act_dict[organ]*norm_factor
    val_sum = sum_values(new_act_dict)

# Append total sum of activities to the end of the dictionary
par_dict["# Sum of all activity values"] = val_sum

write_file(par_dict, new_act_dict, output)

exit