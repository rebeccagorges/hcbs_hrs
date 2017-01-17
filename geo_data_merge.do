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

**open original file from Jing
local jdpath "C:\Users\Rebecca\Documents\UofC\research\hcbs\from_jing_20161006_data"

use `jdpath'\reg_ready.dta


/*

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

drop if _merge==2 //mostly years not in my main dataset 
drop _merge

sort state year

merge m:1 state year using hcbs_waivers_tomerge.dta
tab _merge
 
tab state if _merge==1
tab year if _merge==1 & state=="RI"

**do 2nd time, just bringing in the waiver count variable using interview year
sort state year

merge m:1 state riwendy using hcbs_waivers_tomerge2.dta, gen(merge2)
tab merge2

/* notes re missing state-years
AZ had no waivers
DC first waiver in 1999
RI last waiver in 2009
VT last waiver in 2005
*/

**fill in missing values to 0
local var wvr_count_sy reciptotall_sy dollartotall_sy svc_code_count_sy svc_code_demsp 
foreach v in `var'{
replace `v'=0 if _merge==1
}

forvalues c = 1/30{
replace svc_code_`c'_sy=0 if _merge==1
}

replace wvr_count_sy2=0 if merge2==1 //for interview year merged version

tab riwendy if _merge==2 //mostly years outside of date range (pre 1998 or after 2012)
drop if _merge==2

save hrs_sample2.dta, replace

use  hrs_sample2.dta, clear
forvalues c = 1/30{
tab svc_code_`c'_sy, missing
}

***************************************************


***************************************************
log close


