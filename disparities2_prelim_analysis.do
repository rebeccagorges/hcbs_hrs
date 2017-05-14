**Rebecca Gorges
**May 2017
**Disparities project preliminary analysis for PhD workshop presentation May 2017
**Uses hrs_sample_disparities.dta
**Limits dataset to 1998-2012 waves

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\dispar_prelim_analysis_log.txt, text replace
//log using E:\hrs\logs\dispar_prelim_analysis_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
**additional coding for disparities project
use hrs_sample_disparities.dta, clear
*******************************************************



*******************************************************
log close
