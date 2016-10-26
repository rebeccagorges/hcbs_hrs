**Rebecca Gorges
**October 2016
**Uses hrs_sample3.dta
**First pass at first stage of potential IVs from the HCBS waiver data
**Limits dataset to 1998-2012 waves, age 70+ 

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

//log using `logpath'\iv_prelim_log.txt, text replace
log using E:\hrs\logs\iv_prelim_log.txt, text replace

//local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
local data E:\hrs\data

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

somehow classify as waivers aimed at 65+ vs others? using the waiver name?
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

**home care = 3 versions
gen hctreat1=1 if r_sr_ltc_cat==2
replace hctreat1=0 if r_sr_ltc_cat==1 | r_sr_ltc_cat==3
tab hctreat1 r_sr_ltc_cat, missing
la var hctreat1 "Home care (med) vs HC+NH or NH only"

gen hctreat2=1 if r_sr_ltc_cat2==2
replace hctreat2=0 if r_sr_ltc_cat2==1 | r_sr_ltc_cat2==3
tab hctreat2 r_sr_ltc_cat2, missing
la var hctreat2 "Home care (med or other) vs HC+NH or NH only"

gen hctreat3=1 if r_sr_ltc_cat3==2
replace hctreat3=0 if r_sr_ltc_cat3==1 | r_sr_ltc_cat3==3
tab hctreat3 r_sr_ltc_cat3, missing
la var hctreat3 "Home care (med,other,helper) vs HC+NH or NH only"

sum svc_code_count_sy  if dem_any_vars_ind==1 & rmedicaid_sr==1,detail

local wvrvars wvr_count_sy svc_code_count_sy 
foreach name in `wvrvars' {
	xtile `name'4=`name',nq(4)
	xtile `name'2=`name',nq(2)
	} 
	
tab svc_code_count_sy4,gen(svc_code_count_sy4_)

//ivregress
*create indicators from categorical variables
tab age_cat2, missing

*use in place of cat 5+6 in models
gen age_cat2_ind_gt84=1 if inlist(age_cat2,5,6)
replace age_cat2_ind_gt84=0 if inlist(age_cat2,1,2,3,4)

tab r_race_eth_cat,gen(r_race_eth_cat)
rename r_race_eth_cat2 r_re_black
rename r_race_eth_cat3 r_re_hisp
rename r_race_eth_cat4 r_re_other

**use assets only bc highly correlated with income
pwcorr hatota5 hitot5
tab hatota5, gen(hatota5_)

local xvars age_cat2_ind1 age_cat2_ind2 age_cat2_ind3 age_cat2_ind4 ///
age_cat2_ind5 age_cat2_ind6 age_cat2_ind_gt84 r_female_ind r_re_black r_re_hisp r_re_other ///
r_married hanychild ed_hs_only hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
rshlt_fp rhibp_sr rdiab_sr rcancr_sr rlung_sr rheart_sr ///
rstrok_sr rpsych_sr rarthr_sr radlimpair dem_any_vars_ind

//need lagged x variables
sort hhidpn year
foreach x in `xvars'{
by hhidpn: gen `x'_n1=`x'[_n-1]
}

**drop observations
drop if age_cat2==1 //<70
drop if year==1998 //don't have lagged variables
**use census regions to drop people outside of the US
tab rcendiv,missing
drop if rcendiv==11 | rcendiv==.m
tab state, missing
drop if state=="PR" | state=="ZZ" | state=="RI" | state=="." | state=="AK"

tab state,missing

tab incomeltp25 hatota5_1, missing
**remember income variable is created for >70 group
foreach x in `xvars' `xvars2'{
tab `x' if !missing(hctreat1),missing
}

//(lagged) control variables list
//base cats are age 70-74; male, white, not married, no children, gt HS degree, low q assets ///
// no chronic diseases, no adl impairment, no dementia
local xvars2 age_cat2_ind3_n1 age_cat2_ind4_n1 age_cat2_ind_gt84_n1 ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1 ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 dem_any_vars_ind_n1

//same list but excluding dementia,assets since restricting to medicaid,dementia group
local xvars_nodem age_cat2_ind3_n1 age_cat2_ind4_n1 age_cat2_ind_gt84_n1 ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only /*hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1*/ ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 /*dem_any_vars_ind_n1*/

**************************************************************************
**************************************************************************
**Run first stage, 3 versions for 3 definitions of home care
foreach v in 1 2 3{
di "**********************************************"
di "**********************************************"
di "**********************************************"
di " Definition of home care # `v' "
di "**********************************************"
di "**********************************************"
di "**********************************************"
**waiver count **ri dropped because too few observations
di "Instrument = Waiver count (state-year level), OLS, full sample"
xi: reg hctreat`v' wvr_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
testparm wvr_count_sy
di "Instrument = Waiver count (state-year level), Logit, full sample"
xi: logit hctreat`v' wvr_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
testparm wvr_count_sy

**medicaid subsample
di "Instrument = Waiver count (state-year level), OLS, Medicaid sub-sample"
xi: reg hctreat`v' wvr_count_sy `xvars_nodem' i.state i.year ///
	if rmedicaid_sr==1 , vce(cluster hhidpn)
testparm wvr_count_sy
di "Instrument = Waiver count (state-year level), Logit, Medicaid sub-sample"
xi: logit hctreat`v' wvr_count_sy `xvars2' i.state i.year ///
	if rmedicaid_sr==1, vce(cluster hhidpn)
testparm wvr_count_sy

**income < 25% subsample
di "Instrument = Waiver count (state-year level), OLS, Income<25% sub-sample"
xi: reg hctreat`v' wvr_count_sy `xvars_nodem' i.state i.year ///
	if incomeltp25==1 , vce(cluster hhidpn)
testparm wvr_count_sy
di "Instrument = Waiver count (state-year level), Logit, Income<25% sub-sample"
xi: logit hctreat`v' wvr_count_sy `xvars2' i.state i.year ///
	if incomeltp25==1, vce(cluster hhidpn)
testparm wvr_count_sy

**assets < 20% subsample
tab incomeltp25 hatota5_1, missing

**medicaid + dementia subsample
di "Instrument = Waiver count (state-year level), OLS, "
di "Medicaid, dementia sub-sample"
xi: reg hctreat`v' wvr_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)
testparm wvr_count_sy

di "Instrument = Waiver count (state-year level), Logit, "
di "Medicaid, dementia sub-sample"
xi: logit hctreat`v' wvr_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)
testparm wvr_count_sy

**************************************************************************
**service code count, full sample
di "Instrument = Service code count (state-year level), OLS, Full sample"
xi: reg hctreat`v' svc_code_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
testparm svc_code_count_sy
di "Instrument = Service code count (state-year level), Logit, Full sample"
xi: logit hctreat`v' svc_code_count_sy `xvars2' i.state i.year , vce(cluster hhidpn)
testparm svc_code_count_sy

di "Instrument = Quartile Service code count (state-year level), OLS, "
di "Full sample"
xi: reg hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars2' i.state i.year , vce(cluster hhidpn)
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 
di "Instrument = Quartile Service code count (state-year level), Logit, "
di "Full sample"
xi: logit hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars2' i.state i.year , vce(cluster hhidpn)
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 

**************************************************************************
**service code count, medicaid sample
di "Instrument = Service code count (state-year level), OLS"
di "Medicaid sub-sample"
xi: reg hctreat`v' svc_code_count_sy `xvars_nodem' i.state i.year ///
	if rmedicaid_sr==1  , vce(cluster hhidpn)
testparm svc_code_count_sy
di "Instrument = Service code count (state-year level), Logit"
di "Medicaid sub-sample"
xi: logit hctreat`v' svc_code_count_sy `xvars_nodem' i.state i.year ///
	if rmedicaid_sr==1  , vce(cluster hhidpn)
testparm svc_code_count_sy
	
di "Instrument = Quartile Service code count (state-year level), OLS, "
di "Medicaid sub-sample"
xi: reg hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if rmedicaid_sr==1 , vce(cluster hhidpn)	
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 
di "Instrument = Quartile Service code count (state-year level), Logit, "
di "Medicaid sub-sample"
xi: logit hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if rmedicaid_sr==1 , vce(cluster hhidpn)	
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 

**************************************************************************
**service code count, income<25% sample
di "Instrument = Service code count (state-year level), OLS"
di "Income<25% sub-sample"
xi: reg hctreat`v' svc_code_count_sy `xvars_nodem' i.state i.year ///
	if incomeltp25==1  , vce(cluster hhidpn)
testparm svc_code_count_sy
di "Instrument = Service code count (state-year level), Logit"
di "Income<25% sub-sample"
xi: logit hctreat`v' svc_code_count_sy `xvars_nodem' i.state i.year ///
	if incomeltp25==1  , vce(cluster hhidpn)
testparm svc_code_count_sy
	
di "Instrument = Quartile Service code count (state-year level), OLS, "
di "Income<25% sub-sample"
xi: reg hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if incomeltp25==1 , vce(cluster hhidpn)	
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 
di "Instrument = Quartile Service code count (state-year level), Logit, "
di "Income<25% sub-sample"
xi: logit hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if incomeltp25==1 , vce(cluster hhidpn)	
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 

**************************************************************************
**service code count, dementia, medicaid sample
di "Instrument = Service code count (state-year level), OLS"
di "Medicaid, Dementia sub-sample"
xi: reg hctreat`v' svc_code_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1  , vce(cluster hhidpn)
testparm svc_code_count_sy
di "Instrument = Service code count (state-year level), Logit"
di "Medicaid, Dementia sub-sample"
xi: logit hctreat`v' svc_code_count_sy `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1  , vce(cluster hhidpn)
testparm svc_code_count_sy
	
di "Instrument = Quartile Service code count (state-year level), OLS, "
di "Medicaid, Dementia sub-sample"
xi: reg hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)	
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 
di "Instrument = Quartile Service code count (state-year level), Logit, "
di "Medicaid, Dementia sub-sample"
xi: logit hctreat`v' svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 ///
	`xvars_nodem' i.state i.year if dem_any_vars_ind==1 & rmedicaid_sr==1 , vce(cluster hhidpn)	
testparm svc_code_count_sy4_2 svc_code_count_sy4_3 svc_code_count_sy4_4 

**************************************************************************	
**dementia service codes, full sample
di "Instrument = Dementia Service code count (state-year level), OLS, "
di "Full sample"
xi: reg hctreat`v' svc_code_demsp `xvars2' i.state i.year , vce(cluster hhidpn)
testparm svc_code_demsp 
di "Instrument = Dementia Service code count (state-year level), Logit, "
di "Full sample"
xi: logit hctreat`v' svc_code_demsp `xvars2' i.state i.year , vce(cluster hhidpn)
testparm svc_code_demsp 

**medicaid subsample
di "Instrument = Dementia Service code count (state-year level), OLS, "
di "Medicaid-dementia sub-sample"
xi: reg hctreat`v' svc_code_demsp `xvars_nodem' i.state i.year ///
	if rmedicaid_sr==1, vce(cluster hhidpn)
testparm svc_code_demsp 
di "Instrument = Dementia Service code count (state-year level), Logit, "
di "Medicaid sub-sample"
xi: logit hctreat`v' svc_code_demsp `xvars_nodem' i.state i.year ///
	if rmedicaid_sr==1, vce(cluster hhidpn)
testparm svc_code_demsp 

**Income<25% subsample
di "Instrument = Dementia Service code count (state-year level), OLS, "
di "Income<25% sub-sample"
xi: reg hctreat`v' svc_code_demsp `xvars_nodem' i.state i.year ///
	if incomeltp25==1, vce(cluster hhidpn)
testparm svc_code_demsp 
di "Instrument = Dementia Service code count (state-year level), Logit, "
di "Income<25% sub-sample"
xi: logit hctreat`v' svc_code_demsp `xvars_nodem' i.state i.year ///
	if incomeltp25==1, vce(cluster hhidpn)
testparm svc_code_demsp 

**dementia service codes, medicaid and dementia sample
di "Instrument = Dementia Service code count (state-year level), OLS, "
di "Medicaid-dementia sub-sample"
xi: reg hctreat`v' svc_code_demsp `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1, vce(cluster hhidpn)
testparm svc_code_demsp 
di "Instrument = Dementia Service code count (state-year level), Logit, "
di "Medicaid-dementia sub-sample"
xi: logit hctreat`v' svc_code_demsp `xvars_nodem' i.state i.year ///
	if dem_any_vars_ind==1 & rmedicaid_sr==1, vce(cluster hhidpn)
testparm svc_code_demsp 

}
**************************************************************************

log close
