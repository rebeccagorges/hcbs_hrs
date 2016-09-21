**Rebecca Gorges
**September 2016
**Replicates Hurd et al tables to verify dataset, algorithm are comparable
**with proxy dementia iqcode proxycog_allyrs2.dta

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs
log using `logpath'\dem_prob3_log.txt, text replace
//log using E:\hrs\logs\setup1_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

use pdem_fullds_allwaves.dta, clear
*****************************************************************************
pwcorr pdem prob_hurd
*1 obs missing my calcualted value but not hurd value
sum prob_hurd if missing(pdem) & year>1996 & year<2008 & ragey_e>69 
*505 have my calculated value but not hurd
sum pdem if missing(prob_hurd) & year>1996 & year<2008  & ragey_e>69

tab rage_cat if !missing(pdem) & missing(prob_hurd) & year>1996 & year<2008
gen dem_prob_calc_ind=1 if !missing(pdem) & !missing(prob_hurd) & year>1996 & year<2008 & ragey_e>69
replace dem_prob_calc_ind=2 if missing(pdem) & !missing(prob_hurd) & year>1996 & year<2008 & ragey_e>69
replace dem_prob_calc_ind=3 if !missing(pdem) & missing(prob_hurd) & year>1996 & year<2008 & ragey_e>69
la def dempro 1 "Both models pred val" 2 "Hurd predictions, my model missing" ///
3 "Hurd missing, my model not"
la val dem_prob_calc_ind dempro
tab dem_prob_calc_ind,missing

tab rproxy if dem_prob_calc_ind==2 //Hurd predictions, mine missing
tab rproxy if dem_prob_calc_ind==3 //My model predictions, Hurd missing

**look at covariates, why different??? missingness in covariates
local bothvars age_cat2_ind3 age_cat2_ind4 age_cat2_ind5 age_cat2_ind6 ///
ed_hs_only ed_gt_hs r_female_ind ///
radla riadlza ch_radla ch_riadlza noprevivw 

local regvars  rdates rbwc20 rser7 rscis rcact rpres rimrc rdlrc ///
ch_rdates ch_rbwc20 ch_rser7 ch_rscis ch_rcact ch_rpres ///
ch_rimrc ch_rdlrc nocogprev

local proxyvars iqmean /*ch_iqmean*/ missiqscore  ///
prevrproxy prevrdates prevrser7 prevrpres prevrimrc prevrdlrc

**self interviews
**hurd includes the 1 observation with missing tics variables, not sure
**how to incoprorate this though because none of the obs in the ADAMS are missing
**the tics score variables.
foreach v in `bothvars' `regvars'{
tab `v' dem_prob_calc_ind if rproxy==0 & ragey_e>69, missing
}

**gen indicator for missing change in iqcode
gen miss_chiqmean=1 if missing(ch_iqmean)
replace miss_chiqmean=0 if !missing(ch_iqmean)

**proxy interviews
foreach v in `bothvars' `proxyvars' miss_chiqmean {
tab `v' dem_prob_calc_ind if rproxy==1 & ragey_e>69, missing
}

//Hurd must be different in the missing score variables for proxy interview model
tab missiqscore dem_prob_calc_ind if rproxy==1

tab year if cog_missing==1 &rproxy==1

*****************************************************************************
**Hurd paper, table 1, probability of dementia by study characteristics
/*gen r_white=1 if r_race_eth_cat==0
replace r_white=0 if inlist(r_race_eth_cat,1,2,3)
gen r_hisp=1 if  r_race_eth_cat==2
replace r_hisp=0 if inlist(r_race_eth_cat,0,1,3)
gen r_other=1 if  inlist(r_race_eth_cat,1,3)
replace r_other=0 if inlist(r_race_eth_cat,0,2)

foreach v in r_white r_hisp r_other{
tab r_race_eth_cat `v',missing
} 

mat t1re=J(4,4,.)
tab r_white if !missing(pdem),matcell(re1)
mat t1re[1,1]=re1[2,1]/r(N)*100

reg pdem r_white
mat beta=e(b)
mat t1re[1,2]=beta[1,1]+beta[1,2]



mat list t1re

reg r_race_eth_cat1 pdem
reg pdem r_race_eth_cat1 

gen r_male_ind=1 if r_female_ind==0
replace r_male_ind=0 if r_female_ind==1
reg pdem r_female_ind
reg pdem r_male_ind

sort r_female_ind
by r_female_ind: sum pdem

mat re=J(4,4,.)
**race,ethnicity
tab r_race_eth_cat if !missing(pdem), matcell(re1)
forvalues i=1/4{
mat re[`i',1]=re1[`i',1]/r(N)*100
sum pdem if r_race_eth_cat==`i'-1
mat re[`i',2]=r(mean)
mat re[`i',3]=r(mean)-(1.96*r(sd))
mat re[`i',4]=r(mean)+(1.96*r(sd))
}

mat list re

 
*/
*****************************************************************************
**appendix text beginning page 8 tabulations
tab pred_dem_cat if predsample==1
tab dx_adams if predsample==1

tab pred_dem_cat dx_adams

*****************************************************************************
**table S1, mean, sd of cognitive variables
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

la var rdates "Dates"
la var rbwc20 "Backward counting 20"
la var rser7 "Serial 7"
la var rscis "Scissor"
la var rcact "Cactus"
la var rpres "President"
la var rimrc "Immediate recall"
la var rdlrc "Delayed recall"
la var iqmean "IQCODE"
la var radla "ADLs"
la var riadlza "IADLs"

mat s1=J(1,3,.)
foreach v in rdates rbwc20 rser7 rscis rcact rpres rimrc rdlrc iqmean radla riadlza{
	sum `v' if adams_wave==1
	mat s1[1,1]=r(N)
	mat s1[1,2]=r(mean)
	mat s1[1,3]=r(sd)
	mat rownames s1=`v'  

	frmttable, statmat(s1) store(s1) varlabels sdec(0,2,2)
	outreg, replay(tabs1) append(s1) store(tabs1)
}
outreg using `logpath'/pdem_check_tables, replay(tabs1) ///
title("Replication Hurd table S1, Characteristics of ADAMS sample") ///
replace

*****************************************************************************
**table page 9 of appendix
*****************************************************************************
gen dem_dx_ind=1 if dx_adams==1
replace  dem_dx_ind=0 if inlist(dx_adams,2,3)
tab dem_dx_ind dx_adams

**create bins (decile of dementia probability)
xtile bin10=pdem if adams_wave==1,nq(10)
tab bin10, missing

mat t9=J(10,6,.)

forvalues i = 1/10{
sum pdem if bin10==`i'
mat t9[`i',1]=`i' //bin no
mat t9[`i',2]=r(N) //n
mat t9[`i',3]=r(mean) //fitted probability
tab dem_dx_ind if bin10==`i', matcell(a) 
mat t9[`i',4]=a[2,1]/t9[`i',2] //actual frequency
mat t9[`i',5]= t9[`i',2]* t9[`i',3] //estimated no cases
mat t9[`i',6]=a[2,1] //actual no cases
}

**manually fill in where 0 obs or all obs in bin have dx
mat t9[2,4]=0
mat t9[2,6]=0
mat t9[10,4]=1
mat t9[10,6]=85
frmttable, statmat(t9) store(t9) sdec(0,0,3,3,2,0)

**do overall stats row
mat t9_1=J(1,6,.)
sum pdem if adams_wave==1
//mat t9_1[1,1]=`i' //bin no
mat t9_1[1,2]=r(N) //n
mat t9_1[1,3]=r(mean) //fitted probability
tab dem_dx_ind if adams_wave==1, matcell(a) 
mat t9_1[1,4]=a[2,1]/t9_1[1,2] //actual frequency
mat t9_1[1,5]=t9_1[1,2]*t9_1[1,3] //estimated no cases
mat t9_1[1,6]=a[2,1] //actual no cases
frmttable, statmat(t9_1) store(t9_1) sdec(0,0,3,3,2,0)


frmttable, replay(t9) append(t9_1) store(t9_2)
outreg using `logpath'/pdem_check_tables, replay(t9_2) ///
title("Replication Hurd table appendix p 9, within ADAMS sample fit") ///
ctitles("bin","n","Fitted ","Actual ", "Estimated","Actual" \ ///
"","","probability","frequency","number of cases","number of cases") ///
addtable
*****************************************************************************
**table s5
*****************************************************************************
**bring in wave C assessment to just adams wave A sample
use dementia_dx_adams.dta, clear
keep if adams_wave==3
tab dx_adams,missing
rename id hhidpn
destring hhidpn, replace
rename dx_adams dx_adams_waveC
keep hhidpn dx_adams_waveC 
save dem_wave3only.dta, replace

use pdem_fullds_allwaves.dta, clear
keep if adams_wave==1
sort hhidpn

merge 1:1 hhidpn using dem_wave3only.dta
gen adams_waveC_followup=1 if _merge==3
replace adams_waveC_followup=0 if _merge==1
drop _merge

**table S4 contents
tab dx_adams_waveC if dx_adams==2 &  adams_waveC_followup ==1, missing
tab dx_adams_waveC if dx_adams==3 &  adams_waveC_followup ==1, missing

**get 2007 predicted probabilities for this sample
keep if adams_waveC_followup==1

sort hhidpn year
save dem_followup1.dta,replace

**get 2006,2004 datasets, rename variables
local bothvars age_cat2_ind3 age_cat2_ind4 age_cat2_ind5 age_cat2_ind6 ///
ed_hs_only ed_gt_hs r_female_ind ///
radla riadlza ch_radla ch_riadlza noprevivw 

local regvars  rdates rbwc20 rser7 rscis rcact rpres rimrc rdlrc ///
ch_rdates ch_rbwc20 ch_rser7 ch_rscis ch_rcact ch_rpres ///
ch_rimrc ch_rdlrc nocogprev 

local proxyvars iqmean ch_iqmean ///
prevrproxy prevrdates prevrser7 prevrpres prevrimrc prevrdlrc

local keepvars year pdem pred_dem_cat pcind pnorm rproxy `bothvars' `regvars' `proxyvars' 

foreach y in 2004 2006{
use hhidpn `keepvars' using pdem_fullds_allwaves.dta , clear
keep if year==`y'
foreach v in `keepvars'{
rename `v' `v'_followup
}
save pdem_merge`y'.dta,replace
}

use pdem_merge2006.dta, clear

use dem_followup1.dta, clear
merge 1:1 hhidpn using pdem_merge2006.dta
drop if _merge==2

tab _merge if missing(pdem_followup)
tab rproxy_followup if missing(pdem_followup) & _merge==3

foreach v in `bothvars'{
tab `v'_followup if missing(pdem_followup) & _merge==3,missing
}

**some observations missing current wave tics score components bc missing in imputed dataset
foreach v in `regvars'{
tab `v'_followup if missing(pdem_followup) & _merge==3 & rproxy_followup==0,missing
}

**missing current wave iqcode variable
foreach v in `proxyvars'{
tab `v'_followup if missing(pdem_followup) & _merge==3 & rproxy_followup==1,missing
}


preserve
keep if !missing(pdem_followup)
tab year_followup, missing
save dem_followup2006.dta,replace
restore

**obs with missing 2006 interviews, use 2004 per Hurd appendix note
keep if missing(pdem_followup)
drop _merge *_followup
merge 1:1 hhidpn using pdem_merge2004.dta
keep if _merge==3
sum pdem_followup

append using dem_followup2006.dta
save dem_followup2.dta,replace

tab year_followup, missing
sum pdem_followup

tab pred_dem_cat_followup dx_adams_waveC
**recode variables to make table
gen dx_adams_waveC2=dx_adams_waveC
replace dx_adams_waveC2=1 if dx_adams_waveC==3
replace dx_adams_waveC2=3 if dx_adams_waveC==1

la def dem_cat2 1"Normal" 2"CIND" 3"Demented"
la val dx_adams_waveC2  dem_cat2

**table s6
mat s5=J(3,3,.)
forvalues r=1/3{
		sum pnorm_followup if dx_adams_waveC2==`r'
		mat s5[`r',1]=r(mean)*100	
		
		sum pcind_followup if dx_adams_waveC2==`r'
		mat s5[`r',2]=r(mean)*100

		sum pdem_followup if dx_adams_waveC2==`r'
		mat s5[`r',3]=r(mean)*100
		
	}


mat list s5
frmttable , statmat(s5) sdec(1) store(s5_1)

**summary last row
mat s5_1=J(1,3,.)
sum pnorm_followup
mat s5_1[1,1]=r(mean)*100
sum pcind_followup
mat s5_1[1,2]=r(mean)*100
sum pdem_followup
mat s5_1[1,3]=r(mean)*100

mat list s5_1
frmttable, statmat(s5_1) sdec(1) store(s5_2)
outreg  using `logpath'/pdem_check_tables, ///
replay(s5_1) append(s5_2) addtable ///
title("Replication Hurd table S5, dementia predictions in percentages") ///
ctitles("","predicted","predicted","predicted" \ ///
"Wave C status","Normal","CIND","Demented") ///
rtitles("Normal" \ "CIND" \ "Demented" \ "Total") ///
note("Interpretation: Of those with normal diagnosis in ADAMS wave C," ///
"the average predicted probability of normal status is 66.8%")
*****************************************************************************
**text on page 10 tabulations (documented in Word document)
tab dx_adams_waveC
tab pred_dem_cat_followup

tab pred_dem_cat_followup dx_adams_waveC

*****************************************************************************
log close
