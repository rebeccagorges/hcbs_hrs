**Rebecca Gorges
**March 2017
**Disparities project descriptive stats for PhD workshop presentation May 2017
**Uses hrs_sample3.dta
**Limits dataset to 1998-2012 waves

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\dispar_prelim_log.txt, text replace
//log using E:\hrs\logs\dispar_prelim_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
use hrs_sample3.dta, clear

***********************************************************
tab year, missing

tab rage_cat, missing

tab rcendiv, missing
gen cen_non_us=1 if missing(rcendiv) | rcendiv==11
replace cen_non_us=0 if 0<rcendiv & rcendiv<10 &!missing(rcendiv)
tab cen_non_us, missing

**need to revisit this when get updated geo data
tab state if cen_non_us==0 

gen sampleyear_ind=1 if year>1996
replace sampleyear_ind=0 if year==1996
la var sampleyear_ind "Ivw in sample wave 1998-2010"
tab sampleyear_ind, missing

**Identify sample - use LTC, age 65+
tab r_sr_ltc_cat if sampleyear_ind==1, missing //rhomecar variatle from Rand
//This variable is skipped for nursing home residents; 
//Question is from question about medically trained home care only
tab r_sr_ltc_cat2  if sampleyear_ind==1, missing
//This is my coding also using the question about non-medical
//home care - other services
tab rnhmliv, missing
tab r_sr_ltc_cat r_sr_ltc_cat2 if rnhmliv==0 & sampleyear_ind==1, missing
tab r_sr_ltc_cat r_sr_ltc_cat2 if rnhmliv==1 & sampleyear_ind==1, missing

tab r_sr_ltc_cat home_care_other_svc_ind if rnhmliv==0 & sampleyear_ind==1, missing

gen sampleltc_ind=1 if inlist(r_sr_ltc_cat2,1,2,3)
replace sampleltc_ind=0 if r_sr_ltc_cat2==0
tab r_sr_ltc_cat2 sampleltc_ind if sampleyear_ind==1, missing

tab rage_cat if sampleltc_ind==1 & sampleyear_ind==1, missing

gen home_care_ind=0 if r_sr_ltc_cat2==1 //nh only
replace home_care_ind=1 if inlist(r_sr_ltc_cat2,2,3) //home care only + home care + nh
tab r_sr_ltc_cat2 home_care_ind , missing


**********************************************************
**Outcomes summary stats
**********************************************************

bys rlbrf1: sum rhours_worked

tab rlbrf1, gen(rlbrf1_ind)

la var rhosp "Any hospitalization, \%"
la var rhspnit "Hospital nights"
//la var hosptim "Number hospitalizations"
la var rshlt_fp "Fair or poor self reported health, \%"
la var rhlthlm1 "Health limits work, \%"
la var rbmi_not_normal "BMI not in normal rage, \%"
la var adl_diff "Limitation in activities of daily living, \%"
la var iadl_diff "Limitation in instrumental activities of daily living, \%"
la var rdepres "Felt depressed, \%"
la var reffort "Felt everything is an effort, \%"
la var rsleepr "Sleep was restless, \%"
la var rwhappy "Was happy, \%"
la var rflone "Felt lonely, \%"
la var rfsad "Felt sad, \%"
la var rgoing "Could not get going, \%"
la var renlife "Enjoyed life, \%"
la var rcesd_gt3 "CESD score >3, \%"
la var rlbrf1_ind1 "Employed, \%"
la var rlbrf1_ind2 "Unemployed, \%"
la var rlbrf1_ind3 "Out of labor force, incl. retired,disabled, \%"
la var runemp_ind "Unemployed, \%"
la var rhours_worked "Hours worked (conditional on being employed)"

**Add number hospital stays SR !! 

matrix t1=J(1,12,.)
local v rhosp
	tab `v' if sampleltc_ind==1 & sampleyear_ind==1, missing
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100

	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table1a) append(table1) store(table1a)

matrix t1=J(1,12,.)
local v rhspnit
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)
	mat t1[1,4]=r(sd)
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)
	mat t1[1,8]=r(sd)
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)
	mat t1[1,12]=r(sd)

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

local tabvars rshlt_fp rhlthlm1 rbmi_not_normal adl_diff iadl_diff ///
rdepres reffort rsleepr rwhappy rflone rfsad rgoing renlife rcesd_gt3 ///
rlbrf1_ind1 rlbrf1_ind2 rlbrf1_ind3 
		
foreach v in `tabvars' {
	matrix t1=J(1,12,.)
	tab `v' if sampleltc_ind==1 & sampleyear_ind==1, missing
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100

	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table1a) append(table1) store(table1a)

}	

matrix t1=J(1,12,.)
local v rhours_worked
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)
	mat t1[1,4]=r(sd)
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)
	mat t1[1,8]=r(sd)
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)
	mat t1[1,12]=r(sd)

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)


outreg using `logpath'/disparities_tables1, replace ///
replay(table1a) landscape title("Outcomes summary statistics") ///
ctitles("","Overall","","","Nursing home","","Home care only","" \ ///
"","N","Mean","N","Mean","N","Mean" ) ///
note("HRS 1998-2012 waves, subsample receiving long-term care" \ ///
"Nursing home only vs home care and home care and nursing home care" \ ///
"Health limits worked = observation omitted if reports doesn't work" \ ///
"Wave 7 health limits work assumed yes if yes previous wave - data problem")

**********************************************************
**Right hand side variables summary stats
**********************************************************

la var home_care_ind "Home care since last interview, \%"
la var ragey_e "Age, years"
la var r_female_ind "Female"
**need lagged variables for other control variables
**create indicators from categorical variables
tab rage_cat, gen(rage_cat) 
la var rage_cat1 "Age <65"
la var rage_cat2 "Age 65-74"
la var rage_cat3 "Age 75-84"
la var rage_cat4 "Age 85+"

tab r_race_eth_cat,gen(r_race_eth_cat)
la var r_race_eth_cat1  "White non-Hispanic" 
la var r_race_eth_cat2 "Black non-Hispanic" 
la var r_race_eth_cat3 "Hispanic" 
la var r_race_eth_cat4 "Other non-Hispanic"

rename r_race_eth_cat1 r_re_white
rename r_race_eth_cat2 r_re_black
rename r_race_eth_cat3 r_re_hisp
rename r_race_eth_cat4 r_re_other

tab raeduc
gen raeduc1 = 1 if raeduc==1
replace raeduc1 = 2 if inlist(raeduc,2,3)
replace raeduc1 = 3 if raeduc==4
replace raeduc1 = 4 if raeduc==5
tab raeduc raeduc1
tab raeduc1,gen(raeduc_ind)

la var raeduc_ind1 "Less than high school"
la var raeduc_ind2 "HS degree (inc. GED)"
la var raeduc_ind3 "Some college"
la var raeduc_ind4 "4 year college deg +"

**use assets only bc highly correlated with income
pwcorr hatota5 hitot5
tab hatota5, gen(hatota5_)
tab hitot5, gen(hitot5_)

local xvars rage_cat1 rage_cat2 rage_cat3 rage_cat4 ///
r_married r_livesalone hanychild ///
hatota5_1 hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
rshlt_fp rhibp_sr rdiab_sr rcancr_sr rlung_sr rheart_sr ///
rstrok_sr rpsych_sr rarthr_sr radlimpair adl_diff iadl_diff ///
dem_any_vars_ind sr_mem_dis_any

//need lagged x variables
sort hhidpn year
foreach x in `xvars'{
by hhidpn: gen `x'_n1=`x'[_n-1]
}

drop if year==1996 // don't have lagged variables

la var r_married_n1 "Married$^1$"
la var r_livesalone_n1 "Lives alone$^1$"
la var hanychild_n1 "At least 1 living child$^1$" 
la var hatota5_1_n1 "Assets 1st quintile (low)$^1$"
la var hatota5_2_n1 "2nd quintile$^1$"
la var hatota5_3_n1 "3rd quintile$^1$" 
la var hatota5_4_n1 "4th quintile$^1$" 
la var hatota5_5_n1 "5th qunitile (high)$^1$"
la var rshlt_fp_n1 "SR health fair or poor$^1$"
la var rhibp_sr_n1 "High blood pressure$^1$"
la var rdiab_sr_n1 "Diabetes$^1$"
la var rcancr_sr_n1 "Cancer$^1$"
la var rlung_sr_n1 "Lung disease$^1$"
la var rheart_sr_n1 "Heart disease$^1$"
la var rstrok_sr_n1 "Stroke$^1$"
la var rpsych_sr_n1 "Psychiatric condition$^1$" 
la var rarthr_sr_n1 "Arthritis$^1$"
la var radlimpair_n1 "ADL or IADL impairment$^1$"
la var adl_diff_n1 "ADL limitations$^1$"
la var iadl_diff_n1 "IADL limitations$^1$" 
la var dem_any_vars_ind_n1 "Dementia$^1$"
la var sr_mem_dis_any_n1 "Memory disease$^1$"

foreach v in r_re_white r_re_black ///
r_re_hisp r_re_other  {

	matrix t1=J(1,12,.)

	tab `v' if sampleltc_ind==1 & sampleyear_ind==1, missing
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1  & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1  & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100
	
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table2a) append(table2) store(table2a)
}


local v ragey_e
matrix t1=J(1,12,.)

sum `v' if sampleltc_ind==1 & sampleyear_ind==1
mat t1[1,1]=r(N)
mat t1[1,3]=r(mean)
mat t1[1,4]=r(sd)
	
sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==0
mat t1[1,5]=r(N)
mat t1[1,7]=r(mean)
mat t1[1,8]=r(sd)
	
sum `v' if sampleltc_ind==1 & sampleyear_ind==1 & home_care_ind==1
mat t1[1,9]=r(N)
mat t1[1,11]=r(mean)
mat t1[1,12]=r(sd)

mat rownames t1=`v'
mat list t1
	
frmttable , statmat(t1) store(table2) sdec(0,2,0,2,0,2) varlabels substat(1)
outreg , replay(table2a) append(table2) store(table2a)

foreach v in r_female_ind /// 
raeduc_ind1 raeduc_ind2 raeduc_ind3 raeduc_ind4   {

	matrix t1=J(1,12,.)

	tab `v' if sampleltc_ind==1 & sampleyear_ind==1, missing
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1  & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v' if sampleltc_ind==1 & sampleyear_ind==1  & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100
	
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table2a) append(table2) store(table2a)
}

local lagvars r_married r_livesalone hanychild ///
hatota5_1 hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
rshlt_fp rhibp_sr rdiab_sr rcancr_sr rlung_sr rheart_sr ///
rstrok_sr rpsych_sr rarthr_sr radlimpair adl_diff iadl_diff ///
dem_any_vars_ind sr_mem_dis_any

foreach v in `lagvars' {
	matrix t1=J(1,12,.)

	tab `v'_n1 if sampleltc_ind==1 & sampleyear_ind==1, missing
	sum `v'_n1 if sampleltc_ind==1 & sampleyear_ind==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v'_n1 if sampleltc_ind==1 & sampleyear_ind==1  & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v'_n1 if sampleltc_ind==1 & sampleyear_ind==1  & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100
	
	mat rownames t1=`v'_n1
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table2a) append(table2) store(table2a)
}

outreg using `logpath'/disparities_tables1 , addtable ///
replay(table2a) title("Independent variables summary statistics") ///
ctitles("","Overall","","","Nursing home","","Home care only","" \ ///
"","N","Mean","N","Mean","N","Mean" ) ///
note("HRS 1998-2012 waves, subsample receiving long-term care" \ ///
"Home care includes those home care only and also both home care and nursing home care" \ ///
"$^1$ lagged value - response from previous interview") 



***********************************************************
log close
