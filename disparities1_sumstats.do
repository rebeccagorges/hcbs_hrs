**Rebecca Gorges
**March 2017
**Disparities project descriptive stats for PhD workshop presentation May 2017
**Uses hrs_sample3.dta
**Limits dataset to 1998-2010 waves

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

gen sampleyear_ind=1 if year>1996 & year<2012
replace sampleyear_ind=0 if year==1996 | year==2012
la var sampleyear_ind "Ivw in sample wave 1998-2010"
tab sampleyear_ind year, missing

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

**limit sample to adl or iadl difficulty - look at ltss use
tab radlimpair, missing
tab r_sr_ltc_cat2 radlimpair, missing

mat tadl=J(2,4,.)
tab r_sr_ltc_cat2 if radlimpair==1 & sampleyear_ind==1, matcell(hc)
mat tadl[1,1]=hc[1,1]/r(N)*100
mat tadl[1,2]=hc[2,1]/r(N)*100
mat tadl[1,3]=hc[3,1]/r(N)*100
mat tadl[1,4]=hc[4,1]/r(N)*100

tab r_sr_ltc_cat2 if radlimpair==0 & sampleyear_ind==1, matcell(hc)
mat tadl[2,1]=hc[1,1]/r(N)*100
mat tadl[2,2]=hc[2,1]/r(N)*100
mat tadl[2,3]=hc[3,1]/r(N)*100
mat tadl[2,4]=hc[4,1]/r(N)*100

mat rownames tadl= "ADL or IADL difficulty" "No functional limit"

frmttable , statmat(tadl) store(tadl1) sdec(2)

outreg using `logpath'/disparities_tables1.doc, replace ///
replay(tadl1) ///
ctitles("","No LTC", "Nursing home only" , "Home care only" , "NH + HC") ///
title("LTSS use by Functional status, %")

**********************************************************
**Sample selection table
**Revisit this later to add a restriction of having 2 interviews so can get lagged variables
**********************************************************
mat sample_tab=J(9,2,.)
tab year if sampleyear_ind==1, missing
mat sample_tab[1,1]=r(N) //full smaple

tab rage_lt_65 if sampleyear_ind==1
//tab year if rage_lt_65==0 & sampleyear_ind==1
//mat sample_tab[2,1]=r(N) //age 65+

tab sampleltc_ind if sampleyear_ind==1
tab year if sampleltc_ind==1 & sampleyear_ind==1
mat sample_tab[2,1]=r(N) //use long term care services - NH and/or Home Care

//by race
tab r_race_eth_cat,gen(r_race_eth_cat)
la var r_race_eth_cat1  "White non-Hispanic" 
la var r_race_eth_cat2 "Black non-Hispanic" 
la var r_race_eth_cat3 "Hispanic" 
la var r_race_eth_cat4 "Other non-Hispanic"

rename r_race_eth_cat1 r_re_white
rename r_race_eth_cat2 r_re_black
rename r_race_eth_cat3 r_re_hisp
rename r_race_eth_cat4 r_re_other

tab r_race_eth_cat if sampleltc_ind==1 & sampleyear_ind==1, matcell(s1)
mat list s1
mat sample_tab[3,1]=s1[1,1] //white
mat sample_tab[4,1]=s1[2,1] //black
mat sample_tab[5,1]=s1[3,1] //hispanic

tab s_ivw_yes if sampleltc_ind==1  & sampleyear_ind==1
tab year if sampleltc_ind==1 & s_ivw_yes==1 & sampleyear_ind==1
mat sample_tab[6,1]=r(N) //have spouse interview

tab r_race_eth_cat if sampleltc_ind==1 & s_ivw_yes==1 & sampleyear_ind==1, matcell(s2)
mat list s2
mat sample_tab[7,1]=s2[1,1] //white
mat sample_tab[8,1]=s2[2,1] //black
mat sample_tab[9,1]=s2[3,1] //hispanic

mat rownames sample_tab = "1998-2010 Interview"  ///
"Nursing home and/or HCBS Use" "\qquad White" "\qquad Black" "\qquad Hispanic" /// 
"Have Spouse Interview" "\qquad White" "\qquad Black" "\qquad Hispanic"

mat list sample_tab

preserve
keep if sampleyear_ind==1
sort hhid pn
by hhid pn : gen dup=_n
tab dup, missing
sum dup
local mean_no_ivws=r(mean)
keep if dup==1
tab year 
mat sample_tab[1,2]=r(N)
restore

preserve
keep if sampleyear_ind==1 & sampleltc_ind==1
sort hhid pn
by hhid pn : gen dup=_n
tab dup, missing
keep if dup==1
tab year 
mat sample_tab[2,2]=r(N)

tab r_race_eth_cat , matcell(s1)
mat list s1
mat sample_tab[3,2]=s1[1,1] //white
mat sample_tab[4,2]=s1[2,1] //black
mat sample_tab[5,2]=s1[3,1] //hispanic

restore

preserve
keep if sampleyear_ind==1 & sampleltc_ind==1 & s_ivw_yes==1
sort hhid pn
by hhid pn : gen dup=_n
tab dup, missing
keep if dup==1
tab year 
mat sample_tab[6,2]=r(N)

tab r_race_eth_cat , matcell(s2)
mat list s2
mat sample_tab[7,2]=s2[1,1] //white
mat sample_tab[8,2]=s2[2,1] //black
mat sample_tab[9,2]=s2[3,1] //hispanic
restore

frmttable using `logpath'/disp_pres_tabl.tex, statmat(sample_tab) sdec(0) ///
ctitles("", "Interviews", "Individuals") ///
title("Table 1: Number of Observations") ///
note("Mean number of interviews per R limited to 1998-2010 sample is `mean_no_ivws'." \ ///
"Other and missing race,ethnicity omitted from sample counts by race,ethnicity.") ///
tex replace

**********************************************************
**Outcomes summary stats
**********************************************************
**limit to the analysis sample: by wave, ltc use
gen sample1=0
replace sample1=1 if sampleyear_ind==1 & sampleltc_ind==1
tab sample1, missing
 
bys rlbrf1: sum rhours_worked

tab rlbrf1_ind1
tab rlbrf1_ind2
tab rlbrf1_ind3

la var rmortality_1yr "Died 1 year, \%"
la var rmortality_2yr "Died 2 years, \%"
la var rhosp "Any hospitalization, \%"
la var rhspnit "Hospital nights"
//la var hosptim "Number hospitalizations"
la var rshlt_fp "Fair or poor self reported health, \%"
la var rhlthlm1 "Health limits work, \%"
la var rbmi_not_normal "BMI not in normal rage, \%"
la var radl_diff "Limitation in ADLs, \%"
la var riadl_diff "Limitation in IADLs, \%"
la var rdepres "Felt depressed, \%"
la var reffort "Felt everything is an effort, \%"
la var rsleepr "Sleep was restless, \%"
la var rwhappy "Was happy, \%"
la var rflone "Felt lonely, \%"
la var rfsad "Felt sad, \%"
la var rgoing "Could not get going, \%"
la var renlife "Enjoyed life, \%"
la var rcesd_gt3 "CESD score $>$3, \%"
la var rlbrf1_ind1 "Employed, \%"
la var rlbrf1_ind2 "Unemployed, \%"
la var rlbrf1_ind3 "Out of labor force, \%"
la var runemp_ind "Unemployed, \%"
la var rhours_worked "Hours worked (among employed)"

**Add number hospital stays SR !! 

matrix t1=J(1,12,.)

foreach v in rmortality_1yr rmortality_2yr rhosp{
	tab `v' if sample1==1, missing
	sum `v' if sample1==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100

	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table1a) append(table1) store(table1a)
}

matrix t1=J(1,12,.)
local v rhspnit
	sum `v' if sample1==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)
	mat t1[1,4]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)
	mat t1[1,8]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)
	mat t1[1,12]=r(sd)

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

local tabvars rshlt_fp rhlthlm1 rbmi_not_normal radl_diff riadl_diff ///
rdepres reffort rsleepr rwhappy rflone rfsad rgoing renlife rcesd_gt3 ///
rlbrf1_ind1 rlbrf1_ind2 rlbrf1_ind3 
		
foreach v in `tabvars' {
	matrix t1=J(1,12,.)
	tab `v' if sample1==1, missing
	sum `v' if sample1==1
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)*100

	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
	outreg , replay(table1a) append(table1) store(table1a)

}	

matrix t1=J(1,12,.)
local v rhours_worked
	sum `v' if sample1==1 
	mat t1[1,1]=r(N)
	mat t1[1,3]=r(mean)
	mat t1[1,4]=r(sd)
	
	sum `v' if sample1==1  & home_care_ind==0
	mat t1[1,5]=r(N)
	mat t1[1,7]=r(mean)
	mat t1[1,8]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1
	mat t1[1,9]=r(N)
	mat t1[1,11]=r(mean)
	mat t1[1,12]=r(sd)

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(0,2,0,2,0,2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)


outreg using `logpath'/disparities_tables1, addtable ///
replay(table1a) landscape title("Outcomes summary statistics") ///
ctitles("","Overall","","","Nursing home","","Home care","" \ ///
"","N","Mean","N","Mean","N","Mean" ) ///
note("HRS 1998-2010 waves, subsample receiving long-term care" \ ///
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
tab rage_cat, gen(rage_cat4_) 
la var rage_cat4_1 "Age <65"
la var rage_cat4_2 "Age 65-74"
la var rage_cat4_3 "Age 75-84"
la var rage_cat4_4 "Age 85+"

tab raeduc
tab raeduc r_ed_lt_hs
tab raeduc r_ed_hs_only
tab raeduc r_ed_gt_hs

la var r_ed_lt_hs "Less than high school"
la var r_ed_hs_only "HS degree (inc. GED)"
la var r_ed_gt_hs "Some college + "

tab rmedicaid_sr, missing

**use assets only bc highly correlated with income
pwcorr hatota5 hitot5
tab hatota5, gen(hatota5_)
tab hitot5, gen(hitot5_)

local xvars rage_cat4_1 rage_cat4_2 rage_cat4_3 rage_cat4_4 ///
r_married r_livesalone hanychild ///
hatota5_1 hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
rshlt_fp rhibp_sr rdiab_sr rcancr_sr rlung_sr rheart_sr ///
rstrok_sr rpsych_sr rarthr_sr radlimpair radl_diff riadl_diff ///
 rsr_mem_dis_any

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
la var hatota5_5_n1 "5th quintile (high)$^1$"
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
la var radl_diff_n1 "ADL limitations$^1$"
la var riadl_diff_n1 "IADL limitations$^1$" 
la var rsr_mem_dis_any_n1 "Memory disease$^1$"

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

foreach v in r_female_ind r_ed_lt_hs r_ed_hs_only r_ed_gt_hs rmedicaid_sr {

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
rstrok_sr rpsych_sr rarthr_sr rsr_mem_dis_any radlimpair radl_diff riadl_diff
 

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
ctitles("","Overall","","","Nursing home","","Home care","" \ ///
"","N","Mean","N","Mean","N","Mean" ) ///
note("HRS 1998-2010 waves, subsample receiving long-term care" \ ///
"Home care includes those home care only and also both home care and nursing home care" \ ///
"$^1$ lagged value - response from previous interview") 

**********************************************************
**LTC by race
**********************************************************
tab r_race_eth_cat r_sr_ltc_cat2 , missing
tab r_race_eth_cat r_sr_ltc_cat2

tab r_race_eth_cat if !missing(r_sr_ltc_cat2) & r_race_eth_cat!=3  & sampleyear_ind==1, matcell(hcr1)
mat list hcr1

frmttable , statmat(hcr1) store(hcr1_n) sdec(0)

mat trace=J(3,4,.)
tab r_sr_ltc_cat2 if r_race_eth_cat==0  & sampleyear_ind==1, matcell(hcr)
mat trace[1,1]=hcr[1,1]/r(N)*100
mat trace[1,2]=hcr[2,1]/r(N)*100
mat trace[1,3]=hcr[3,1]/r(N)*100
mat trace[1,4]=hcr[4,1]/r(N)*100

tab r_sr_ltc_cat2 if r_race_eth_cat==1  & sampleyear_ind==1, matcell(hcr)
mat trace[2,1]=hcr[1,1]/r(N)*100
mat trace[2,2]=hcr[2,1]/r(N)*100
mat trace[2,3]=hcr[3,1]/r(N)*100
mat trace[2,4]=hcr[4,1]/r(N)*100

tab r_sr_ltc_cat2 if r_race_eth_cat==2  & sampleyear_ind==1, matcell(hcr)
mat trace[3,1]=hcr[1,1]/r(N)*100
mat trace[3,2]=hcr[2,1]/r(N)*100
mat trace[3,3]=hcr[3,1]/r(N)*100
mat trace[3,4]=hcr[4,1]/r(N)*100

mat rownames trace= "White" "Black" "Hispanic"

frmttable , statmat(trace) store(trace1) sdec(2)

outreg using `logpath'/disparities_tables1.doc, addtable ///
replay(hcr1_n) merge(trace1) ///
ctitles("","N","No LTC", "Nursing home only" , "Home care only" , "NH + HC") ///
title("LTSS use by Race and Ethnicity Categories , %") ///
note("Other race category ommitted" \ ///
"Chi-squared test of equal ltss by race categories: p<0.001")

tab r_race_eth_cat r_sr_ltc_cat2 if r_sr_ltc_cat2!=0 & r_race_eth_cat!=3 & sampleyear_ind==1, chi

***********************************************************
***********************************************************
reg rhosp i.r_race_eth_cat#i.home_care_ind if sampleltc_ind==1 & sampleyear_ind==1 & r_race_eth_cat!=3
***********************************************************
***********************************************************
**table of rate of use ltc categories by race
**presentation Table 2

mat table_use=J(3,3,.)
foreach i in 0 1 2{
tab r_sr_ltc_cat2 if sample1==1 & r_race_eth_cat==`i', matcell(use)
mat table_use[1,`i'+1]=use[1,1]/r(N)*100 //% nh only
mat table_use[2,`i'+1]=use[2,1]/r(N)*100 //% home care only
mat table_use[3,`i'+1]=use[3,1]/r(N)*100 //% hc+nh
}

mat list table_use
mat rownames table_use="Nursing home only, \%" "Home care only, \%" "Nursing home and home care, \%"

frmttable using `logpath'/disp_pres_tabl.tex, statmat(table_use) sdec(2) ///
ctitles("", "White", "Black", "Hispanic") ///
title("Table 2: LTSS by Race and Ethnicity") ///
note("HRS 1998-2010 sample limited to respondents reporting LTC utilization." \ ///
"Other and missing race,ethnicity omitted."\ ///
"Chi-squared test of equal LTSS by race categories: p<0.001") ///
tex addtable

tab r_race_eth_cat r_sr_ltc_cat2 if r_sr_ltc_cat2!=0 & r_race_eth_cat!=3 & sample1==1, chi

***********************************************************
***********************************************************
**table of outcomes by race category and hc use
mata: mata clear
matrix t1=J(1,6,.)
foreach v in rmortality_1yr rmortality_2yr rhosp{

foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100 
	
	sum `v' if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
}
	mat rownames t1=`v'
	mat list t1
	
	frmttable , statmat(t1) store(table1) sdec(2) varlabels 
	outreg , replay(table1a) append(table1) store(table1a)
}

matrix t1=J(1,12,.) //additional columns for mean,sd reported
local v rhspnit	
local c = 1
foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`c'+6]=r(mean)
	mat t1[1,`c'+7]=r(sd)
	
	local c = `c'+2
}
	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

local tabvars rshlt_fp rhlthlm1 rbmi_not_normal radl_diff riadl_diff ///
rdepres reffort rsleepr rwhappy rflone rfsad rgoing renlife rcesd_gt3 ///
rlbrf1_ind1 rlbrf1_ind2 rlbrf1_ind3 

matrix t1=J(1,6,.)		
foreach v in `tabvars' {
	foreach i in 0 1 2{
	
	sum `v' if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
	}
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(2) varlabels
	outreg , replay(table1a) append(table1) store(table1a)

}	

matrix t1=J(1,12,.) //additional columns for mean,sd reported
local v rhours_worked

local c = 1
foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`c'+6]=r(mean)
	mat t1[1,`c'+7]=r(sd)
	
	local c = `c'+2
}

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

outreg using `logpath'/disp_pres_tab2.tex, tex landscape replace ///
replay(table1a)  title("Table 4: Outcomes by HCBS Use and Race/Ethnicity") ///
ctitles("","Nursing Home","","","Home care","","" \ ///
"","White","Black","Hispanic","White","Black","Hispanic" ) ///
multicol(1,2,3;1,5,3) ///
note("HRS 1998-2010 waves, subsample receiving LTSS" \ ///
"Nursing home only vs home care and home care and nursing home care" \ ///
"Health limits work = observation omitted if reports doesn't work" \ ///
"Wave 7 health limits work assumed yes if yes previous wave - data problem")

***********************************************************
***********************************************************
**table of characteristics (x variables) by race category and hc use

**cc count variables
gen count_ccs_n1=0
foreach v in rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 {
replace count_ccs_n1=count_ccs_n1+`v' if !missing(`v')
}
tab count_ccs_n1 if sample1==1, missing
gen count_ccs_0_n1=1 if count_ccs_n1==0
replace count_ccs_0_n1=0 if count_ccs_n1!=0 & !missing(count_ccs_n1)
gen count_ccs_12_n1=1 if inlist(count_ccs_n1,1,2)
replace count_ccs_12_n1=0 if count_ccs_n1!=1 & count_ccs_n1!=2 & !missing(count_ccs_n1)
gen count_ccs_gt2_n1=1 if count_ccs_n1>2 & !missing(count_ccs_n1)
replace count_ccs_gt2_n1=0 if inlist(count_ccs_n1,0,1,2) & !missing(count_ccs_n1)

foreach v in count_ccs_0_n1 count_ccs_12_n1 count_ccs_gt2_n1{
tab count_ccs_n1 `v',missing
}

la var count_ccs_0_n1 "No chronic conditions$^1$"
la var count_ccs_12_n1 "1 or 2 chronic conditions$^1$"
la var count_ccs_gt2_n1 "3+ chronic conditions$^1$"

local v ragey_e //additional columns for mean,sd reported
matrix t1=J(1,12,.)

local c = 1
foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`c'+6]=r(mean)
	mat t1[1,`c'+7]=r(sd)
	
	local c = `c'+2
}
mat rownames t1=`v'

frmttable , statmat(t1) store(table2) sdec(2) varlabels substat(1)
outreg , replay(table2a) append(table2) store(table2a)

matrix t1=J(1,6,.)

foreach v in r_female_ind r_ed_lt_hs r_ed_hs_only r_ed_gt_hs rmedicaid_sr {


	foreach i in 0 1 2{
	
	sum `v' if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
	}
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels
	outreg , replay(table2a) append(table2) store(table2a)

	}		

local lagvars r_married r_livesalone hanychild ///
hatota5_1 hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
rshlt_fp count_ccs_0 count_ccs_12 count_ccs_gt2 rsr_mem_dis_any radlimpair
 

foreach v in `lagvars' {

	foreach i in 0 1 2{
	
	sum `v'_n1 if sample1==1 & home_care_ind==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v'_n1 if sample1==1 & home_care_ind==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
	}

	mat rownames t1=`v'_n1
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels 
	outreg , replay(table2a) append(table2) store(table2a)
}

outreg using `logpath'/disp_pres_tab2.tex , tex landscape addtable ///
replay(table2a) title("Table 3: Sample Characteristics by Race, LTC Setting") ///
ctitles("","Nursing Home","","","Home care","","" \ ///
"","White","Black","Hispanic","White","Black","Hispanic" ) ///
multicol(1,2,3;1,5,3) ///
note("HRS 1998-2010 waves, subsample receiving long-term care" \ ///
"Home care includes those home care only and also both home care and nursing home care" \ ///
"$^1$ lagged value - response from previous interview" \ ///
"Chronic conditions for count are high blood pressure, diabetes, cancer, lung disease," \ ///
"Heart disease, stroke, psychiatric condition, and arthritis.") 

***********************************************************
**Spouse outcomes by race, LTC use
la var shosp "S Any hospitalization, \%"
la var shspnit "S Hospital nights"
//la var hosptim "Number hospitalizations"
la var sshlt_fp "S Fair or poor self reported health, \%"
la var shlthlm1 "S Health limits work, \%"
la var sbmi_not_normal "S BMI not in normal rage, \%"
la var sadl_diff "S Limitation in ADLs, \%"
la var siadl_diff "S Limitation in IADLs, \%"
la var sdepres "S Felt depressed, \%"
la var seffort "S Felt everything is an effort, \%"
la var ssleepr "S Sleep was restless, \%"
la var swhappy "S Was happy, \%"
la var sflone "S Felt lonely, \%"
la var sfsad "S Felt sad, \%"
la var sgoing "S Could not get going, \%"
la var senlife "S Enjoyed life, \%"
la var scesd_gt3 "S CESD score $>$3, \%"
la var slbrf1_ind1 "S Employed, \%"
la var slbrf1_ind2 "S Unemployed, \%"
la var slbrf1_ind3 "S Out of labor force, \%"
la var sunemp_ind "S Unemployed, \%"
la var shours_worked "S Hours worked (among employed)"

mata: mata clear
matrix t1=J(1,6,.)
foreach v in smortality_1yr smortality_2yr shosp {

foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100 
	
	sum `v' if sample1==1 & home_care_ind==1 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
}
	mat rownames t1=`v'
	mat list t1
	
	frmttable , statmat(t1) store(table1) sdec(2) varlabels 
	outreg , replay(table1a) append(table1) store(table1a)
}

matrix t1=J(1,12,.) //additional columns for mean,sd reported
local v shspnit	
local c = 1
foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`c'+6]=r(mean)
	mat t1[1,`c'+7]=r(sd)
	
	local c = `c'+2
}
	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

local tabvars sshlt_fp shlthlm1 sbmi_not_normal sadl_diff siadl_diff ///
sdepres seffort ssleepr swhappy sflone sfsad sgoing senlife scesd_gt3 ///
slbrf1_ind1 slbrf1_ind2 slbrf1_ind3 

matrix t1=J(1,6,.)		
foreach v in `tabvars' {
	foreach i in 0 1 2{
	
	sum `v' if sample1==1 & home_care_ind==0 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v' if sample1==1 & home_care_ind==1 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
	}
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(2) varlabels
	outreg , replay(table1a) append(table1) store(table1a)

}	

matrix t1=J(1,12,.) //additional columns for mean,sd reported
local v shours_worked

local c = 1
foreach i in 0 1 2{
	sum `v' if sample1==1 & home_care_ind==0 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & home_care_ind==1 & s_ivw_yes==1 & r_race_eth_cat==`i'
	mat t1[1,`c'+6]=r(mean)
	mat t1[1,`c'+7]=r(sd)
	
	local c = `c'+2
}

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

outreg using `logpath'/disp_pres_tab2.tex, tex landscape addtable ///
replay(table1a)  title("Table 5: Spouse Outcomes by HCBS Use and Race/Ethnicity") ///
ctitles("","Nursing Home","","","Home care","","" \ ///
"","White","Black","Hispanic","White","Black","Hispanic" ) ///
multicol(1,2,3;1,5,3) ///
note("HRS 1998-2010 waves, subsample receiving LTSS with spouse interview" \ ///
"Nursing home only vs home care and home care and nursing home care" \ ///
"Health limits work = observation omitted if reports doesn't work" \ ///
"Wave 7 health limits work assumed yes if yes previous wave - data problem")

***********************************************************

save hrs_sample_disparities.dta, replace

***********************************************************

log close
