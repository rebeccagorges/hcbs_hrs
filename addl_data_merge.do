**Rebecca Gorges
**August 2016
**Starts with rand_waves3to11.dta dataset (long format)
**Adds in variables from other HRS datasets
**   Rand family dataset
**   Dementia probability dataset (user contributed, Hurd 2013 NEJM paper)
**   HRS xwave cognition dataset
**Final dataset is saved as rand_addl_ds_3.dta

** Note, additional data added in impute_dementia_probability.do file: 
**	 HRS survey, IQCODE components for proxy interview cognition measure
**	 ADAMS dementia diagnosis

**Revisions
**3/22/17: Updated to use Rand 2012 family dataset; HRS cognition ds through 2014

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\setup2_log.txt, text replace
//log using E:\hrs\logs\setup1_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

****************************************************************************
**Rand family dataset **up to wave 11 only
****************************************************************************
**family dataset through 2012 (wave 11) as of March 2017
/*
use `data'\public_raw\randhrsfam1992_2012v1_STATA\randhrsfamr1992_2012v1.dta, clear
keep *hhidpn *hhid pn inw* *ndau *hlpadlkn *hlpiadlkn *resdkn *lv10mikn *diedkn
save rand_fam_trunc.dta, replace  
*/
**need to convert this ds from wide to long format
forvalues i=3/11{
use rand_fam_trunc.dta, clear

**keep only specific wave variables
keep hhidpn inw`i' h`i'ndau *`i'hlpadlkn *`i'hlpiadlkn *`i'resdkn *`i'lv10mikn *`i'diedkn 

gen year=`i'*2+1990
gen wave=`i'

*only keep persons who had an interview in the specific wave
drop if inw`i'==0 
drop inw`i'

**rename variables that are both r/s variables
local rsvars hlpadlkn hlpiadlkn

foreach v in r s {
	foreach name in `rsvars' {
		rename `v'`i'`name' `v'`name'
		}
	
	}
	
**rename household variables	
local hhvars ndau resdkn lv10mikn diedkn
foreach name in `hhvars' {
	rename h`i'`name' h`name'
	}	
		
save rand_fam_w`i'.dta, replace
}

*************************************************************
**merge waves 3-11 into the Rand main, long dataset
*************************************************************

*combine into single dataset of family level data
use rand_fam_w3.dta, clear

forvalues i=4/11{
append using rand_fam_w`i'.dta
}

**check for duplicates in the family dataset
sort hhidpn year
by hhidpn year: gen dup1=_n
tab dup1, missing

drop dup1
save rand_fam_allwaves.dta, replace

**merge Rand family dataset into main dataset
use rand_waves3to11.dta, clear
capture drop _merge

merge 1:1 hhidpn wave using rand_fam_allwaves.dta
tab wave if _merge==3

tab rhlpadlkn year, missing
tab hlv10mikn year, missing

**check for duplicates
sort hhidpn year
by hhidpn year: gen dup1=_n
tab dup1, missing

sort hhid pn year
by hhid pn year: gen dup2=_n
tab dup2, missing

drop dup1 dup2

drop _merge
save rand_addl_ds_1.dta, replace

****************************************************************************
**Probability of dementia 1998-2006 waves only
****************************************************************************
use `data'\public_raw\DementiaPredictedProbabilities\pdem_withvarnames.dta, clear

gen year=prediction_year-1
la var year "Interview year=prediction year-1"

drop hhid pn

sort hhidpn year 

save `data'\dementia_prob.dta,replace

use rand_addl_ds_1.dta, clear
sort hhidpn year 

merge 1:1 hhidpn year using dementia_prob.dta
tab year if _merge==3, missing

drop _merge
save `data'\rand_addl_ds_2.dta, replace

****************************************************************************
**Xwave cognition imputation dataset (for self interviews only)
****************************************************************************

**first set up cognition dataset from wide to long format
use `data'\public_raw\CogImpV5.0\COGIMP9214A_R.dta, clear
rename *,l

egen hhidpn=concat(hhid pn)
destring hhidpn, replace

**check for duplicates
sort hhidpn 
by hhidpn : gen dup1=_n
tab dup1, missing

sort hhid pn 
by hhid pn : gen dup2=_n
tab dup2, missing

drop dup1 dup2

save cogimpds_raw.dta, replace

**get individual wave ds, then combine
forvalues i=3/11{
use cogimpds_raw.dta, clear

keep hhidpn r`i'status r`i'imrc r`i'dlrc r`i'ser7 r`i'bwc20 r`i'mo r`i'dy r`i'yr r`i'dw ///
r`i'scis r`i'cact r`i'pres r`i'vp r`i'vocab r`i'mstot r`i'cogtot

gen year=`i'*2+1990
gen wave=`i'

keep if r`i'status==1 //only keep completed self interviews with part d questions asked
drop r`i'status

**rename variables with common variable names
local varlist imrc dlrc ser7 bwc20 mo dy yr dw scis cact pres vp vocab mstot cogtot

foreach name in `varlist'{
	rename r`i'`name' r`name'
	}

save cogimp`i'.dta,replace
}	

**merge datasets
use cogimp3.dta, clear
forvalues i=4/11{
append using cogimp`i'.dta
}

save cogimpds_long.dta,replace

**merge into main dataset
use rand_addl_ds_2.dta,replace
sort hhidpn year 

merge 1:1 hhidpn year using cogimpds_long.dta
tab year if _merge==3, missing
tab rproxy if _merge==1, missing
drop if _merge==2

drop _merge

sort hhid pn year
by hhid pn year: gen dup=_n
tab dup, missing

sort hhidpn year
by hhidpn year: gen dup1=_n
tab dup1, missing

li hhidpn hhid pn year if dup1==1 & dup==2
drop dup1 dup

save `data'\rand_addl_ds_3.dta, replace

*************************************************************
log close
