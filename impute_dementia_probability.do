**Rebecca Gorges
**August 2016
**Based on code from Amy Kelley , Evan Bollends Lund via Github
**Merges meain ds with cleaned outcomes hrs_waves3to11_vars.dta
**with proxy dementia iqcode proxycog_allyrs2.dta

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\dem_prob2_log.txt, text replace
//log using E:\hrs\logs\setup1_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**********************************************************************************
** Merge in proxy IQCODE to main dataset **
**********************************************************************************
**first merge datasets
**open cleaned main rand dataset
use hrs_waves3to11_vars.dta, clear
sort hhid pn year

merge 1:1 hhid pn year using proxycog_allyrs2.dta
tab _merge rproxy, missing
tab year _merge if rproxy==1 & age_lt_65==0
drop _merge

sum iqmean if rproxy==1
sum iqmean if rproxy==0
sum rcogtot if rproxy==0 & !missing(iqmean) //these obs have tics scores, set iqcode to missing
replace iqmean=. if rproxy==0

**how many obs do not have TICS or IQCODE?
gen iqcode_missing=0
replace iqcode_missing=1 if missing(iqmean)
tab iqcode_missing age_lt_65 if rproxy==1, missing

gen cog_missing=0
replace cog_missing=1 if iqcode_missing==1 & tics_missing==1
tab rproxy cog_missing if age_lt_70==0 & wave>3


**********************************************************************************
** Proxy cognition assessment IQCODE **
**********************************************************************************
**need to start with raw interview files



**********************************************************************************
** Calculate the dementia probability **
**********************************************************************************


save hrs_wproxycog.dta,replace


log close

