**Rebecca Gorges
**July 2016
**Starts with rand_addl_ds_3.dta, long version of RAND core dataset 
** with additional data added from other HRS sources
**Creates outcome and control variables from core interviews (no MEDPAR linkage)
**Final dataset is saved as hrs_waves3to11_vars.dta

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\setup3_log.txt, text replace
//log using E:\hrs\logs\setup2_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 3-11 from RAND
use rand_addl_ds_3.dta, clear

*****************************************************************************
** Outcome variables
*****************************************************************************

**self reported heatlh
tab rshlt wave, missing
gen rshlt_fp = 1 if inlist(rshlt,4,5)
replace rshlt_fp = 0 if inlist(rshlt,1,2,3)
la var rshlt_fp "R Self-report health = fair or poor"
tab rshlt_fp wave, missing

**health limits work
tab rhlthlm wave, missing
**note, waves 3,7 have missingness
**wave 3: question skipped ~7000 r's
**wave 7: question skipped, assumed yes (.y) if answered yes in previous interview
**wave 7: not working also introduced as possible response

**cesd score - depression
tab rcesd wave, missing
tab rcesd rproxy, missing //for non-proxy interviews only
gen rcesd_gt3=1 if rcesd>3 & rcesd!=.m
replace rcesd_gt3=0 if rcesd<4 & rcesd!=.m
la var rcesd_gt3 "R CESD gt 3 = clinicial depress cutoff"
tab rcesd_gt3, missing

**bmi 
sum rbmi, detail
gen rbmi_cat = 1 if rbmi>=18 & rbmi<=25
replace rbmi_cat = 2 if rbmi>25 & rbmi<30
replace rbmi_cat = 3 if rbmi>=30
replace rbmi_cat = 4 if rbmi<18
replace rbmi_cat = . if inlist(rbmi,.d,.m,.r)
la def bmi 1 "Normal BMI 18-25" 2"Overweight BMI 25-30" 3 "Obese BMI 30+" ///
4 "Underweight BMI <18"
la val rbmi_cat bmi  
la var rbmi_cat "R BMI Categorical"
tab rbmi_cat, missing
sort rbmi_cat
by rbmi_cat: sum rbmi

**gen indicator for not-normal bmi
gen rbmi_not_normal=1 if inlist(rbmi_cat,2,3,4)
replace rbmi_not_normal=0 if rbmi_cat==1
la var rbmi_not_normal "BMI not in normal range"
tab rbmi_not_normal, missing

**adl/iadl impairment
**uses RAND "some difficulty" with ADL / IADL count variables
**ADL includes bathe,dress,eat,get in/out of bed, walking across room
**IADL includes phone, money, medications, shopping, meal prep
tab radla, missing
tab riadlza, missing
gen radlimpair=1 if inlist(radla,1,2,3,4,5)
replace radlimpair=1 if inlist(riadlza,1,2,3,4,5)
replace radlimpair=0 if radla==0 & riadlza==0
la var radlimpair "R 1+ ADL/IADL difficulty"
tab radlimpair, missing
tab radlimpair radla, missing
tab radlimpair riadlza, missing

**unemployed
tab rlbrf, missing
tab runemp, missing
gen runemp_ind = 1 if runemp==1
replace runemp_ind = 0 if inlist(runemp,.x,.i,0)
la var runemp_ind "R unemployed 1=yes; 0 includes not in lf"
tab runemp_ind, missing
tab runemp_ind runemp, missing
tab runemp_ind rlbrf, missing //some discrepancies between this and runemp, use runemp variable

**hours per week worked, add primary job + additional job variables
** if not working .w code originally, kept as missing here, may want to review this
sum rjhours, detail
sum rjhour2,detail
gen rhours_worked=rjhours if !missing(rjhours)
replace rhours_worked=rjhours+rjhour2 if !missing(rjhour2)
sum rhours_worked, detail
la var rhours_worked "R Hours worked/week at current job, includes second job"

*****************************************************************************
** Dementia variables
*****************************************************************************
**Cognition total score 
sum rcogtot,detail
gen rcogimp_tics_ind=1 if rcogtot<=8
replace rcogimp_tics_ind=0 if rcogtot>8 & !missing(rcogtot)
tab rcogimp_tics_ind, missing
tab rcogimp_tics_ind rproxy, missing
tab rcogimp_tics_ind wave, missing
tab rcogtot rcogimp_tics_ind , missing

**look at why tics score missing
**.n = not asked, reinterview or age<65
**.s=specific interview is proxy interview; .x=no non-proxy interviews
gen tics_missing=0
replace tics_missing=1 if missing(rcogtot)
tab rcogtot if tics_missing==1, missing

**cognition questions not asked if <65yo
gen age_lt_65=1 if ragey_e<65
replace age_lt_65=0 if ragey_e>=65 & !missing(ragey_e)
tab age_lt_65, missing

**dementia probability not imputed if <70yo
gen age_lt_70=1 if ragey_e<70
replace age_lt_70=0 if ragey_e>=70 & !missing(ragey_e)
tab age_lt_70, missing

tab rcogimp_tics_ind ralzhe, missing

**self report of alzheimers or dementia
tab ralzhe rdemen if inlist(wave,10,11), missing
gen ralzdem_sr=1 if ralzhe==1 | rdemen==1
replace ralzdem_sr=0 if ralzhe==0 & rdemen==0
tab ralzdem_sr if inlist(wave,10,11), missing
tab rcogtot ralzdem_sr  if inlist(wave,10,11)

**self report memory related disease, question not asked in wave 3
tab rmemry wave, missing //waves 3,10,11 had different variables
tab rmemrye wave, missing

**combine self report memory disease + dementia + alzheimers to see if similar across waves
gen sr_mem_dis_any=1 if ralzdem_sr==1
replace sr_mem_dis_any=1 if rmemrye==1
replace sr_mem_dis_any=0 if ralzdem_sr==0 & missing(sr_mem_dis_any)
replace sr_mem_dis_any=0 if rmemrye==0 & missing(sr_mem_dis_any)

**possibly try to backfill with previous wave ever report for missings in 2010/2012?
tab sr_mem_dis_any year, missing

**dementia probability 1998-2006 waves only
la var prob_dementia "Probability dementia +1 year from core, Hurd calculated"
sum prob_dementia, detail
sum prob_dementia if rproxy==1
sum prob_dementia if rproxy==0
sum prob_dementia if rcogimp_tics_ind==1
sum prob_dementia if rcogimp_tics_ind==0
sum prob_dementia if sr_mem_dis_any==1
sum prob_dementia if sr_mem_dis_any==0

gen prob_dem_gt50=1 if prob_dementia>=.5 & !missing(prob_dementia)
replace prob_dem_gt50=0 if prob_dementia<.5 & !missing(prob_dementia)
la var prob_dem_gt50 "Prob dementia > 50%"
tab prob_dem_gt50, missing

gen prob_dem_gt70=1 if prob_dementia>=.7 & !missing(prob_dementia)
replace prob_dem_gt70=0 if prob_dementia<.7 & !missing(prob_dementia)
la var prob_dem_gt70 "Prob dementia > 70%"
tab prob_dem_gt70, missing

gen prob_dem_gt90=1 if prob_dementia>=.9 & !missing(prob_dementia)
replace prob_dem_gt90=0 if prob_dementia<.9 & !missing(prob_dementia)
la var prob_dem_gt90 "Prob dementia > 90%"
tab prob_dem_gt90, missing

pwcorr prob_dementia prob_dem_gt50 rproxy rcogimp_tics_ind sr_mem_dis_any, sig

***********************************************

**need to do Dementia probability imputations to get 2008-2012 waves included here!

***********************************************

*****************************************************************************
** Nursing home, home health aide variables
*****************************************************************************
**nursing home
tab rnrshom year, missing
tab rnhmliv, missing
tab rnrshom rnhmliv, missing //all that were in nh at time of ivw have yes for nh use variable

gen sr_nh_ind = 1 if rnrshom==1
replace sr_nh_ind = 0 if rnrshom==0
la var sr_nh_ind "R Nursing home use last 2 years, self report"
tab sr_nh_ind year, missing

**home care
tab rhomcar year, missing
gen sr_homecare_ind = 1 if rhomcar==1
replace sr_homecare_ind = 0 if rhomcar==0
replace sr_homecare_ind = 0 if rhomcar==.n //set to 0 if in nh at time of interview and question skipped
la var sr_homecare_ind "R Home care last 2 years, self report"
tab sr_homecare_ind year, missing

tab sr_nh_ind sr_homecare_ind, missing

**long term care categorical variable
gen r_sr_ltc_cat = 0 if sr_nh_ind==0&sr_homecare_ind==0
replace r_sr_ltc_cat = 1 if sr_nh_ind==1&sr_homecare_ind==0
replace r_sr_ltc_cat = 2 if sr_nh_ind==0&sr_homecare_ind==1
replace r_sr_ltc_cat = 3 if sr_nh_ind==1&sr_homecare_ind==1
la def ltccat 0 "No LTC" 1 "Nursing home only" 2 "Home care only" 3 "Nursing home and home care"
la val r_sr_ltc_cat ltccat
la var r_sr_ltc_cat "R self report nh and/or home care"
tab r_sr_ltc_cat,missing

*****************************************************************************
** Control variables - demographics
*****************************************************************************
**age, use age at end of interview variable, per Rand codebook, when begin and end
** dates are different, most of the interview is at the end date (randhrs_0 page 118)
sum ragey_e, detail
gen rage_cat=0 if ragey_e<65 & !missing(ragey_e)
replace rage_cat=1 if ragey_e>=65 & ragey_e<75
replace rage_cat=2 if ragey_e>=75 & ragey_e<85
replace rage_cat=3 if ragey_e>=85 & !missing(ragey_e)

la def agecat 0"age <65" 1"age 65-74" 2"age 75-84" 3"age 85+"
la val rage_cat agecat
la var rage_cat "R age at interview, years"
tab rage_cat, missing
sort rage_cat
by rage_cat: sum ragey_e

tab sr_mem_dis_any rage_cat, missing
tab rcogimp_tics_ind rproxy if rage_cat==3, missing

**gender
tab ragender, missing
gen r_female_ind = 1 if ragender==2
replace r_female_ind = 0 if ragender==1
la var r_female_ind "R gender 1=female; 0=male"
tab r_female_ind, missing

**race,ethnicity
tab raracem rahispan, missing
gen r_race_eth_cat = 0 if raracem==1 & rahispan==0
replace r_race_eth_cat = 1 if raracem==2 & rahispan==0
replace r_race_eth_cat = 2 if rahispan==1
replace r_race_eth_cat = 3 if raracem==3 & rahispan==0
la def raceethcat 0 "White non-Hispanic" 1 "Black non-Hispanic" 2"Hispanic" 3"Other non-Hispanic"
la var r_race_eth_cat "R Race/Ethnicity"
la val r_race_eth_cat raceethcat
tab r_race_eth_cat, missing

**education
tab raeduc, missing

**income and assets
**note income and assets quintiles calculated separately for each wave
sort hatota5
by hatota5: sum hatota

la def quintiles 1 "1 (low)" 2"2" 3 "3" 4 "4" 5 "5 (high)"
la val hitot5 hatota5 quintiles

tab hitot5, missing
sum hitot, detail
tab hatota5, missing
sum hatota, detail


*****************************************************************************
** Family structure, children caregivers
*****************************************************************************
**marital status, include partnered as married
tab rmstat, missing
gen r_married=1 if inlist(rmstat,1,2,3)
replace r_married=0 if inlist(rmstat,4,5,6,7,8)
la var r_married "R Married or Partnered"
tab r_married, missing

**lives alone
tab hhhres, missing
gen r_livesalone=1 if hhhres==1
replace r_livesalone=0 if hhhres>1 & !missing(hhhres)
la var r_livesalone "R lives alone"
tab r_livesalone, missing

**indicator for having 1 or more living children
gen hanychild=1 if hchild>0 & !missing(hchild)
replace hanychild=0 if hchild==0 & !missing(hchild)
la var hanychild "Any living child for R&S 1=yes"
tab hanychild, missing

**indicator for 1 or more daughters
gen hanydaughter=1 if hndau>0 & !missing(hndau)
replace hanydaughter=0 if hndau==0 & !missing(hndau)
la var hanydaughter "Any daughters for R&S 1=yes"
tab hanydaughter, missing 

**indicator adult child helps with adl or iadl, 
** missing for 2010 data, manually do this for 2012?
/*sum rhlpadlkn, detail //number children help with adls
sum rhlpiadlkn, detail //number of children help with iadls 
need to create binary variable for having a child help with adl or iadl*/

*****************************************************************************
** Health insurance
*****************************************************************************

tab rgovmr, missing //medicare
tab rgovmd, missing //medicaid
tab rgovva, missing //va insurance
tab rhiltc, missing //ltc insurance
tab rhiothp, missing //other insurance (not employer or government)

gen rmedicaid_sr = 1 if rgovmd==1
replace rmedicaid_sr = 0 if rgovmd==0
la var rmedicaid_sr "R Medicaid, self report"
gen rmedicaid_sr_missing = 1 if inlist(rgovmd,.d,.m,.r)
replace rmedicaid_sr_missing = 0 if inlist(rgovmd,0,1)
la var rmedicaid_sr_missing "R Medicaid missing indicator 1=missing"
tab rmedicaid_sr rmedicaid_sr_missing, missing

tab rage_cat rmedicaid_sr, missing


*****************************************************************************
** Medical diagnoses
*****************************************************************************
* use Jing's recodes for the dispute response categories
* 3=disputes previous record, has condition coded as 1
* 4=disputes previous record and no condition coded as 0
* 5=disputes previous record and dk if condition coded as missing
local dis hibp diab cancr lung heart strok psych arthr  

foreach v in `dis'{
tab r`v',missing
gen r`v'_sr=1 if r`v'==1
replace r`v'_sr=0 if r`v'==0
replace r`v'_sr=1 if r`v'==3
replace r`v'_sr=0 if r`v'==4
tab r`v'_sr, missing
}

la var rhibp_sr "R dx high blood pressure, self report"
la var rdiab_sr "R dx diabetes, self report"
la var rcancr_sr "R dx cancer, self report"
la var rlung_sr "R dx lung disease, self report"
la var rheart_sr "R dx heart disease, self report"
la var rstrok_sr "R dx stroke, self report"
la var rpsych_sr "R dx psychiatric condition, self report"
la var rarthr_sr "R dx arthritis, self report"

save hrs_waves3to11_vars.dta, replace


log close
