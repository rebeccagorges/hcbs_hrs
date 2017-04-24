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
** Outcome variables - for both R and S where applicable
*****************************************************************************
*first identify which R's have spouses
gen sid_ind=1 if shhidpn!=0
replace sid_ind=0 if shhidpn==0
la var sid_ind "Spouse ID 1=yes"
tab rmstat sid_ind , missing

**self reported heatlh
foreach i in r s{
tab `i'shlt wave, missing
gen `i'shlt_fp = 1 if inlist(`i'shlt,4,5)
replace `i'shlt_fp = 0 if inlist(`i'shlt,1,2,3)
}

la var rshlt_fp "R Self-report health = fair or poor"
la var sshlt_fp "S Self-report health = fair or poor"
tab rshlt_fp wave, missing
tab sshlt_fp wave if sid_ind==1, missing


**health limits work
tab rhlthlm wave, missing
tab shlthlm wave, missing
**note, waves 3,7 have missingness
**wave 3: question skipped ~7000 r's
**wave 7: question skipped, assumed yes (.y) if answered yes in previous interview
**wave 7: not working also introduced as possible response
foreach i in r s{
gen `i'hlthlm1 = `i'hlthlm
replace `i'hlthlm1=1 if `i'hlthlm==.y & wave==7
tab `i'hlthlm `i'hlthlm1, missing
}

**cesd score - depression
foreach i in r s{
tab `i'cesd wave, missing
tab `i'cesd `i'proxy, missing //for non-proxy interviews only

gen `i'cesd_gt3=1 if `i'cesd>3 & `i'cesd!=.m
replace `i'cesd_gt3=0 if `i'cesd<4 & `i'cesd!=.m
}
*set spouse to missing if nonresponse or not married
replace scesd_gt3=. if scesd==.u | scesd==.v

la var rcesd_gt3 "R CESD gt 3 = clinicial depress cutoff"
la var scesd_gt3 "S CESD gt 3 = clinicial depress cutoff"
tab rcesd_gt3, missing
tab scesd_gt3, missing 

**bmi 
foreach i in r s{
sum `i'bmi, detail
gen `i'bmi_cat = 1 if `i'bmi>=18 & `i'bmi<=25
replace `i'bmi_cat = 2 if `i'bmi>25 & `i'bmi<30
replace `i'bmi_cat = 3 if `i'bmi>=30
replace `i'bmi_cat = 4 if `i'bmi<18
replace `i'bmi_cat = . if inlist(`i'bmi,.d,.m,.r,.u,.v)
}

la def bmi 1 "Normal BMI 18-25" 2"Overweight BMI 25-30" 3 "Obese BMI 30+" ///
4 "Underweight BMI <18"
la val rbmi_cat sbmi_cat bmi  
la var rbmi_cat "R BMI Categorical"
la var sbmi_cat "S BMI Categorical"
tab rbmi_cat, missing
tab sbmi_cat, missing
bys rbmi_cat: sum rbmi
bys sbmi_cat: sum sbmi

**gen indicator for not-normal bmi
foreach i in r s{
gen `i'bmi_not_normal=1 if inlist(`i'bmi_cat,2,3,4)
replace `i'bmi_not_normal=0 if `i'bmi_cat==1
tab `i'bmi_not_normal, missing
}

la var rbmi_not_normal "R BMI not in normal range"
la var rbmi_not_normal "S BMI not in normal range"

**adl/iadl impairment
**uses RAND "some difficulty" with ADL / IADL count variables
**ADL includes bathe,dress,eat,get in/out of bed, walking across room
**IADL includes phone, money, medications, shopping, meal prep
foreach i in r s{
tab `i'adla, missing
tab `i'iadlza, missing
gen `i'adlimpair=1 if inlist(`i'adla,1,2,3,4,5)
replace `i'adlimpair=1 if inlist(`i'iadlza,1,2,3,4,5)
replace `i'adlimpair=0 if `i'adla==0 & `i'iadlza==0
}
la var radlimpair "R 1+ ADL/IADL difficulty"
la var sadlimpair "S 1+ ADL/IADL difficulty"
tab radlimpair, missing
tab radlimpair radla, missing
tab radlimpair riadlza, missing
tab sadlimpair, missing
tab sadlimpair sadla, missing
tab sadlimpair siadlza, missing

**indicator any ADL limitations
foreach i in r s{
gen `i'adl_diff=1 if `i'adla>0 & !missing(`i'adla)
replace `i'adl_diff=0 if `i'adla==0 & !missing(`i'adla)
tab `i'adla `i'adl_diff, missing
}
la var radl_diff "R 1+ ADL limitations"
la var sadl_diff "S 1+ ADL limitations"

**indicator any IADL limitations
foreach i in r s{
gen `i'iadl_diff=1 if `i'iadla>0 & !missing(`i'iadla)
replace `i'iadl_diff=0 if `i'iadla==0 & !missing(`i'iadla)
tab `i'iadla `i'iadl_diff, missing
}
la var riadl_diff "R 1+ IADL limitations"
la var siadl_diff "S 1+ IADL limitations"

**unemployed
foreach i in r s{
tab `i'lbrf, missing
tab `i'unemp, missing
gen `i'unemp_ind = 1 if `i'unemp==1
replace `i'unemp_ind = 0 if inlist(`i'unemp,.x,.i,0)
}
la var runemp_ind "R unemployed 1=yes; 0 includes not in lf"
la var sunemp_ind "S unemployed 1=yes; 0 includes not in lf"
tab runemp_ind, missing
tab runemp_ind runemp, missing
tab runemp_ind rlbrf, missing //some discrepancies between this and runemp, use runemp variable
tab sunemp_ind, missing
tab sunemp_ind sunemp, missing
tab sunemp_ind slbrf, missing //some discrepancies between this and sunemp, use sunemp variable

foreach i in r s{
gen `i'lbrf1=1 if inlist(`i'lbrf,1,2,4)
replace `i'lbrf1=2 if `i'lbrf==3
replace `i'lbrf1=3 if inlist(`i'lbrf,5,6,7)
}
la def lbrf1 1 "1.working (ft/pt)" 2 "2.unemployed" 3 "3.not in lbrf (retired, disabled, sr not in)"
la val rlbrf1 slbrf1 lbrf1
tab rlbrf rlbrf1, missing
tab slbrf slbrf1, missing

**hours per week worked, add primary job + additional job variables
** if not working .w code originally, kept as missing here, may want to review this
foreach i in r s{
sum `i'jhours, detail
sum `i'jhour2,detail
gen `i'hours_worked=`i'jhours if !missing(`i'jhours)
replace `i'hours_worked=`i'jhours+`i'jhour2 if !missing(`i'jhour2)
sum `i'hours_worked, detail
}
la var rhours_worked "R Hours worked/week at current job, includes second job"
la var shours_worked "S Hours worked/week at current job, includes second job"
bys rlbrf1: sum rhours_worked
bys slbrf1: sum shours_worked

**mortality based on time from interview
tab raddate if missing(raddate),missing //.x=missing - 
sum raddate, detail
format raddate %td
gen rdeathdate_ind=1 if !missing(raddate)
replace rdeathdate_ind=0 if missing(raddate)
la var rdeathdate_ind "R Died, indicator from death date"
tab rdeathdate_ind, missing

tab sddate if missing(sddate), missing
format sddate %td
gen sdeathdate_ind=1 if !missing(sddate)
replace sdeathdate_ind=0 if sddate==.x //if no spouse or s non response, leave missing
la var sdeathdate_ind "S Died, indicator from death date"
tab sdeathdate_ind, missing

sum riwend, detail
format riwend %td
gen rivw_to_death_days = raddate-riwend
sum rivw_to_death_days, detail
li riwend raddate raidatef if rivw_to_death_days<0
gen sivw_to_death_days = sddate-riwend //days from R's interview
sum sivw_to_death_days, detail
tab rmstat if sivw_to_death_days<0, missing

foreach i in r s{
gen `i'mortality_1yr=1 if `i'ivw_to_death_days<366 & `i'deathdate_ind==1
replace `i'mortality_1yr=0 if (`i'deathdate_ind==1 & `i'ivw_to_death_days>=366 ) | `i'deathdate_ind==0

gen `i'mortality_2yr=1 if `i'ivw_to_death_days<731 & `i'deathdate_ind==1
replace `i'mortality_2yr=0 if (`i'deathdate_ind==1 & `i'ivw_to_death_days>=731 ) | `i'deathdate_ind==0
}
la var rmortality_1yr "R Died within 1 year of interview"
la var rmortality_2yr "R Died within 2 years of interview"
la var smortality_1yr "S Died within 1 year of interview"
la var smortality_2yr "S Died within 2 years of interview"

tab rmortality_1yr smortality_1yr, missing
tab rmortality_2yr smortality_2yr, missing

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
foreach i in r s{
gen `i'age_lt_65=1 if `i'agey_e<65
replace `i'age_lt_65=0 if `i'agey_e>=65 & !missing(`i'agey_e)
tab `i'age_lt_65, missing
}
**dementia probability not imputed if <70yo
foreach i in r s{
gen `i'age_lt_70=1 if `i'agey_e<70
replace `i'age_lt_70=0 if `i'agey_e>=70 & !missing(`i'agey_e)
tab `i'age_lt_70, missing
}
tab rcogimp_tics_ind ralzhe, missing

**self report of alzheimers or dementia
foreach i in r s{
tab `i'alzhe `i'demen if inlist(wave,10,11), missing
gen `i'alzdem_sr=1 if `i'alzhe==1 | `i'demen==1
replace `i'alzdem_sr=0 if `i'alzhe==0 & `i'demen==0
tab `i'alzdem_sr if inlist(wave,10,11), missing
}
tab rcogtot ralzdem_sr  if inlist(wave,10,11)

**self report memory related disease, question not asked in wave 3
tab rmemry wave, missing //waves 3,10,11 had different variables
tab rmemrye wave, missing
tab smemry wave, missing //waves 3,10,11 had different variables
tab smemrye wave, missing

**combine self report memory disease + dementia + alzheimers to see if similar across waves
foreach i in r s{
gen `i'sr_mem_dis_any=1 if `i'alzdem_sr==1
replace `i'sr_mem_dis_any=1 if `i'memrye==1
replace `i'sr_mem_dis_any=0 if `i'alzdem_sr==0 & missing(`i'sr_mem_dis_any)
replace `i'sr_mem_dis_any=0 if `i'memrye==0 & missing(`i'sr_mem_dis_any)
}
**possibly try to backfill with previous wave ever report for missings in 2010/2012?
tab rsr_mem_dis_any year, missing
tab ssr_mem_dis_any year, missing

**dementia probability 1998-2006 waves only
la var prob_dementia "Probability dementia +1 year from core, Hurd calculated"
sum prob_dementia, detail
sum prob_dementia if rproxy==1
sum prob_dementia if rproxy==0
sum prob_dementia if rcogimp_tics_ind==1
sum prob_dementia if rcogimp_tics_ind==0
sum prob_dementia if rsr_mem_dis_any==1
sum prob_dementia if rsr_mem_dis_any==0

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

pwcorr prob_dementia prob_dem_gt50 rproxy rcogimp_tics_ind rsr_mem_dis_any, sig

***********************************************

**need to do Dementia probability imputations to get 2008-2012 waves included here!
**see .do fiiles impute_dementia... for the imputations
***********************************************

*****************************************************************************
** Nursing home, home health aide variables
*****************************************************************************
**nursing home
tab rnrshom year, missing
tab rnhmliv, missing
tab rnrshom rnhmliv, missing //all that were in nh at time of ivw have yes for nh use variable

foreach i in r s{
gen `i'sr_nh_ind = 1 if `i'nrshom==1
replace `i'sr_nh_ind = 0 if `i'nrshom==0
}
la var rsr_nh_ind "R Nursing home use last 2 years, self report"
tab rsr_nh_ind year, missing
la var ssr_nh_ind "S Nursing home use last 2 years, self report"
tab ssr_nh_ind year, missing

**home care
foreach i in r s{
tab `i'homcar year, missing
gen `i'sr_homecare_ind = 1 if `i'homcar==1
replace `i'sr_homecare_ind = 0 if `i'homcar==0
replace `i'sr_homecare_ind = 0 if `i'homcar==.n //set to 0 if in nh at time of interview and question skipped
}
la var rsr_homecare_ind "R Home care last 2 years, self report"
la var ssr_homecare_ind "S Home care last 2 years, self report"
tab rsr_homecare_ind year, missing
tab ssr_homecare_ind year, missing

tab rsr_nh_ind rsr_homecare_ind, missing

**long term care categorical variable
foreach i in r s{
gen `i'_sr_ltc_cat = 0 if `i'sr_nh_ind==0&`i'sr_homecare_ind==0
replace `i'_sr_ltc_cat = 1 if `i'sr_nh_ind==1&`i'sr_homecare_ind==0
replace `i'_sr_ltc_cat = 2 if `i'sr_nh_ind==0&`i'sr_homecare_ind==1
replace `i'_sr_ltc_cat = 3 if `i'sr_nh_ind==1&`i'sr_homecare_ind==1
}
la def ltccat 0 "No LTC" 1 "Nursing home only" 2 "Home care only" 3 "Nursing home and home care"
la val r_sr_ltc_cat s_sr_ltc_cat ltccat
la var r_sr_ltc_cat "R self report nh and/or home care"
la var s_sr_ltc_cat "S self report nh and/or home care"
tab r_sr_ltc_cat,missing
tab s_sr_ltc_cat,missing
tab r_sr_ltc_cat s_sr_ltc_cat, missing //see that these are symmetric - its because they are the same people!

*****************************************************************************
** Control variables - demographics
*****************************************************************************
**age, use age at end of interview variable, per Rand codebook, when begin and end
** dates are different, most of the interview is at the end date (randhrs_0 page 118)
foreach i in r s{
sum `i'agey_e, detail
gen `i'age_cat=0 if `i'agey_e<65 & !missing(`i'agey_e)
replace `i'age_cat=1 if `i'agey_e>=65 & `i'agey_e<75
replace `i'age_cat=2 if `i'agey_e>=75 & `i'agey_e<85
replace `i'age_cat=3 if `i'agey_e>=85 & !missing(`i'agey_e)
}
la def agecat 0"age <65" 1"age 65-74" 2"age 75-84" 3"age 85+"
la val rage_cat sage_cat agecat
la var rage_cat "R age at interview, years"
la var sage_cat "S age at interview, years"
tab rage_cat, missing
sort rage_cat
by rage_cat: sum ragey_e

tab sage_cat, missing
sort sage_cat
by sage_cat: sum sagey_e

tab rsr_mem_dis_any rage_cat, missing
tab rcogimp_tics_ind rproxy if rage_cat==3, missing

**gender
tab ragender, missing
gen r_female_ind = 1 if ragender==2
replace r_female_ind = 0 if ragender==1
la var r_female_ind "R gender 1=female; 0=male"
tab r_female_ind, missing

tab sgender, missing
gen s_female_ind = 1 if sgender==2
replace s_female_ind = 0 if sgender==1
la var s_female_ind "S gender 1=female; 0=male"
tab s_female_ind, missing

tab r_female_ind s_female_ind , missing

**race,ethnicity
tab raracem rahispan, missing
gen r_race_eth_cat = 0 if raracem==1 & rahispan==0
replace r_race_eth_cat = 1 if raracem==2 & rahispan==0
replace r_race_eth_cat = 2 if rahispan==1
replace r_race_eth_cat = 3 if raracem==3 & rahispan==0

tab sracem shispan, missing
gen s_race_eth_cat = 0 if sracem==1 & shispan==0
replace s_race_eth_cat = 1 if sracem==2 & shispan==0
replace s_race_eth_cat = 2 if shispan==1
replace s_race_eth_cat = 3 if sracem==3 & shispan==0

la def raceethcat 0 "White non-Hispanic" 1 "Black non-Hispanic" 2"Hispanic" 3"Other non-Hispanic"
la var r_race_eth_cat "R Race/Ethnicity"
la var s_race_eth_cat "S Race/Ethnicity"
la val r_race_eth_cat s_race_eth_cat raceethcat
tab r_race_eth_cat s_race_eth_cat, missing

**education
tab raeduc, missing
tab seduc, missing 

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
tab r_married wave, missing

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

**indicator for any deceased children
tab hdiedkn, missing
gen hdiedkn_any=1 if hdiedkn>0 & !missing(hdiedkn)
replace hdiedkn_any=0 if hdiedkn==0
la var hdiedkn_any "Any children deceased 1=yes"
tab hdiedkn_any hdiedkn, missing

**indicator for 1 or more daughters
tab hndau year, missing
gen hanydaughter=1 if hndau>0 & !missing(hndau)
replace hanydaughter=0 if hndau==0
la var hanydaughter "Any daughters for R&S 1=yes"
tab hanydaughter year, missing //from Rand family file so missing in 2012
tab hanydaughter hanychild, missing
tab hanydaughter hanychild if hdiedkn_any==0, missing //leave for now, check later

**indicator for any resident children
tab hresdkn year, missing
gen hanyreschild=1 if hresdkn>0 & !missing(hresdkn)
replace hanyreschild=0 if hresdkn==0
la var hanyreschild "Any resident children for R&S 1=yes"
tab hresdkn hanyreschild, missing
tab hresdkn hanychild, missing //leave for now, think about updating later
**if no children reported, then replace resident child indicator=0
replace hanyreschild=0 if hanychild==0
tab hresdkn hanyreschild, missing

**indicator for children living within 10 miles
tab hlv10mikn year, missing
gen hanyliv10kn=1 if hlv10mikn>0 & !missing(hlv10mikn)
replace hanyliv10kn=0 if hlv10mikn==0
la var hanyliv10kn "Children living within 10 miles 1=yes"
tab hlv10mikn hanyreschild, missing
**if no children reported, then replace child within 10mi indicator=0
replace hanyliv10kn=0 if hanychild==0
tab hlv10mikn hanyliv10kn, missing

**indicator for resident children or child within 10 miles
tab hanyliv10kn hanyreschild if year>1996 & year<2012, missing

gen hchildnearby=1 if hanyliv10kn==1 | hanyreschild==1
replace hchildnearby=0 if hanyliv10kn==0 & hanyreschild==0
la var hchildnearby "Resident child or child living wi 10mi"
tab hchildnearby year,missing

**indicator adult child helps with adl or iadl, 
** missing for 2010 data, manually do this for 2012?
tab rhlpadlkn year, missing //number children help with adls
tab rhlpiadlkn year, missing //number of children help with iadls 
tab shlpadlkn year, missing //number children help with adls
tab shlpiadlkn year, missing //number of children help with iadls 

foreach i in r s{
gen `i'hlpadlk_ind=1 if `i'hlpadlkn>0 & !missing(`i'hlpadlkn)
replace `i'hlpadlk_ind=0 if `i'hlpadlkn==0 & !missing(`i'hlpadlkn)
gen `i'hlpiadlk_ind=1 if `i'hlpiadlkn>0 & !missing(`i'hlpiadlkn)
replace `i'hlpiadlk_ind=0 if `i'hlpiadlkn==0 & !missing(`i'hlpiadlkn)
}
la var rhlpadlk_ind "Adult child helps R with ADLs 1=yes"
la var rhlpiadlk_ind "Adult child helps R with IADLs 1=yes"
la var shlpadlk_ind "Adult child helps S with ADLs 1=yes"
la var shlpiadlk_ind "Adult child helps S with IADLs 1=yes"

foreach i in r s {
gen `i'hlp_adl_or_iadl_k_ind=1 if `i'hlpadlk_ind==1 | `i'hlpiadlk_ind==1
replace `i'hlp_adl_or_iadl_k_ind=0 if `i'hlpadlk_ind==0 & `i'hlpiadlk_ind==0
}
la var rhlp_adl_or_iadl_k_ind "Adult child helps R with ADL/IADL 1=yes"
la var shlp_adl_or_iadl_k_ind "Adult child helps S with ADL/IADL 1=yes"
tab rhlp_adl_or_iadl_k_ind year if hanychild>0 & !missing(hanychild), missing
tab shlp_adl_or_iadl_k_ind year if hanychild>0 & !missing(hanychild), missing

*****************************************************************************
** Health insurance
*****************************************************************************

tab rgovmr, missing //medicare
tab rgovmd, missing //medicaid
tab sgovmd, missing //medicaid
tab rgovva, missing //va insurance
tab rhiltc, missing //ltc insurance
tab rhiothp, missing //other insurance (not employer or government)

foreach i in r s{
gen `i'medicaid_sr = 1 if `i'govmd==1
replace `i'medicaid_sr = 0 if `i'govmd==0
gen `i'medicaid_sr_missing = 1 if inlist(`i'govmd,.d,.m,.r)
replace `i'medicaid_sr_missing = 0 if inlist(`i'govmd,0,1)
}

la var rmedicaid_sr "R Medicaid, self report"
la var rmedicaid_sr_missing "R Medicaid missing indicator 1=missing"
la var smedicaid_sr "S Medicaid, self report"
la var smedicaid_sr_missing "S Medicaid missing indicator 1=missing"
tab rmedicaid_sr rmedicaid_sr_missing, missing
tab smedicaid_sr smedicaid_sr_missing, missing

tab rage_cat rmedicaid_sr, missing
tab sage_cat smedicaid_sr, missing

*****************************************************************************
** Medical diagnoses
*****************************************************************************
* use Jing's recodes for the dispute response categories
* 3=disputes previous record, has condition coded as 1
* 4=disputes previous record and no condition coded as 0
* 5=disputes previous record and dk if condition coded as missing
local dis hibp diab cancr lung heart strok psych arthr  
foreach i in r s{
	foreach v in `dis'{
		tab `i'`v',missing
		gen `i'`v'_sr=1 if `i'`v'==1
		replace `i'`v'_sr=0 if `i'`v'==0
		replace `i'`v'_sr=1 if `i'`v'==3
		replace `i'`v'_sr=0 if `i'`v'==4
		tab `i'`v'_sr, missing
		}

* Stroke has additional option 2=TIA/possible stroke, count this as stroke
replace `i'strok_sr=1 if `i'strok==2
tab `i'strok_sr, missing

* Heart disease has item for had problem before elderly; doesn't have problem now
replace `i'heart_sr=0 if `i'heart==6
tab `i'heart_sr,missing
	}

la var rhibp_sr "R dx high blood pressure, self report"
la var rdiab_sr "R dx diabetes, self report"
la var rcancr_sr "R dx cancer, self report"
la var rlung_sr "R dx lung disease, self report"
la var rheart_sr "R dx heart disease, self report"
la var rstrok_sr "R dx stroke / tia, self report"
la var rpsych_sr "R dx psychiatric condition, self report"
la var rarthr_sr "R dx arthritis, self report"

la var shibp_sr "S dx high blood pressure, self report"
la var sdiab_sr "S dx diabetes, self report"
la var scancr_sr "S dx cancer, self report"
la var slung_sr "S dx lung disease, self report"
la var sheart_sr "S dx heart disease, self report"
la var sstrok_sr "S dx stroke / tia, self report"
la var spsych_sr "S dx psychiatric condition, self report"
la var sarthr_sr "S dx arthritis, self report"

******************************************************************************

sort hhid pn year
by hhid pn year: gen dup=_n
tab dup, missing

sort hhidpn year
by hhidpn year: gen dup1=_n
tab dup1, missing

li hhidpn hhid pn year if dup1==1 & dup==2
drop dup1 dup

save hrs_waves3to11_vars.dta, replace


log close
