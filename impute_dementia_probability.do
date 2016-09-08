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
**open cleaned main rand dataset (includes Hurd p dementia variable)
use hrs_waves3to11_vars.dta, clear

replace prediction_year=year+1 if missing(prediction_year)

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
** Merge in ADAMS diagnosis **
**********************************************************************************
merge 1:1 hhid pn year using dementia_dx_adams_wave1_only.dta
**n=856 with wave 1 diagnosis
drop _merge

**********************************************************************************
** Check through variables used to for dementia probability algorithm **
**********************************************************************************
tab r_female_ind, missing
tab ragey_e, missing
tab rage_cat, missing

gen age_cat2=1 if ragey_e<70 & !missing(ragey_e)
replace age_cat2=2 if ragey_e>=70  & !missing(ragey_e)
replace age_cat2=3 if ragey_e>=75 & !missing(ragey_e)
replace age_cat2=4 if ragey_e>=80 & !missing(ragey_e)
replace age_cat2=5 if ragey_e>=85 & !missing(ragey_e)
replace age_cat2=6 if ragey_e>=90 & !missing(ragey_e)
tab age_cat2, gen(age_cat2_ind)
label define age_cat2 1 "Age<70" 2 "Age 70-74" 3 "Age 75-79" 4 "Age 80-84" ///
5 "Age 85-89" 6 "Age>=90"
label values age_cat2 age_cat2
tab age_cat2, missing

tab raeduc,missing

gen ed_hs_only=0 if !missing(raeduc)
replace ed_hs_only=1 if raeduc==3 | raeduc==2 //includes GED
tab ed_hs_only, missing

gen ed_gt_hs=raeduc>3 if !missing(raeduc)
tab ed_gt_hs raeduc, missing

la var ed_hs_only "High school education level indicator (includes GED)"
la var ed_gt_hs "GT high school educ level indicator"

tab radla, missing
la var radla "Some difficulty with ADLs, count"

tab riadlza, missing
la var riadlza "Some difficulty with IADLs, count"

sum iqmean, detail
tab rproxy, missing

**create the change variables (change from previous to current interview)
**note for first interview, sets change,prev variables = 0
local changevars rimrc rdlrc rser7 rbwc20 rmo rdy ryr rdw rscis rcact rpres rvp radla ///
riadlza iqmean rproxy 

foreach x of local changevars {
sort hhidpn year
by hhidpn: gen prev`x'=`x'[_n-1]
gen ch_`x'=`x'-prev`x'
gen miss`x'=prev`x'==.
replace ch_`x'=0 if ch_`x'==.
replace prev`x'=0 if prev`x'==.
}

gen rdates=rmo+rdy+ryr+rdw
by hhidpn: gen prevrdates=rdates[_n-1]
gen missrdates=prevrdates==.
gen ch_rdates=ch_rmo+ch_ryr+ch_rdy+ch_rdw
replace prevrdates=0 if prevrdates==.
replace ch_rdates=0 if ch_rdates==.


**********************************************************************************
** Calculate the dementia probability **
**********************************************************************************
/*note-most missing variables excluded due to collinearity
base categories are age<75, ls hs education, male, correct answers to each of 
the cognition questions*/

local bothvars age_cat2_ind3 age_cat2_ind4 age_cat2_ind5 age_cat2_ind6 ///
ed_hs_only ed_gt_hs r_female_ind ///
radla riadlza ch_radla ch_riadlza  missradla missriadlza ///
missrdates missrser7 missrscis missrcact missrpres missrimrc ///
missrdlrc 

local regvars  rdates rbwc20 rser7 rscis rcact rpres rimrc rdlrc ///
ch_rdates ch_rbwc20 ch_rser7 ch_rscis ch_rcact ch_rpres ///
ch_rimrc ch_rdlrc missrbwc20 

local proxyvars iqmean ch_iqmean ///
ch_rproxy prevrdates prevrser7 prevrpres prevrimrc prevrdlrc


oprobit dx `bothvars' `regvars' if rproxy==0
predict pself if rproxy==0
oprobit dx `bothvars' `proxyvars' if rproxy==1
predict pdem if rproxy==1
replace pdem=pself if rproxy==0

histogram pdem if rproxy==1
histogram pdem if rproxy==0
histogram pdem

preserve
keep hhidpn rproxy pdem prob_dementia dx_adams year
rename prob_dementia prob_hurd
save `data'\pdem_withvarnames_allwaves.dta, replace

log close

