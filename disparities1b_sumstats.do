**Rebecca Gorges
**September 2017
**Disparities project descriptive stats
**Uses hrs_sample_disparities.dta
**Limits dataset to 1998-2012 waves

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\dispar_sumstats_1b_log.txt, text replace
//log using E:\hrs\logs\dispar_sumstats_1b_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
use hrs_sample_disparities.dta, clear
tab year, missing

**************************************************************
**************************************************************
**By race,ethnicity look at use of LTSS by setting over time
**************************************************************
**Table 1: Just compare raw NH and Home care variables
**************************************************************




**************************************************************
**Table 2: Now use treatment (any home care) vs control (no home care; ie nursing home only)
**************************************************************

**************************************************************
log close
