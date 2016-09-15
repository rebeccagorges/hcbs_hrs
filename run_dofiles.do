**do file for hcbs work RG summer 2016

**directory for do files
local dofiles C:\Users\Rebecca\Documents\GitHub\hcbs_hrs

**keep only required variables from RAND ds, set up as long data format 
**(each r has multiple rows, one for each wave)
do `dofiles'/combine_waves_long_ds.do

**add data from Rand family file, probability of dementia
do `dofiles'/addl_data_merge.do

**initial outcomes variables coding
do `dofiles'/coding_outcomes.do

**generate IQCODE, ADAMS datasets to merg in next step
do `dofiles'/impute_dementia_preprocessing.do 

**impute dementia probabilty following Hurd method
do `dofiles'/impute_dementia_probability.do

**check dementia imputations by replicating Hurd tables
do `dofiles'/impute_dementia_checks.do


**home care variables created from raw interview questions,helper files
do `dofiles'/home_care.do

**first pass at sample sizes - preliminary
do `dofiles'/sample_size_tables.do
