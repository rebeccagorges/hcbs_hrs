**Rebecca Gorges
**August 2016
**Uses hrs_waves3to11_vars.dta
**Creates tabulations for initial sample size estimates
**Limits dataset to 1998-2012 waves, age 70+

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

//log using `logpath'\iv_prelim_log.txt, text replace
log using F:\hrs\logs\iv_prelim_log.txt, text replace

//local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
local data F:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
use hrs_sample3.dta, clear

*********************************************************
/*iv plan
different defs of home care (2 or 3)
different defs of dementia

potential ivs
number of waivers
number of service codes
specific service codes (any of 10,12,18)

divide number into quartiles, above/below median, any others

somehow classify as waivesr aimed at 65+ vs others? using the waiver name?
   this will take some work because all different names...

*/

**potential instruments
sum wvr_count_sy, detail
sum svc_code_count_sy , detail
tab svc_code_demsp , missing

la var svc_code_10_sy "Svc code 10: home health/home health aide"
tab svc_code_10_sy , missing
la var svc_code_12_sy "Svc code 12: personal care in home"
tab svc_code_12_sy , missing

tab r_sr_ltc_cat2, missing

tab r_sr_ltc_cat2 svc_code_demsp if r_sr_ltc_cat2!=0, chi
tab r_sr_ltc_cat2 svc_code_10_sy if r_sr_ltc_cat2!=0, chi

tab r_sr_ltc_cat svc_code_10_sy if r_sr_ltc_cat!=0, chi

gen hctreat=1 if r_sr_ltc_cat2==2
replace hctreat=0 if r_sr_ltc_cat2==1 | r_sr_ltc_cat2==3

tab hctreat r_sr_ltc_cat2, missing

sum svc_code_count_sy  if dem_any_vars_ind==1 & rmedicaid_sr==1,detail
reg hctreat svc_code_count_sy

local wvrvars wvr_count_sy svc_code_count_sy 
foreach name in `wvrvars' {
	xtile `name'4=`name',nq(4)
	xtile `name'2=`name',nq(2)
	} 
	

//ivregress
*create indicators from categorical variables
tab rage_cat,gen(rage_cat)
rename rage_cat3 rage_75_84
rename rage_cat4 rage_gt_84

tab r_race_eth_cat,gen(r_race_eth_cat)
rename r_race_eth_cat2 r_re_black
rename r_race_eth_cat3 r_re_hisp
rename r_race_eth_cat4 r_re_other

**use assets only bc highly correlated with income
pwcorr hatota5 hitot5
tab hatota5, gen(hatota5_)

local xvars rage_75_84 rage_gt_84 r_female_ind r_re_black r_re_hisp r_re_other ///
r_married hanychild ed_hs_only hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
rshlt_fp rhibp_sr rdiab_sr rcancr_sr rlung_sr rheart_sr ///
rstrok_sr rpsych_sr rarthr_sr radlimpair dem_any_vars_ind

//need lagged x variables
sort hhidpn year
foreach x in `xvars'{
by hhidpn: gen `x'_n1=`x'[_n-1]
}

local xvars2 rage_75_84_n1 rage_gt_84_n1 r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1 ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 dem_any_vars_ind_n1

//same list but excluding dementia,assets since restricting to medicaid,dementia group
local xvars_nodem rage_75_84_n1 rage_gt_84_n1 r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only  ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 

**drop observations
drop if rage_cat1==1 //<65
drop if year==1998 //don't have lagged variables
**use census regions to drop people outside of the US
tab rcendiv,missing
drop if rcendiv==11 | rcendiv==.m
tab state, missing
drop if state=="PR" | state=="ZZ" | state=="RI" | state=="." | state=="AK"

tab state,missing

local xvars2 rage_75_84_n1 rage_gt_84_n1 r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1 ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 dem_any_vars_ind_n1

**************************************************************************
**waiver count **ri dropped because too few observations
xi: reg hctreat wvr_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
xi: reg hctreat wvr_count_sy `xvars2' i.state i.year
xi: logit hctreat wvr_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
xi: logit hctreat wvr_count_sy `xvars2' i.state i.year

xi: reg hctreat wvr_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)
xi: reg hctreat wvr_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1 
xi: logit hctreat wvr_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)
xi: logit hctreat wvr_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1 

**************************************************************************
**service code count, full sample
xi: reg hctreat svc_code_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
xi: reg hctreat svc_code_count_sy `xvars2' i.state i.year
xi: logit hctreat svc_code_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
xi: logit hctreat svc_code_count_sy `xvars2' i.state i.year

tab svc_code_count_sy4,gen(svc_code_count_sy4_)
xi: reg hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars2' i.state i.year , vce(cluster hhidpn)
xi: reg hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars2' i.state i.year 
xi: logit hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars2' i.state i.year , vce(cluster hhidpn)
xi: logit hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars2' i.state i.year 

**************************************************************************
**service code count, dementia, medicaid sample
xi: reg hctreat svc_code_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1  , vce(cluster hhidpn)
xi: reg hctreat svc_code_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1  
xi: logit hctreat svc_code_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1  , vce(cluster hhidpn)
xi: logit hctreat svc_code_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1  	
	
xi: reg hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)	
xi: reg hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if dem_any_vars_ind==1 & rmedicaid_sr==1 
xi: logit hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)	
xi: logit hctreat svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if dem_any_vars_ind==1 & rmedicaid_sr==1 

**************************************************************************	
**dementia service codes, full sample
xi: reg hctreat svc_code_demsp `xvars2' i.state i.year , vce(cluster hhidpn)
xi: reg hctreat svc_code_demsp `xvars2' i.state i.year
xi: logit hctreat svc_code_demsp `xvars2' i.state i.year , vce(cluster hhidpn)
xi: logit hctreat svc_code_demsp `xvars2' i.state i.year


**dementia service codes, medicaid sample
xi: reg hctreat svc_code_demsp `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1, vce(cluster hhidpn)
xi: reg hctreat svc_code_demsp `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1
xi: logit hctreat svc_code_demsp `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1, vce(cluster hhidpn)
xi: logit hctreat svc_code_demsp `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1	

**************************************************************************



log close
