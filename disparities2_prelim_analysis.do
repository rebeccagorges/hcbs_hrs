**Rebecca Gorges
**May 2017
**Disparities project preliminary analysis for PhD workshop presentation May 2017
**Uses hrs_sample_disparities.dta
**Limits dataset to 1998-2012 waves

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\dispar_prelim_analysis_log.txt, text replace
//log using E:\hrs\logs\dispar_prelim_analysis_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
**additional coding for disparities project
use hrs_sample_disparities.dta, clear

keep if sample1==1
*******************************************************
**plot waiver information by state over time
/*
preserve
collapse wvr_pop_12 scode_count wvr_respite_svc wvr_personal_home_care_svc wvr_count , by(state year) 

collapse wvr_pop_12 scode_count wvr_respite_svc wvr_personal_home_care_svc wvr_count , by(year) 

scatter wvr_pop_12 year
scatter wvr_respite_svc year
scatter wvr_personal_home_care_svc year
scatter wvr_count year
scatter scode_count year
restore
*/


*******************************************************
**table values of potential instruments by treatment status
la var wvr_pop_7 "Waiver Target Population=Alzheimers"
la var wvr_pop_12 "Waiver Target Population=Elderly"
la var wvr_case_manag_svc "Waiver Case Management Services"
la var wvr_personal_home_care_svc "Waiver Personal,Home Care Services"
la var wvr_prof_svc "Waiver Professional Services"
la var wvr_therapy_svc "Waiver Therapy Services"
la var wvr_respite_svc "Waiver Respite Services"
la var wvr_residential_svc "Waiver Residential Services" 
la var wvr_transit_drugs_svc "Waiver, Transportation or Rx"
la var wvr_count "Count of Waivers"
la var scode_count "Count of Waiver Service Codes"
la var nhbed_st "NH Beds/1000 residents"
la var homehealthagencies_st "Number home health agencies"
la var nursingfacilities_st "Nursing facilities"

**get waiver participants per 1000 population
gen wvr_bene_per_cap = wvr_recipttot/tot_pop_st*1000
sum wvr_bene_per_cap, detail

sca m=r(p50)
gen wvrbenpercap_gtp50 = 1 if wvr_bene_per_cap>m  
replace wvrbenpercap_gtp50 = 0 if wvr_bene_per_cap<=m 
sum wvr_bene_per_cap if wvrbenpercap_gtp50==1
sum wvr_bene_per_cap if wvrbenpercap_gtp50==0

la var wvrbenpercap_gtp50 "Waiver beneficaries/1000 pop gt median"
local wvrvars_d wvrbenpercap_gtp50 wvr_pop_7 wvr_pop_12 wvr_case_manag_svc wvr_personal_home_care_svc ///
 wvr_therapy_svc wvr_respite_svc wvr_residential_svc ///
 wvr_transit_drugs_svc 
 
local wvrvars_c wvr_count scode_count hcbsofltc ttlhcbsppl ttlhcbsexp

**dummy variables, use chi2 test
mat t_iv=J(1,6,.)
foreach v in `wvrvars_d'{
sum `v' if home_care_ind==0
mat t_iv[1,1]=r(mean)
mat t_iv[1,2]=r(sd)
sum `v' if home_care_ind==1
mat t_iv[1,3]=r(mean)
mat t_iv[1,4]=r(sd)

tab `v' home_care_ind, chi2
mat t_iv[1,5]=r(p)

mat rownames t_iv=`v'
mat list t_iv
	
frmttable , statmat(t_iv) store(table_iv) sdec(2) varlabels substat(1)
outreg , replay(table_iva) append(table_iv) store(table_iva)
}

mat t_iv=J(1,6,.)
foreach v in `wvrvars_c'{
sum `v' if home_care_ind==0
mat t_iv[1,1]=r(mean)
mat t_iv[1,2]=r(sd)
sum `v' if home_care_ind==1
mat t_iv[1,3]=r(mean)
mat t_iv[1,4]=r(sd)

ttest `v',by(home_care_ind)
mat t_iv[1,5]=r(p)

mat rownames t_iv=`v'
mat list t_iv
	
frmttable , statmat(t_iv) store(table_iv) sdec(2) varlabels substat(1)
outreg , replay(table_iva) append(table_iv) store(table_iva)
}


outreg using `logpath'/disp_pres_tab3.tex, tex landscape replace ///
replay(table_iva)  title("Table 6: HCBS Waivers, Expendiures") ///
ctitles("","Nursing Home","Home care","P-value") ///
note("HRS 1998-2010 waves, subsample receiving LTSS " \ ///
"Nursing home only vs home care and home care and nursing home care" \ ///
"P-value for test of difference; t-test for continuous; chisq test for binary")


*******************************************************
**main list used for full sample, no comorbidites as base 1,2 vs 3+
local xvars2 rage_cat4_2 rage_cat4_3 rage_cat4_4  ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 r_ed_hs_only r_ed_gt_hs ///
hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1 ///
rshlt_fp_n1 count_ccs_12_n1 count_ccs_gt2_n1 radlimpair_n1 

**try tamara's specification
**indicator for greater than median hcbs spending
sum hcbsofltc [aw=tot_pop_st], detail
gen hcbsofltc_gt_med=1 if hcbsofltc>r(p50)
replace hcbsofltc_gt_med=0 if hcbsofltc<r(p50)
tab hcbsofltc_gt_med, missing

sum ttlhcbsexp [aw=tot_pop_st], detail
gen ttlhcbsexp_gt_med=1 if ttlhcbsexp>r(p50)
replace ttlhcbsexp_gt_med=0 if ttlhcbsexp<r(p50)
tab ttlhcbsexp_gt_med, missing

local iv ttlhcbsexp_gt_med
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st] , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'

sum cmsttlhcbsexp [aw=tot_pop_st], detail
gen cmsttlhcbsexp_gt_med=1 if cmsttlhcbsexp>r(p50)
replace cmsttlhcbsexp_gt_med=0 if cmsttlhcbsexp<r(p50)
tab cmsttlhcbsexp_gt_med, missing

local iv cmsttlhcbsexp_gt_med
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st] , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'

**personal care expenditures as share of overall hcbs or overall ltss ??
**problem with this for cases where individual service code totals aren't provided
//egen phc_wvr_exp=total(scode_2_dollar+scode_3_dollar+scode_10_dollar+ ///
//scode_11_dollar+scode_12_dollar)

//gen phc_wvr_share=phc_wvr_exp / wvr_dollartot
//sum phc_wvr_share, detail
//sum phc_wvr_exp, detail
//sum wvr_dollartot, detail

gen wvrfrac = cmshcbswvexp / cmsttlhcbsexp 
sum wvrfrac, detail
sca m=r(p50)
gen wvrfrac_gtp50 = 1 if wvrfrac>m & !missing(wvrfrac)
replace wvrfrac_gtp50 = 0 if wvrfrac<=m & !missing(wvrfrac)
tab wvrfrac_gtp50, missing

local iv wvrfrac_gtp50
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st] , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'

tab r_sr_ltc_cat2 home_care_ind, missing


sum wvrfrac [aw=tot_pop_st], detail
sca m=r(p50)
gen wvrfrac_gtp50_w = 1 if wvrfrac>m & !missing(wvrfrac)
replace wvrfrac_gtp50_w = 0 if wvrfrac<=m & !missing(wvrfrac)
tab wvrfrac_gtp50_w, missing

local iv wvrfrac_gtp50_w
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st] , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'

local iv wvrfrac_gtp50_w
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st] if rage_lt_65==0, vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'

local iv nhbed_st
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st], vce(cluster hhidpn)

sum wvr_count, detail
sca m=r(p50)
gen wvrcount_gtp50 = 1 if wvr_count>m 
replace wvrcount_gtp50 = 0 if wvr_count<=m 
tab wvr_count wvrcount_gtp50, missing

local iv wvrcount_gtp50
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st], vce(cluster hhidpn)
xi: reg home_care_ind `iv' `xvars2' i.state i.year /*[aw=tot_pop_st]*/, vce(cluster hhidpn)

**try IV with beneficaries per capita gt/lt median
local iv wvrbenpercap_gtp50
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st], vce(cluster hhidpn)
xi: reg home_care_ind `iv' `xvars2' i.state i.year /*[aw=tot_pop_st]*/, vce(cluster hhidpn)

**also continuous iv
local iv wvr_bene_per_cap
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st], vce(cluster hhidpn)
xi: reg home_care_ind `iv' `xvars2' i.state i.year /*[aw=tot_pop_st]*/, vce(cluster hhidpn)

**********************************8
sum scode_count, detail
sca m=r(p50)
gen scodecount_gtp50 = 1 if scode_count>m & !missing(scode_count)
replace scodecount_gtp50 = 0 if scode_count<=m & !missing(scode_count) 
tab scode_count scodecount_gtp50, missing

local iv scodecount_gtp50
xi: reg home_care_ind `iv' `xvars2' i.state i.year [aw=tot_pop_st], vce(cluster hhidpn)
xi: reg home_care_ind `iv' `xvars2' i.state i.year /*[aw=tot_pop_st]*/, vce(cluster hhidpn)

//Table by having waiver count above/below the median
**characteristics
**table of characteristics,treatment (x variables) by race category and hc use

local v home_care_ind
matrix t1=J(1,6,.)

	foreach i in 0 1 2{
	
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
	}
	mat rownames t1=`v'
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels
	outreg , replay(table2a) append(table2) store(table2a)	

local v ragey_e //additional columns for mean,sd reported
matrix t1=J(1,12,.)

local c = 1
foreach i in 0 1 2{
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
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
	
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
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
	
	sum `v'_n1 if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v'_n1 if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
	mat t1[1,`i'+4]=r(mean)*100
	}

	mat rownames t1=`v'_n1
	mat list t1

	frmttable , statmat(t1) store(table2) sdec(2) varlabels 
	outreg , replay(table2a) append(table2) store(table2a)
}

outreg using `logpath'/disp_pres_tab4.tex , tex landscape replace ///
replay(table2a) title("Table 3a: Sample Characteristics by Race, Waiver") ///
ctitles("","Waivers$<$ Median","","","Waivers$>$Median","","" \ ///
"","White","Black","Hispanic","White","Black","Hispanic" ) ///
multicol(1,2,3;1,5,3) ///
note("HRS 1998-2010 waves, subsample receiving long-term care" \ ///
"Home care includes those home care only and also both home care and nursing home care" \ ///
"$^1$ lagged value - response from previous interview" \ ///
"Chronic conditions for count are high blood pressure, diabetes, cancer, lung disease," \ ///
"Heart disease, stroke, psychiatric condition, and arthritis.") 


**outcomes
**table of outcomes by race category and hc use
mata: mata clear
matrix t1=J(1,6,.)
foreach v in rmortality_1yr rmortality_2yr rhosp{

foreach i in 0 1 2{
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100 
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
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
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
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
	
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`i'+1]=r(mean)*100
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
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
	sum `v' if sample1==1 & wvrcount_gtp50==0 & r_race_eth_cat==`i'
	mat t1[1,`c']=r(mean)
	mat t1[1,`c'+1]=r(sd)
	
	sum `v' if sample1==1 & wvrcount_gtp50==1 & r_race_eth_cat==`i'
	mat t1[1,`c'+6]=r(mean)
	mat t1[1,`c'+7]=r(sd)
	
	local c = `c'+2
}

	mat rownames t1=`v'
	mat list t1
	
frmttable , statmat(t1) store(table1) sdec(2) varlabels substat(1)
outreg , replay(table1a) append(table1) store(table1a)

outreg using `logpath'/disp_pres_tab4.tex, tex landscape addtable ///
replay(table1a)  title("Table 4a: Outcomes by Waiver and Race/Ethnicity") ///
ctitles("","Waiver $\leq$ median","","","Waiver$>$Median","","" \ ///
"","White","Black","Hispanic","White","Black","Hispanic" ) ///
multicol(1,2,3;1,5,3) ///
note("HRS 1998-2010 waves, subsample receiving LTSS" \ ///
"below median (6) count of waivers vs above median" \ ///
"Health limits work = observation omitted if reports doesn't work" \ ///
"Wave 7 health limits work assumed yes if yes previous wave - data problem")

/*
local iv wvr_count
xi: reg home_care_ind `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
qui outreg, store(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

local iv wvr_count wvr_respite_svc
xi: reg home_care_ind `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
qui outreg, store(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

egen phc_dollar_tot=total(scode_2_dollar + scode_3_dollar + scode_10_dollar + ///
	scode_11_dollar + scode_12_dollar)
gen phc_dollar_share=phc_dollar_tot/wvr_dollartot

sum wvr_dollartot, detail
sum phc_dollar_share, detail

local iv phc_dollar_share
xi: reg home_care_ind `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
qui outreg, store(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

gen kff_thcbs_pp = ttlhcbsppl / totpop
gen wvr_pp = wvr_recipttot / totpop
sum kff_thcbs_pp, detail
sum wvr_pp, detail

local iv kff_thcbs_pp
xi: reg home_care_ind `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
qui outreg, store(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )
*/



*******************************************************
log close
