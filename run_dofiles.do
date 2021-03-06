**do file for hcbs work RG summer 2016

**directory for do files
local dofiles C:\Users\Rebecca\Documents\GitHub\hcbs_hrs

**keep only required variables from RAND ds, set up as long data format 
**(each r has multiple rows, one for each wave)
//do `dofiles'/combine_waves_long_ds.do

**add data from Rand family file, probability of dementia
//do `dofiles'/addl_data_merge.do

**initial outcomes variables coding
//do `dofiles'/coding_outcomes.do

**generate IQCODE, ADAMS datasets to merge in next step
//do `dofiles'/impute_dementia_preprocessing.do 

**impute dementia probabilty following Hurd method
do `dofiles'/impute_dementia_probability.do

**check dementia imputations by replicating Hurd tables
//do `dofiles'/impute_dementia_checks.do

**home care variables created from raw interview questions,helper files
do `dofiles'/home_care.do

*********************************************
**State Medicaid LTC data processing

//do `dofiles'/waivers_master_list_pre.do //original merge of 2 spreadsheets
//to send to LW for collecting missing target population data

**prepares USCF provided waiver files for merge
//do `dofiles'/waiver_file_prep.do //old version
//do `dofiles'/waiver_file_prep_v2.do 

**prepares Eiken Truven Report HCBS Expenditures data for merge
//do C:\Users\Rebecca\Documents\GitHub\misc_data_setup/mcaid_expend_data_prep.do

**prepares KFF HCBS Program data for merge
//do C:\Users\Rebecca\Documents\GitHub\misc_data_setup/kff_hcbs_data_prep.do

**merges the three Medicaid state-year level datasets together
//do `dofiles'/state_data_merge.do

**bring in state level data
do `dofiles'/geo_data_merge.do

******************************************************
**variable cleaning prior to sample size checks
do `dofiles'/coding_variables2.do

**first pass at sample sizes - preliminary
//do `dofiles'/sample_size_tables.do

**exploring iv's
//do `dofiles'/iv_work.do

**additional exploratory work, including time trends
//do `dofiles'/sample_size_tables_2.do
