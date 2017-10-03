**Rebecca Gorges
**October 2016
**Merge in geographic data from Jing's dataset
**Process Medicaid waiver file and merge in

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\geo_data_merge_log.txt, text replace
//log using E:\hrs\logs\geo_data_merge_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**********************************************************
/*
**open original file from Jing
local jdpath "C:\Users\Rebecca\Documents\UofC\research\hcbs\from_jing_20161006_data"

use `jdpath'\reg_ready.dta

keep hhidpn shhidpn year wave state totpop ptotf ptotm p65m p65f p85m p85f ///
 hpicmb nhbed tot85 tot65 nhbed1k nhbed1k65 nhbed1k85 CCRC ALR ILR ttlhcbsexp homehealthppl ///
 ttlhcbsppl homehealthexp personalcareppl personalcareexp waiverppl waiverexp ///
 cmsttlhcbsexp cmsttlltcexp cmshcbswvexp cmspersonalcareexp cmshomehealthexp ///
 cms1915wvexp cms1115wvexp cms1929wvexp cms1115_1915_1932wvexp hcbsofltc ///
 skillednursingfacilities skillednursfactotalbeds skillednursfaccertifiedbeds ///
 nursingfacilities nursingfacilitiestotalbeds nursingfacilitiescertbeds ///
 homehealthagencies tot_pop_st tot_pop_us prop_totf_st prop_totf_us ///
 prop_totm_st prop_totm_us prop_nhw_st prop_nhw_us prop_nhb_st prop_nhb_us ///
 prop_har_st prop_har_us prop_otherrace_st prop_otherrace_us prop_age65upm_st /// 
 prop_age65upm_us prop_age65upf_st prop_age65upf_us prop_age85upm_st ///
 prop_age85upm_us prop_age85upf_st prop_age85upf_us prop_poverty_st ///
 prop_poverty_us hhinc_st hhinc_us employed_st employed_us unemployed_st ///
 unemployed_us skillednursingfacilities_st skillednursingfacilities_us ///
 skillednursfactotalbeds_st skillednursfactotalbeds_us ///
 skillednursfaccertifiedbeds_st skillednursfaccertifiedbeds_us ///
 nursingfacilities_st nursingfacilities_us nursingfacilitiestotalbeds_st ///
 nursingfacilitiestotalbeds_us nursingfacilitiescertbeds_st ///
 nursingfacilitiescertbeds_us homehealthagencies_st homehealthagencies_us ///
 nhbed_st nhbed_us

save geo_to_merge.dta, replace 

*/
**********************************************************
***********************************************k***********
**merge into dataset

use hrs_sample.dta, clear
drop _merge
sort hhidpn year

merge 1:1 hhidpn year using geo_to_merge.dta //bring in jd's dataset by wave year

tab year if _merge==2, missing 
li hhidpn year riwstat wave state if _merge==2 & year==2012
li hhidpn year riwstat wave state if _merge==1 

drop if _merge==2 // years not in my dataset 
drop if _merge==1 // 
**I suspect the 2 ids that don't match are related to JG using rand v. O as the 
** starting point while I'm now using v. P

tab _merge, missing

drop _merge

sort state year

**uses wave year (not interview year) to do the merge 
**(ex. if ivw was wave 10 (2010) but conducted in 2011, merge with 2010 waiver information)
//merge m:1 state year using hcbs_waivers_tomerge.dta
merge m:1 state year using Medicaid_state_data_combined.dta
tab _merge

**extra state-year from waiver spreadsheet - odd years, small states
tab year if _merge==2
tab state if _merge==2 & year==1998 
tab state if _merge==2 & year==2000 
tab state if _merge==2 & year==2002 
tab state if _merge==2 & year==2004 

drop if _merge==2

**what about interviews with no matched waiver information?
tab state if _merge==1
tab state if _merge==1 & year==1998
tab state if _merge==1 & year==2000
tab state if _merge==1 & year==2002
tab state if _merge==1 & year==2004
tab state if _merge==1 & year==2006
tab state if _merge==1 & year==2008
tab state if _merge==1 & year==2010

tab year if _merge==1 & state=="RI"
tab year if _merge==1

/* notes re missing state-years
AZ had no waivers
DC first waiver in 1999
RI last waiver in 2009
VT last waiver in 2005
*/

**fill in missing values to 0
**fix these with new variable names from updated waiver file!! add in variables for populations, etc!
local var wvr_count wvr_recipttot wvr_dollartot wvr_daystot scode_count
foreach v in `var'{
replace `v'=0 if _merge==1
}

forvalues i=1/13{
replace wvr_pop_`i'=0 if _merge==1
}

forvalues i=1/30{
replace scode_`i'_ind=0 if _merge==1
replace scode_`i'_recips=0 if _merge==1
replace scode_`i'_dollar=0 if _merge==1
replace scode_`i'_days=0 if _merge==1
}

foreach v in case_manag personal_home_care prof therapy respite residential ///
supplies_dme transit_drugs {
replace wvr_`v'_svc=0 if _merge==1
}

drop _merge

save hrs_sample2.dta, replace

use  hrs_sample2.dta, clear
forvalues c = 1/30{
tab scode_`c'_ind, missing
}



***************************************************
log close


