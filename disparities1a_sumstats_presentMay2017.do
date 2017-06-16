**Rebecca Gorges
**March 2017
**Disparities project descriptive stats for PhD workshop presentation May 2017
**Uses hrs_sample_disparities.dta
**Limits dataset to 1998-2010 waves
**Presentation slides tables

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\dispar_present_may2017_log.txt, text replace
//log using E:\hrs\logs\dispar_present_may2017_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
use hrs_sample_disparities.dta, clear
*********************************************************************88

*********************************************************************88
*********************************************************************88
**Table 1 - Sample restrictions, sample size by race
*********************************************************************88
*********************************************************************88
**********************************************************
**Revisit this later to add a restriction of having 2 interviews so can get lagged variables
**********************************************************
mat sample_tab=J(9,2,.)
tab year if sampleyear_ind==1 & state_ind==1, missing
mat sample_tab[1,1]=r(N) //full smaple reside in US state

tab rage_lt_65 if sampleyear_ind==1 & state_ind==1
//tab year if rage_lt_65==0 & sampleyear_ind==1 & state_ind==1
//mat sample_tab[2,1]=r(N) //age 65+

tab sampleltc_ind if sampleyear_ind==1 & state_ind==1
tab year if sampleltc_ind==1 & sampleyear_ind==1 & state_ind==1
mat sample_tab[2,1]=r(N) //use long term care services - NH and/or Home Care

//by race
tab r_race_eth_cat if sampleltc_ind==1 & sampleyear_ind==1 & state_ind==1, matcell(s1)
mat list s1
mat sample_tab[3,1]=s1[1,1] //white
mat sample_tab[4,1]=s1[2,1] //black
mat sample_tab[5,1]=s1[3,1] //hispanic

tab s_ivw_yes if sampleltc_ind==1  & sampleyear_ind==1 & state_ind==1
tab year if sampleltc_ind==1 & s_ivw_yes==1 & sampleyear_ind==1 & state_ind==1
mat sample_tab[6,1]=r(N) //have spouse interview

tab r_race_eth_cat if sampleltc_ind==1 & s_ivw_yes==1 & sampleyear_ind==1 & state_ind==1, matcell(s2)
mat list s2
mat sample_tab[7,1]=s2[1,1] //white
mat sample_tab[8,1]=s2[2,1] //black
mat sample_tab[9,1]=s2[3,1] //hispanic

mat rownames sample_tab = "1998-2010 Interview"  ///
"\hline Long-term Care Use" "\qquad White" "\qquad Black" "\qquad Hispanic" /// 
"\hline Have Spouse Interview" "\qquad White" "\qquad Black" "\qquad Hispanic"

mat list sample_tab

preserve
keep if sampleyear_ind==1 & state_ind==1
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
keep if sampleyear_ind==1 & sampleltc_ind==1 & state_ind==1
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
keep if sampleyear_ind==1 & sampleltc_ind==1  & state_ind==1 & s_ivw_yes==1
sort hhid pn
by hhid pn : gen dup=_n
tab dup, missing
keep if dup==1
tab year 
mat sample_tab[6,2]=r(N) //overall has s interview

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

*********************************************************************
*********************************************************************
** LTC use by race,ethnicity
*********************************************************************
*********************************************************************
** limit data to analysis sample only (variable defined in disparities1_sumstats.do
** 1998-2010, ltc, state, race=black,white,hispanic
keep if sample1==1

**waiver count variable
sum wvr_count, detail //median=6
sca m=r(p50)
gen wvrcount_gtp50 = 1 if wvr_count>m  //gt 6
replace wvrcount_gtp50 = 0 if wvr_count<=m  //6 or less
tab wvr_count wvrcount_gtp50, missing

preserve
collapse wvr_count,by (state year)
sum wvr_count,detail
//median is 4
tab state
restore

gen wvrcnt_gt4=1 if wvr_count>4
replace wvrcnt_gt4=0 if wvr_count<=4
tab wvr_count wvrcnt_gt4, missing

tab r_sr_ltc_cat2 if wvrcount_gtp50==0
tab r_sr_ltc_cat2 if wvrcount_gtp50==1

*************************************

mat table_use=J(3,3,.)
foreach i in 0 1 2{
tab r_sr_ltc_cat2 if r_race_eth_cat==`i', matcell(use)
mat table_use[1,`i'+1]=use[1,1]/r(N)*100 //% nh only
mat table_use[2,`i'+1]=use[2,1]/r(N)*100 //% home care only
mat table_use[3,`i'+1]=use[3,1]/r(N)*100 //% hc+nh
}

mat list table_use
mat rownames table_use="Nursing home only, \%" "Home care only, \%" "Nursing home and home care, \%"

tab year
local sampsize=r(N)

frmttable using `logpath'/disp_pres_tabl.tex, statmat(table_use) sdec(2) ///
ctitles("", "White", "Black", "Hispanic") ///
title("Table 2: LTSS by Race and Ethnicity, N=`sampsize'") ///
note("HRS 1998-2010 sample limited to respondents reporting LTC utilization." \ ///
"Other and missing race,ethnicity omitted."\ ///
"Chi-squared test of equal LTSS by race categories: p$<$0.001") ///
tex addtable

tab r_race_eth_cat r_sr_ltc_cat2 if r_sr_ltc_cat2!=0 & r_race_eth_cat!=3 , chi

tab r_race_eth_cat, missing

*********************************************************************
*********************************************************************
** Sample characteristics by LTC use
*********************************************************************
*********************************************************************
**Presentation Table 3
*********************************************************************
local s home_care_ind
mata: mata clear

mat dmat=(0,1)
mat summstat = J(1,2,.)

local v ragey_e
  qui summarize `v' 
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
 
  matrix rownames summstat = `v'
  
matrix pars = (1 )

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c1)

 qui summarize `v'  if `s'==0
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c2)
  
outreg, replay(c1) merge(c2) store(c2a)
  
  qui summarize `v'  if home_care_ind==1
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
  
  matrix rownames summstat = `v'
  
frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")")  store(c3)

 outreg, replay(c2a) merge(c3) store(table2a)
 
matrix t1=J(1,3,.)

foreach v in r_female_ind r_re_white r_re_black r_re_hisp r_ed_lt_hs r_ed_hs_only r_ed_gt_hs rmedicaid_sr {

	sum `v' 
	mat t1[1,1]=r(mean)*100
	
	foreach i in 0 1{
	sum `v' if `s'==`i'
	mat t1[1,`i'+2]=r(mean)*100
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

	sum `v'_n1  
	mat t1[1,1]=r(mean)*100

	foreach i in 0 1 {
	sum `v'_n1 if `s'==`i'
	mat t1[1,`i'+2]=r(mean)*100
	}

	mat rownames t1=`v'_n1
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels 
	outreg , replay(table2a) append(table2) store(table2a)
}

*sample sizes
sum year 
local n_oa=r(N)

sum year if `s'==0 
local n_nh=r(N)

sum year if `s'==1
local n_hc=r(N)


outreg using `logpath'/disp_pres_tab2.tex, tex landscape replace ///
replay(table2a) title("Table 3: Sample Characteristics by LTC setting") ///
ctitles("","Overall sample","Nursing home","Home care" \ ///
"","N=`n_oa'","n=`n_nh'","n=`n_hc'" ) ///
note("HRS 1998-2010 waves, excluding other/unknown race, subsample receiving long-term care" \ ///
"Home care includes those home care only and also both home care and nursing home care" \ ///
"$^1$ lagged value - response from previous interview" \ ///
"Chronic conditions for count are high blood pressure, diabetes, cancer, lung disease," \ ///
"Heart disease, stroke, psychiatric condition, and arthritis.") 


*********************************************************************
*********************************************************************
** Outcomes characteristics by LTC use
*********************************************************************
*********************************************************************
**Presentation Table 4
*********************************************************************
matrix t1=J(1,3,.)

foreach v in rmortality_1yr rmortality_2yr rhosp{
	tab `v' , missing
	sum `v' /*[w=weight_comb]*/
	mat t1[1,1]=r(mean)*100
	
	foreach i in 0 1{
		sum `v' if home_care_ind==`i' /*[w=weight_comb]*/
		mat t1[1,`i'+2]=r(mean)*100
		}
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(2) varlabels 
	outreg , replay(table1a) append(table1) store(table1a)
}
********************************************

local v rhspnit
  qui summarize `v' 
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
 
  matrix rownames summstat = `v'
  
matrix pars = (1 )

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c1)

 qui summarize `v'  if home_care_ind==0
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c2)
  
outreg, replay(c1) merge(c2) store(c2a)
  
  qui summarize `v'  if home_care_ind==1
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
  
  matrix rownames summstat = `v'
  
frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")")  store(c3)

 outreg, replay(c2a) merge(c3) store(cont)

 outreg, replay(table1a) append(cont) store(table1a)

 ********************************************************

 local tabvars rshlt_fp rhlthlm1 rbmi_not_normal radl_diff riadl_diff ///
rdepres reffort rsleepr rwhappy rflone rfsad rgoing renlife rcesd_gt3 ///
rlbrf1_ind1 rlbrf1_ind2 rlbrf1_ind3 
		
foreach v in `tabvars' {
	matrix t1=J(1,3,.)
	tab `v' , missing
	sum `v' /*[w=weight_comb]*/
	
	mat t1[1,1]=r(mean)*100
	
	foreach i in 0 1{
	sum `v' if  home_care_ind==`i' /*[w=weight_comb]*/
	mat t1[1,`i'+2]=r(mean)*100
	}

	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table1) sdec(2) varlabels 
	outreg , replay(table1a) append(table1) store(table1a)

}	
********************************************
local v rhours_worked
  qui summarize `v' 
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
 
  matrix rownames summstat = `v'
  
matrix pars = (1 )

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c1)

 qui summarize `v'  if home_care_ind==0
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c2)
  
outreg, replay(c1) merge(c2) store(c2a)
  
  qui summarize `v'  if home_care_ind==1
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
  
  matrix rownames summstat = `v'
  
frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")")  store(c3)

 outreg, replay(c2a) merge(c3) store(cont)

 outreg, replay(table1a) append(cont) store(table1a)


outreg using `logpath'/disp_pres_tab2, tex addtable ///
replay(table1a) landscape title("Table 4 - Outcomes by LTC Setting") ///
ctitles("","Overall","Nursing home","Home care" \ ///
"","N=`n_oa'","n=`n_nh'","n=`n_hc'" ) ///
note("HRS 1998-2010 waves, excluding other/unknown race, subsample receiving long-term care" \ ///
"Nursing home only vs home care and home care and nursing home care" \ ///
"Health limits worked = observation omitted if reports doesn't work" \ ///
"Wave 7 health limits work assumed yes if yes previous wave - data problem")
*********************************************************************
*********************************************************************
**Presentation Table 5
**X variables split by Waiver count above/below median 
*********************************************************************
local s wvrcount_gtp50
mata: mata clear

**first show home care treatment
local v home_care_ind

	sum `v' 
	mat t1[1,1]=r(mean)*100

	foreach i in 0 1 {
	sum `v' if `s'==`i'
	mat t1[1,`i'+2]=r(mean)*100
	}

	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels 
	outreg , replay(table2a) append(table2) store(table2a)



mat dmat=(0,1)
mat summstat = J(1,2,.)

local v ragey_e
  qui summarize `v' 
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
 
  matrix rownames summstat = `v'
  
matrix pars = (1 )

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c1)

 qui summarize `v'  if `s'==0
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)

frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")") store(c2)
  
outreg, replay(c1) merge(c2) store(c2a)
  
  qui summarize `v'  if home_care_ind==1
  mat summstat[1,1] = r(mean)
  mat summstat[1,2] = r(sd)
  
  matrix rownames summstat = `v'
  
frmttable, statmat(summstat) varlabels doubles(dmat) sdec(1) ///
  dbldiv(" (") annotate(pars) asymbol(")")  store(c3)

 outreg, replay(c2a) merge(c3) store(c3a)
 
 outreg, replay(table2a) append(c3a) store(table2a)
 
 
matrix t1=J(1,3,.)

foreach v in r_female_ind r_re_white r_re_black r_re_hisp r_ed_lt_hs r_ed_hs_only r_ed_gt_hs rmedicaid_sr {

	sum `v' 
	mat t1[1,1]=r(mean)*100
	
	foreach i in 0 1{
	sum `v' if `s'==`i'
	mat t1[1,`i'+2]=r(mean)*100
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

	sum `v'_n1  
	mat t1[1,1]=r(mean)*100

	foreach i in 0 1 {
	sum `v'_n1 if `s'==`i'
	mat t1[1,`i'+2]=r(mean)*100
	}

	mat rownames t1=`v'_n1
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels 
	outreg , replay(table2a) append(table2) store(table2a)
}

*sample sizes
sum year 
local n_oa=r(N)

sum year if `s'==0 
local n_nh=r(N)

sum year if `s'==1
local n_hc=r(N)


outreg using `logpath'/disp_pres_tab2.tex, tex landscape addtable ///
replay(table2a) title("Table 5: Sample Characteristics by Waiver Count") ///
ctitles("","Overall sample","Count $\leq$ 6","Count $>$6" \ ///
"","N=`n_oa'","n=`n_nh'","n=`n_hc'" ) ///
note("HRS 1998-2010 waves, excluding other/unknown race, subsample receiving long-term care" \ ///
"Median waiver count=6 during sample period among states represented in HRS sample" \ ///
"$^1$ lagged value - response from previous interview" \ ///
"Chronic conditions for count are high blood pressure, diabetes, cancer, lung disease," \ ///
"Heart disease, stroke, psychiatric condition, and arthritis.") 

**********************************************************************
**********************************************************************
** Spouse outcomes by race,ltc category
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

**get sample sizes
foreach i in 0 1 2{
tab year if sample1==1 & home_care_ind==0 & s_ivw_yes==1 & r_race_eth_cat==`i'
local n_0_`i'=r(N)
}
foreach i in 0 1 2{
tab year if sample1==1 & home_care_ind==1 & s_ivw_yes==1 & r_race_eth_cat==`i'
local n_1_`i'=r(N)
}

outreg using `logpath'/disp_pres_tab2.tex, tex landscape addtable ///
replay(table1a)  title("Table 5: Spouse Outcomes by HCBS Use and Race/Ethnicity") ///
ctitles("","Nursing Home","","","Home care","","" \ ///
"","White","Black","Hispanic","White","Black","Hispanic" \ ///
"","N=`n_0_0'","N=`n_0_1'","N=`n_0_2'","N=`n_1_0'","N=`n_1_1'","N=`n_1_2'") ///
multicol(1,2,3;1,5,3) ///
note("HRS 1998-2010 waves, subsample receiving LTSS with spouse interview" \ ///
"Nursing home only vs home care and home care and nursing home care" \ ///
"Health limits work = observation omitted if reports doesn't work" \ ///
"Wave 7 health limits work assumed yes if yes previous wave - data problem")

*********************************************************************88
log close
