**Rebecca Gorges
**August 2016
**Based on code from Amy Kelley , Evan Bollends Lund via Github
**Merges meain ds with cleaned outcomes hrs_waves3to11_vars.dta
**with proxy dementia iqcode proxycog_allyrs2.dta
**full dataset with all variables: pdem_fullds_allwaves.dta
**dataset with just predicted dementia values: pdem_withvarnames_allwaves.dta

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
tab age_cat2 if !missing(dx) & rproxy==1, missing

tab raeduc,missing

gen ed_hs_only=0 if !missing(raeduc)
replace ed_hs_only=1 if raeduc==3 | raeduc==2 //includes GED
tab ed_hs_only, missing
tab ed_hs_only if !missing(dx) & rproxy==1, missing

gen ed_gt_hs=raeduc>3 if !missing(raeduc)
tab ed_gt_hs raeduc, missing

la var ed_hs_only "High school education level indicator (includes GED)"
la var ed_gt_hs "GT high school educ level indicator"

tab radla, missing
tab radla if !missing(dx) & rproxy==1, missing

la var radla "Some difficulty with ADLs, count"

tab riadlza, missing
tab riadlza if !missing(dx) & rproxy==1, missing
la var riadlza "Some difficulty with IADLs, count"

sum iqmean, detail
sum iqmean if !missing(dx) & rproxy==1, detail
tab rproxy, missing

gen missiqscore=1 if missing(iqmean) & rproxy==1
replace missiqscore=0 if !missing(iqmean) & rproxy==1
tab missiqscore rproxy, missing

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

**indicator for no previous wave interview
sort hhidpn year
by hhidpn: gen ivwno=_n
gen first_ivw_ind=1 if ivwno==1
replace first_ivw_ind=0 if ivwno>1
tab first_ivw_ind, missing
tab wave if first_ivw_ind==1, missing
drop ivwno

**check through the missing variable indicators for the two samples
**self interview prior to adams
tab ch_radl missradl if !missing(dx) & rproxy==0, missing
tab first_ivw_ind missradl if !missing(dx) & rproxy==0, missing //all b/c no interview
tab first_ivw_ind missriadlza if !missing(dx) & rproxy==0, missing
tab first_ivw_ind missrdates if !missing(dx) & rproxy==0, missing //3 b/c no interview
tab prevrproxy if missrdates==1 & first_ivw_ind==0 &  !missing(dx) & rproxy==0, missing //rest because proxy ivw

**proxy interveiw prior to adams
tab first_ivw_ind missradl if !missing(dx) & rproxy==1, missing //all b/c no interview
tab first_ivw_ind missriadlza if !missing(dx) & rproxy==1, missing
tab first_ivw_ind missrdates if !missing(dx) & rproxy==1, missing //2 b/c no interview
tab prevrproxy if missrdates==1 & first_ivw_ind==0 &  !missing(dx) & rproxy==1, missing //rest because proxy ivw

**so create two missing variables
gen noprevivw=first_ivw_ind
gen nocogprev=1 if prevrproxy==1
replace nocogprev=0 if prevrproxy==0 | first_ivw_ind==1
tab nocogprev, missing
la var noprevivw "Missing change adl / iadl bc no prev interview"
la var nocogprev "Missing change in tics scores bc prev interview by proxy"

**TICS components variables scissors, etc not imputed for all observations, indicator for this
gen misscog_scis_etc=1 if missing(rscis)
replace misscog_scis_etc=0 if !missing(rscis)
tab misscog_scis_etc if rproxy==0,missing
tab misscog_scis_etc if rproxy==0 & year==2006,missing

tab misscog_scis_etc if !missing(dx) & rproxy==0

**********************************************************************************
** Calculate the dementia probability **
**********************************************************************************
/*note-most missing variables excluded due to collinearity
base categories are age<75, ls hs education, male, correct answers to each of 
the cognition questions*/

la var dx "ADAMS final diagnosis"


/*Version 1 code, from ebl
note-most missing variables excluded due to collinearity
this section original version from ebl with variable names updated*/
/*local regvars age_cat2_ind3 age_cat2_ind4 age_cat2_ind5 age_cat2_ind6 ed_hs_only ed_gt_hs r_female_ind ///
radla riadlza ch_radla ch_riadlza rdates rbwc20 ///
rser7 rscis rcact rpres rimrc rdlrc ch_rdates ch_rbwc20 ch_rser7 ch_rscis ch_rcact ch_rpres ///
ch_rimrc ch_rdlrc missrbwc20 missrser7 missrscis missrcact missrpres missrimrc ///
missrdlrc missrdates missradla missriadlza

local proxyvars age_cat2_ind3 age_cat2_ind4 age_cat2_ind5 age_cat2_ind6 ed_hs_only ed_gt_hs r_female_ind ///
radla riadlza ch_radla ch_riadlza  iqmean ch_iqmean ///
ch_rproxy prevrdates prevrser7 prevrpres prevrimrc prevrdlrc ///
missrdates missrser7 missrscis missrcact missrpres missrimrc ///
missrdlrc missradla missriadlza
*/
/*version 2 code
Updated from version 1 to include alternate missing categorical variables
1. noprevivw=no t-2 HRS interview, change scores set to 0
(can remove miss adl, iadl variables, all missingness is because missing the interview)
2. nocogprev=no t-2 HRS TICS cognition score, self interview
(can remove miss tics components missing, b/c imputed dataset used, if missing one, missing all
for a given interview)
3. missiqscore=no t-2 HRS IQSCORE, proxy interview 
4. also, for clarity, using variable prevrproxy instead of ch_rproxy to match Hurd paper 
(they are the same thing though) */
local bothvars age_cat2_ind3 age_cat2_ind4 age_cat2_ind5 age_cat2_ind6 ///
ed_hs_only ed_gt_hs r_female_ind radla riadlza ch_radla ch_riadlza missradla missriadlza

local regvars rdates rbwc20 rser7 rscis rcact rpres rimrc rdlrc ///
ch_rdates ch_rbwc20 ch_rser7 ch_rscis ch_rcact ch_rpres ///
ch_rimrc ch_rdlrc nocogprev 

local proxyvars iqmean missiqscore ch_iqmean ///
prevrproxy prevrdates prevrser7 prevrpres prevrimrc prevrdlrc 

replace iqmean=3 if missing(iqmean) & rproxy==1 //so don't drop those that have missing scores, just have addl ind

**checks
tab rdates if !missing(dx) & rproxy==0, missing
sum iqmean  if !missing(dx) & rproxy==1

//oprobit dx `regvars' if rproxy==0 //version 1 model
oprobit dx `bothvars' `regvars' if rproxy==0 //version 2
gen predsample=e(sample) //indicator for obs in the model
predict pself_1 if rproxy==0 /*& ragey_e>69*/, outcome(1)
predict pself_2 if rproxy==0 /*& ragey_e>69*/, outcome(2) 
predict pself_3 if rproxy==0 /*& ragey_e>69*/, outcome(3)

//oprobit dx `proxyvars' if rproxy==1 //version 1 model
oprobit dx `bothvars' `proxyvars' if rproxy==1 //version 2
gen predsample2=e(sample)
replace predsample=1 if predsample2==1
drop predsample2
predict pproxy_1 if rproxy==1 /*& ragey_e>69*/, outcome(1)
predict pproxy_2 if rproxy==1 /*& ragey_e>69*/, outcome(2)
predict pproxy_3 if rproxy==1 /*& ragey_e>69*/, outcome(3)

tab predsample,missing
tab dx if rproxy==1 //n=199 adams sample with proxy ivw previous wave

*probability of dementia variable, comparable to Hurd variable
gen pdem=pself_1 if rproxy==0
replace pdem=pproxy_1 if rproxy==1
la var pdem "Predicted probability of dementia"

gen pcind=pself_2 if rproxy==0
replace pcind=pproxy_2 if rproxy==1
la var pcind "Predicted probability of CIND"

gen pnorm=pself_3 if rproxy==0
replace pnorm=pproxy_3 if rproxy==1
la var pnorm "Predicted probability of normal"

*categorical variable, assign to category with higest predicted probability
gen pred_dem_cat=1 if (pself_1>pself_2 & pself_1>pself_3 & !missing(pself_1)) | ///
	(pproxy_1>pproxy_2 & pproxy_1>pproxy_3 & !missing(pproxy_1))
replace pred_dem_cat=2 if (pself_2>pself_1 & pself_2>pself_3 & !missing(pself_1)) | ///
	(pproxy_2>pproxy_1 & pproxy_2>pproxy_3 & !missing(pproxy_1))
replace pred_dem_cat=3 if (pself_3>pself_2 & pself_3>pself_1 & !missing(pself_1)) | ///
	(pproxy_3>pproxy_2 & pproxy_3>pproxy_1 & !missing(pproxy_1))
tab pred_dem_cat,missing
la var pred_dem_cat "Predicted cog dx category"

tab pred_dem_cat dx if !missing(dx),missing
tab pred_dem_cat dx if !missing(dx)

**save complete dataset
rename prob_dementia prob_hurd
pwcorr pdem prob_hurd

save `data'\pdem_fullds_allwaves.dta,replace

preserve
keep hhidpn rproxy pdem prob_hurd dx_adams year
save `data'\pdem_withvarnames_allwaves.dta, replace

log close

