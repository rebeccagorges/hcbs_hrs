**Rebecca Gorges
**August 2016
**Starts with rand_waves3to11.dta dataset (long format)
**Adds in variables from other HRS datasets
**   Rand family dataset
**   Dementia probability dataset (user contributed, Hurd 2013 NEJM paper)
**Final dataset is saved as 

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\setup2_log.txt, text replace
//log using E:\hrs\logs\setup1_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

****************************************************************************
**Rand family dataset **up to wave 10 only
****************************************************************************
**family dataset only through 2010 (wave 10) data as of August 2016
use `data'\public_raw\rndfamC_stata\StataSE\rndfamr_c.dta, clear
keep *hhidpn *hhid pn inw* *ndau *hlpadlkn *hlpiadlkn
save rand_fam_trunc.dta, replace  

**need to convert this ds from wide to long format
forvalues i=3/10{
use rand_fam_trunc.dta, clear

**keep only specific wave variables
keep hhidpn inw`i' h`i'ndau *`i'hlpadlkn *`i'hlpiadlkn

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
local hhvars ndau 
foreach name in `hhvars' {
	rename h`i'`name' h`name'
	}	
		
save rand_fam_w`i'.dta, replace
}

**merge waves 3-10 into the Rand main, long dataset

*************************************************************
** Something is wrong with this merge, resulting ds missing values after wave 3!!! 
*************************************************************

*************************************************************

use rand_waves3to11.dta, clear

forvalues i=3/10{
merge 1:1 hhidpn wave using rand_fam_w`i'.dta
tab wave if _merge==3
drop if _merge==2
drop _merge
}

/*
**manually do wave 10 to check why this wave has observations where _merge==2
use rand_waves3to11.dta, clear
merge 1:1 hhidpn wave using rand_fam_w10.dta
**2 observations in wave 10 have family file, but missing in rand ds 
**have .k=no children; .u=unmarried in family file, so drop from ds since
**family variables don't contain any information anyway.
*/

save rand_addl_ds_1.dta, replace

use rand_addl_ds_1.dta, clear
tab rhlpadlkn wave, missing

****************************************************************************
**Probability of dementia 1998-2006 waves only
****************************************************************************
use `data'\public_raw\DementiaPredictedProbabilities\pdem_withvarnames.dta

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

log close
