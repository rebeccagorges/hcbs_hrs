**do file for hcbs work RG summer 2016

**directory for do files
local dofiles C:\Users\Rebecca\Documents\GitHub\hcbs_hrs

**keep only required variables from RAND ds, set up as long data format 
**(each r has multiple rows, one for each wave)
do `dofiles'/combine_waves_long_ds.do

**add data from Rand family file, probability of dementia
do `dofiles'/addl_data_merge.do

**outcomes variables coding
do `dofiles'/coding_outcomes.do

**impute dementia probabilty following Hurd method
do `dofiles'/impute_dementia_preprocessing.do

do `dofiles'/impute_dementia_probability.do


**home care variables created from raw interview questions,helper files
do `dofiles'/home_care.do

**first pass at sample sizes - preliminary
do `dofiles'/sample_size_tables.do
