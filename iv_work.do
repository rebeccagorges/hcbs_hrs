**Rebecca Gorges
**October 2016
**Uses hrs_sample3.dta
**First pass at first stage of potential IVs from the HCBS waiver data
**Limits dataset to 1998-2012 waves, age 70+ 

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\iv_prelim_log.txt, text replace
//log using E:\hrs\logs\iv_prelim_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

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

   
for each iv
	IVs are
		count of waivers
		quartiles, other divisions of waivers
		count of service codes
		quartiles, other divisions of service codes
		service codes related to dementia
		maybe look at rare service codes? (maybe less than 50% state-years??)
		
Possibly drop states with little variation in service codes		

for each sample/subsample
	samples are:
		full sample
		medicaid only subsample
		income < 25% subsample
		Medicaid + dementia subsample
		Sample dropping top 25% in income (and 20 and 10 percent)
		Sample dropping top 25% in assets (and 20 and 10 percent)
   
*/

**potential instruments

**waiver count , service codes variables
sum wvr_count_sy, detail
sum wvr_count_pctchange, detail
tab wvr_count_incr, missing
tab wvr_count_nodecr, missing
sum svc_code_count_sy , detail
tab svc_code_demsp , missing

la var svc_code_10_sy "Svc code 10: home health/home health aide"
tab svc_code_10_sy , missing
la var svc_code_12_sy "Svc code 12: personal care in home"
tab svc_code_12_sy , missing
la var svc_code_18_sy "Svc code 18: respite/caregiver or family support/edu"
tab svc_code_18_sy , missing
tab r_sr_ltc_cat2, missing

tab r_sr_ltc_cat2 svc_code_demsp if r_sr_ltc_cat2!=0, chi
tab r_sr_ltc_cat2 svc_code_10_sy if r_sr_ltc_cat2!=0, chi

tab r_sr_ltc_cat svc_code_10_sy if r_sr_ltc_cat!=0, chi

**rare service codes (see tab in log geo_data_merge.do
**have a service code that is present in <20% state-year
gen svc_code_rare=0 & !missing(svc_code_count_sy)
foreach i in 29 28 7 {
replace svc_code_rare=1 if svc_code_`i'_sy==1
}
tab svc_code_rare, missing

**spending on hcbs variables
sum hcbsofltc, detail //percentage of LTC spending on HCBS
sum cmsttlhcbsexp, detail //HCBS expenditure capita
sum cmshcbswvexp, detail //Waiver expediture per capita
la var cmshcbswvexp "Burwell total HCBS waiver expend"

**spending per enrollee
**note this restricts years to be 2000-2010
gen miss_ttlhcbsexp=1 if missing(ttlhcbsexp)
tab year miss_ttlhcbsexp , missing 
gen ttlhcbsexppenr = ttlhcbsexp/ttlhcbsppl
sum ttlhcbsexppenr, detail
sca m=r(p50)
gen ttlhcbsexppenr_gtp50 = 1 if ttlhcbsexppenr>m & !missing(ttlhcbsexppenr)
replace ttlhcbsexppenr_gtp50 = 0 if ttlhcbsexppenr<=m & !missing(ttlhcbsexppenr)
tab ttlhcbsexppenr_gtp50, missing

gen miss_cmshcbswvexp=1 if missing(cmshcbswvexp)
tab year miss_cmshcbswvexp , missing 
gen wvrfrac = cmshcbswvexp / cmsttlhcbsexp 
sum wvrfrac, detail
sca m=r(p50)
sca m75=r(p75)
gen wvrfrac_gtp50 = 1 if wvrfrac>m & !missing(wvrfrac)
replace wvrfrac_gtp50 = 0 if wvrfrac<=m & !missing(wvrfrac)
tab wvrfrac_gtp50, missing
gen wvrfrac_gtp75 = 1 if wvrfrac>m & !missing(wvrfrac)
replace wvrfrac_gtp75 = 0 if wvrfrac<=m & !missing(wvrfrac)
tab wvrfrac_gtp75, missing

**indicator for bottom x% for income and assets
foreach v in hcbsofltc{
foreach c in 60 70 80 90 {
	_pctile `v' if sample_criteria==1, p(`c')
	sca `v'`c'co=r(r1)
	gen `v'_gtp`c' = 1 if `v'>`v'`c'co & !missing(`v') & sample_criteria==1
	replace `v'_gtp`c' = 0 if `v'<=`v'`c'co & !missing(`v') & sample_criteria==1
	tab `v'_gtp`c', missing
	}
}

la var hcbsofltc_gtp60 "Top 40% of HCBS/LTC percentage" 
la var hcbsofltc_gtp70 "Top 30% of HCBS/LTC percentage"
la var hcbsofltc_gtp80 "Top 20% of HCBS/LTC percentage"
la var hcbsofltc_gtp90 "Top 10% of HCBS/LTC percentage"

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

local wvrvars wvr_count_sy svc_code_count_sy hcbsofltc cmsttlhcbsexp cmshcbswvexp
foreach name in `wvrvars' {
	xtile `name'q4=`name',nq(4)
	xtile `name'q2=`name',nq(2)
	} 
	
tab svc_code_count_syq4,gen(svc_code_count_syq4_)
tab hcbsofltcq2, gen(hcbsofltcq2_)
tab hcbsofltcq4, gen(hcbsofltcq4_)
tab cmsttlhcbsexpq4, gen(cmsttlhcbsexpq4_)
tab cmshcbswvexpq4, gen(cmshcbswvexp4_)


*create indicators from categorical variables
tab age_cat2, missing
**create coarser age categories
**75-84
gen age_75_84 = 1 if inlist(age_cat2,3,4)
replace age_75_84 = 0 if inlist(age_cat2,1,2,5,6)

**85+
gen age_gt84=1 if inlist(age_cat2,5,6)
replace age_gt84=0 if inlist(age_cat2,1,2,3,4)

tab r_race_eth_cat,gen(r_race_eth_cat)
rename r_race_eth_cat2 r_re_black
rename r_race_eth_cat3 r_re_hisp
rename r_race_eth_cat4 r_re_other

**use assets only bc highly correlated with income
pwcorr hatota5 hitot5
tab hatota5, gen(hatota5_)
tab hitot5, gen(hitot5_)

local xvars age_cat2_ind1 age_cat2_ind2 age_cat2_ind3 age_cat2_ind4 ///
age_cat2_ind5 age_cat2_ind6 age_75_84 age_gt84 r_female_ind r_re_black r_re_hisp r_re_other ///
r_married hanychild ed_hs_only hatota5_2 hatota5_3 hatota5_4 hatota5_5 ///
 hitot5_2 hitot5_3 hitot5_4 hitot5_5 ///
rshlt_fp rhibp_sr rdiab_sr rcancr_sr rlung_sr rheart_sr ///
rstrok_sr rpsych_sr rarthr_sr radlimpair dem_any_vars_ind sr_mem_dis_any

//need lagged x variables
sort hhidpn year
foreach x in `xvars'{
by hhidpn: gen `x'_n1=`x'[_n-1]
}

**drop observations
drop if age_cat2==1 //<70
drop if year==1996 //don't have lagged variables
**use census regions to drop people outside of the US
tab rcendiv,missing
drop if rcendiv==11 | rcendiv==.m
tab state, missing
drop if state=="PR" | state=="ZZ" | state=="RI" | state=="." | state=="AK"

tab state,missing

tab incomeltp25 hatota5_1, missing

//(lagged) control variables list
//base cats are age 70-74; male, white, not married, no children, gt HS degree, low q assets ///
// no chronic diseases, no adl impairment, no dementia
local xvars2 age_75_84_n1 age_gt84_n1  ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1 ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 sr_mem_dis_any_n1

**remember income variable is created for >70 group
foreach x in `xvars' `xvars2'{
tab `x' if !missing(hctreat1),missing
}

foreach x in `xvars' `xvars2'{
tab `x' year if !missing(hctreat1) & inlist(year,1996,1998,2000),missing
}

**assets < 20% subsample
tab incomeltp25 hatota5_1, missing

save analysis.dta,replace 

use analysis.dta,replace

la var hctreat1 "Home care"
la var wvr_count_sy "Waiver count"
la var svc_code_count_sy "Service code count"
la var svc_code_count_syq4_2 "Q2 svc code count"
la var svc_code_count_syq4_3 "Q3 svc code count"
la var svc_code_count_syq4_4 "Q4 (top) svc code count"
la var svc_code_demsp "Home medical care svc code"

**cc count variables
gen count_ccs_n1=0
foreach v in rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 {
replace count_ccs_n1=count_ccs_n1+`v' if !missing(`v')
}
tab count_ccs_n1 if !missing(hctreat2), missing
gen count_ccs_0_n1=1 if count_ccs_n1==0
replace count_ccs_0_n1=0 if count_ccs_n1!=0 & !missing(count_ccs_n1)
gen count_ccs_12_n1=1 if inlist(count_ccs_n1,1,2)
replace count_ccs_12_n1=0 if count_ccs_n1!=1 & count_ccs_n1!=2 & !missing(count_ccs_n1)
gen count_ccs_gt2_n1=1 if count_ccs_n1>2 & !missing(count_ccs_n1)
replace count_ccs_gt2_n1=0 if inlist(count_ccs_n1,0,1,2) & !missing(count_ccs_n1)

foreach v in count_ccs_0_n1 count_ccs_12_n1 count_ccs_gt2_n1{
tab count_ccs_n1 `v',missing
}


/*local xvars2 age_75_84_n1 age_gt84_n1  ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hitot5_2_n1 hitot5_3_n1 hitot5_4_n1 hitot5_5_n1 ///
rshlt_fp_n1 rhibp_sr_n1 rdiab_sr_n1 rcancr_sr_n1 rlung_sr_n1 rheart_sr_n1 ///
rstrok_sr_n1 rpsych_sr_n1 rarthr_sr_n1 radlimpair_n1 sr_mem_dis_any_n1*/

**regression control variables lists

**main list used for full sample, no comorbidites as base 1,2 vs 3+
local xvars2 age_75_84_n1 age_gt84_n1  ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hitot5_2_n1 hitot5_3_n1 hitot5_4_n1 hitot5_5_n1 ///
rshlt_fp_n1 count_ccs_12_n1 count_ccs_gt2_n1 radlimpair_n1 sr_mem_dis_any_n1

//same list but excluding assets since restricting to medicaid group
local xvars_noassets age_75_84_n1 age_gt84_n1  ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only /*hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1*/ ///
rshlt_fp_n1 count_ccs_12_n1 count_ccs_gt2_n1  radlimpair_n1 sr_mem_dis_any_n1

//same list but excluding dementia,assets since restricting to medicaid,dementia group
local xvars_nodem age_75_84_n1 age_gt84_n1  ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only /*hatota5_2_n1 hatota5_3_n1 hatota5_4_n1 hatota5_5_n1*/ ///
rshlt_fp_n1 count_ccs_12_n1 count_ccs_gt2_n1  radlimpair_n1 /*sr_mem_dis_any_n1*/


**look at variation in state-year waiver count
tab state, gen(stateind)
forvalues i=1/49{
di "state = stateind`i'==1"
tab wvr_count_sy year if stateind`i'==1
}

**list of states with no variation in waiver count in the estimation sample
gen novarst=0 
foreach i in 48 3{
replace novarst=1 if stateind`i'==1
}
tab novarst, missing

**with only 2 different values for waiver count during the period
gen novarst_1=0
replace  novarst_1=1 if novarst==1
foreach i in  12 21 22 23 30 33 39 45{
replace novarst_1=1 if stateind`i'==1
}
tab novarst_1, missing

/*
********************************************************************
** waiver count by wave-year
di "Instrument = Waiver count (state-year level), OLS, full sample"
local iv wvr_count_sy
xi: reg hctreat2 `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
qui outreg, store(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

**************************************************************************
**waiver count by interview date year
di "Instrument = Waiver count (state-year level), OLS, full sample"
local iv wvr_count_sy2
xi: reg hctreat2 `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
outreg, merge(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

tab riwendy year if e(sample)==1 

************************************************************************
**version with waiver info, fixed effects at interview year
di "Instrument = Waiver count (state-year level), OLS, full sample"
local iv wvr_count_sy2
xi: reg hctreat2 `iv' `xvars2' i.state i.riwendy , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
outreg, merge(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

tab riwendy year if e(sample)==1 
************************************************************************

**version using top,bottom quartile of waiver counts as instruments
tab wvr_count_syq4, gen(wvr_count_syq4)

local iv /*wvr_count_syq42 wvr_count_syq43*/ wvr_count_syq44
xi: reg hctreat2 `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
local c = 1
outreg, merge(t1) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full sample", "X" )

*/

**generate sample variables
gen sample1=1
la var sample1 "Full sample"
gen sample2=1 if rmedicaid_sr==1
la var sample2 "Medicaid (sr) sample"
gen sample3=1 if incomeltp25==1
la var sample3 "Income <p25% sample"
gen sample4=1 if dem_any_vars_ind==1 & rmedicaid_sr==1
la var sample4 "Medicaid,dementia sample"
gen sample5=1 if incomeltp90==1
la var sample5 "Excludes top 10% income"
gen sample6=1 if incomeltp80==1
la var sample6 "Excludes top 20% income"
gen sample7=1 if incomeltp75==1
la var sample7 "Excludes top 25% income"
gen sample8=1 if assetsltp90==1
la var sample8 "Excludes top 10% assets"
gen sample9=1 if assetsltp80==1
la var sample9 "Excludes top 20% assets"
gen sample10=1 if assetsltp75==1
la var sample10 "Excludes top 25% assets"
gen sample11=1 if novarst!=1 
la var sample11 "Excludes st with no var in waiver count"
gen sample12=1 if novarst_1!=1 
la var sample12 "Excludes st with only two values of waiver count"
gen sample13=1 if hchildnearby==0 
la var sample13 "Excludes R's with res child or child wi 10mi"
gen sample14=1 if impute_fl==0
la var sample14 "Excludes state-years with imputed waiver info"
gen sample15=1 if impute_fl==0 & incomeltp80==1
la var sample15 "Excludes st-yr with imputed waiver and top 20% income"

**************************************************************************
**************************************************************************

foreach v in 1 2 /*3*/{

di "**********************************************"
di "**********************************************"
di "**********************************************"
di " Definition of home care # `v' "
di "**********************************************"
di "**********************************************"
di "**********************************************"
**waiver count **ri dropped because too few observations
di "Instrument = Waiver count (state-year level), OLS"
local iv wvr_count_sy
local i =1 
forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/ , vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg,  merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "Sample`s'", "X" ) ///
	title("IV = waiver count")
	}

**waiver count percentage change from previous year
di "Instrument = Waiver count % change (state-year level), OLS"
local iv wvr_count_pctchange
local i =`i'+1 
forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1  /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg,  merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "Sample`s'", "X" ) ///
	title("IV = waiver count percentage change from prev year")
	}	


**waiver count increase from previous year
di "Instrument = Waiver count increase (state-year level), OLS"
local iv wvr_count_incr
local i =`i'+1 
forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1  /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg,  merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "Sample`s'", "X" ) ///
	title("IV = waiver count increase from prev year")
	}	

**waiver count same or increase from previous year
di "Instrument = Waiver count same or increase (state-year level), OLS"
local iv wvr_count_nodecr
local i =`i'+1 
forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1  /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg,  merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "Sample`s'", "X" ) ///
	title("IV = waiver count same or increase from prev year")
	}		
	
**************************************************************************
**service code count
/*di "Instrument = Service code count (state-year level), OLS"
local iv svc_code_count_sy
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year  if sample`s'==1  [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'
	
	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "Sample`s'", "X" ) ///
	title("IV = Service code count")
	}

**************************************************************************	
**Quartile of service codes 
di "Instrument = Quartile Service code count (state-year level), OLS"
local iv svc_code_count_syq4_2 svc_code_count_syq4_3 svc_code_count_syq4_4
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "Sample`s'", "X" ) ///
	title("IV = quartile service code count")
	}

**************************************************************************	
**dementia service codes,
di "Instrument = Dementia Service code count (state-year level), OLS "
local iv svc_code_demsp
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = dementia service codes")
	}
*/		
**************************************************************************	
**service codes 7 28 or 29 (<20% state-years contain these codes, signs of generous state?)
di "Instrument = Any of service codes 7, 28 or 29 (state-year level), OLS "
local iv svc_code_rare
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = service codes 7, 28 or 29")
	}	

*********************************************************
**specific home health services codes
/* **** result in negative relationship between service code and home care
local iv svc_code_10_sy
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = service code 10")
	}	
	
*********************************************************
**specific home health services codes
local iv svc_code_12_sy
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = service code 12")
	}	
	
*********************************************************
**specific home health services codes
local iv svc_code_18_sy
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = service code 18")
	}	
*/	
	
**************************************************************************	
**percentage of ltc spending on hcbs
di "Instrument = percentage of LTC spending on HCBS, OLS "
local iv hcbsofltc
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	test `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = percentage of ltc spending on hcbs")
	}

**top 50% of percentage of ltc spending on hcbs
di "Instrument = above median in percentage of LTC spending on HCBS, OLS "
local iv hcbsofltcq2_2	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = above median in percentage of ltc spending on hcbs")
	}	

**top 60% of percentage of ltc spending on hcbs
di "Instrument = above p60 in percentage of LTC spending on HCBS, OLS "
local iv hcbsofltc_gtp60	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = above p60 in percentage of ltc spending on hcbs")
	}		

**top 70% of percentage of ltc spending on hcbs
di "Instrument = above p70 in percentage of LTC spending on HCBS, OLS "
local iv hcbsofltc_gtp70	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = above p70 in % ltc spending on hcbs")
	}		
	
**quartiles of percentage of ltc spending on hcbs
di "Instrument = Quartiles percentage of LTC spending on HCBS, OLS "
local iv hcbsofltcq4_2  hcbsofltcq4_3  hcbsofltcq4_4	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = quartiles percentage of ltc spending on hcbs")
	}	
	
**hcbs spending per person
**doesn't work, estimates coef and se=0
di "Instrument = HCBS spending/person, OLS "	
local iv cmsttlhcbsexp	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	test `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = HCBS spending per person")
	}

**quartile hcbs spending per person
di "Instrument = Quartile HCBS spending/person, OLS "	
local iv cmsttlhcbsexpq4_2 cmsttlhcbsexpq4_3 cmsttlhcbsexpq4_4	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartiles HCBS spending per person")
	}
	
**************************************************************	
**waiver hcbs spending per person
**doesn't work, estimates coef and se=0

di "Instrument = HCBS Waiver spending/person, OLS "	
local iv cmshcbswvexp 	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	test `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = HCBS Waiver spending per person")
	}	
	
**quartile hcbs waiver spending per person
di "Instrument = Quartile HCBS Waiver spending/person, OLS "	
local iv cmshcbswvexp4_2 cmshcbswvexp4_3 cmshcbswvexp4_4	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartile HCBS Waiver spending per person")
	}	
	
************************************************************
**quartile hcbs waiver spending per person
di "Instrument = KFF HCBS expend/HCBS participant > median, OLS "	
local iv ttlhcbsexppenr_gtp50	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Greater than median HCBS spending/participant")
	}
	
	
************************************************************
	**quartile hcbs waiver spending per person
di "Instrument = Greater than median Wvr spending / HCBS spending "	
local iv wvrfrac_gtp50	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Above p50 waiver spending as fraction of total HCBS spending")
	}
	
************************************************************
	**quartile hcbs waiver spending per person
di "Instrument = Top 25% wvr spending / HCBS spending "	
local iv wvrfrac_gtp75	
local i =`i'+1 

forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 /*[aw=tot_pop_st]*/, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(iv`i'_`v') store(iv`i'_`v') ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Above p75 waiver spending as fraction of total HCBS spending")
	}
	
}


**************************************************************************
local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

**first one do outside loop to replace word doc
local t = 1
outreg using `logpath'/iv_firststage.doc, ///
replay(iv`t'_1) note("Outcome=Home care defined as medical home care") ///
landscape replace

forvalues t=2/`i'{
outreg using `logpath'/iv_firststage.doc, ///
replay(iv`t'_1) note("Outcome=Home care defined as medical home care") ///
landscape addtable
}


forvalues t=1/`i'{
outreg using `logpath'/iv_firststage.doc, ///
replay(iv`t'_2) note("Outcome=Home care defined as medical or other services") ///
landscape addtable
}

/*
forvalues t=1/`i'{
outreg using `logpath'/iv_firststage.doc, ///
replay(iv`t'_3) note("Outcome=Home care defined as medical or other services or helper") ///
landscape addtable
}
*/
*/
/*

**************************************************************************
**Additional tries 
local iv wvr_count_sy
*************************************************************************
** vary sample by cutting top x-tile of income,assets distribution
local c = 1
di "Instrument = Waiver count (state-year level), OLS, full sample"
xi: reg hctreat2 `iv' `xvars2' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
outreg, merge(t2a) store(t2a) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full Sample", "X" )

local c = 2
foreach v in incomeltp90 incomeltp80 incomeltp75 assetsltp90 assetsltp80 assetsltp75 {
di "Instrument = Waiver count (state-year level), OLS, if `v'==1"
xi: reg hctreat2 `iv' `xvars2' i.state i.year ///
	if `v'==1 , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
outreg, merge(t2a) store(t2a) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Sample `v'=1", "X" )
local c = `c'+1
}

outreg using `logpath'/iv_firststage.doc, replay(t2a) ///
title("IV=waiver count, testing different samples based on income and assets") ///
addtable

tab incomeltp75 incomeltp90

tab incomeltp75 incomeltp80

tab hctreat2 year,missing

***********************************************************************
**modify covariates, age, assets as continuous, dementia=self report (consistent with other sr)
sum ragey_e, detail
gen agesq=ragey_e*ragey_e
**note also tried using ln assets, log(assets) as continuous variable but it did not work

local xvars3 ragey_e agesq ///
r_female_ind r_re_black r_re_hisp r_re_other ///
r_married_n1 hanychild_n1 ed_hs_only hitot5_2_n1 hitot5_3_n1 hitot5_4_n1 hitot5_5_n1 ///
rshlt_fp_n1 count_ccs_12_n1 count_ccs_gt2_n1 radlimpair_n1 sr_mem_dis_any_n1

local c=1
di "Instrument = Waiver count (state-year level), OLS, full sample"
xi: reg hctreat2 `iv' `xvars3' i.state i.year , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
outreg, merge(t3) store(t3) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Full Sample", "X" )

local c = 2
foreach v in incomeltp90 incomeltp80 incomeltp75 assetsltp90 assetsltp80 assetsltp75 {
di "Instrument = Waiver count (state-year level), OLS, if `v'==1"
xi: reg hctreat2 `iv' `xvars3' i.state i.year ///
	if `v'==1 , vce(cluster hhidpn)
testparm `iv'
local f: display %5.2f `r(F)'
outreg, merge(t3) store(t3) ///
stat(b se) keep(`iv') varlabels ctitle("","`c'") ///
addrows("F-test IV", "`f'" \ "Sample `v'=1", "X" )
local c = `c'+1
}

outreg using `logpath'/iv_firststage.doc, replay(t3) ///
title("IV=waiver count, cont covariates, testing different samples based on income and assets") ///
addtable

*/

********************************************************************************
**check different cutpoints for hcbsofltc variable
********************************************************************************
/*
**di "Instrument = Quartile HCBS Waiver spending per person, OLS "	
local iv hcbsofltcq2_2	
local i =`i'+1 

local v = 2
local s = 1
//forvalues s = 1/13{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartile HCBS Waiver spending per person")
//	}	
	
di "Instrument = Quartile HCBS Waiver spending per person, OLS "	
local iv hcbsofltc_gtp60	
local i =`i'+1 

local s = 1
//forvalues s = 1/13{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartile HCBS Waiver spending per person")
//	}	

di "Instrument = Quartile HCBS Waiver spending per person, OLS "	
local iv hcbsofltc_gtp70	
local i =`i'+1 

local s = 1
//forvalues s = 1/13{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartile HCBS Waiver spending per person")
//	}

di "Instrument = Quartile HCBS Waiver spending per person, OLS "	
local iv hcbsofltc_gtp80	
local i =`i'+1 

local s = 1
//forvalues s = 1/13{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartile HCBS Waiver spending per person")
//	}
	
	di "Instrument = Quartile HCBS Waiver spending per person, OLS "	
local iv hcbsofltc_gtp90	
local i =`i'+1 

local s = 1
//forvalues s = 1/13{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" ) ///
	title("IV = Quartile HCBS Waiver spending per person")
//	}
*/
********************************************************************************
**try weight by number of waiver participants - ttlhcbsppl
di "Instrument = Top 50% in HCBS / LTC spending fraction , OLS "	
local iv hcbsofltcq2_2	
local i =`i'+1 
local v = 1
local s = 7
//forvalues s = 1/13{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1, vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" \ "No weighting", "X" ) ///
	title("IV = Top 50% HCBS/LTC spending")
//	}
	
di "Instrument = Top 50% in HCBS / LTC spending fraction , OLS "	
local iv hcbsofltcq2_2	
local i =`i'+1 

//forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=ttlhcbsppl], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" \ "Weight=number HCBS part.", "X" ) ///
	title("IV = Top 50% HCBS/LTC spending")
//	}	

di "Instrument = Top 50% in HCBS / LTC spending fraction , OLS "	
local iv hcbsofltcq2_2	
local i =`i'+1 

//forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=ttlhcbsexp], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" \ "Weight=HCBS spending", "X" ) ///
	title("IV = Top 50% HCBS/LTC spending")
//	}	

di "Instrument = Top 50% in HCBS / LTC spending fraction , OLS "	
local iv hcbsofltcq2_2	
local i =`i'+1 

//forvalues s = 1/15{
	xi: reg hctreat`v' `iv' `xvars2' i.state i.year if sample`s'==1 [aw=tot_pop_st], vce(cluster hhidpn)
	testparm `iv'
	local f: display %5.2f `r(F)'

	outreg, merge(test1) store(test1) ///
	stat(b se) keep(`iv') varlabels ctitle("","`s'") ///
	addrows("F-test IV", "`f'" \ "sample`s'", "X" \ "Weight=State-year population", "X" ) ///
	title("IV = Top 50% HCBS/LTC spending")
//	}

	
**************************************************************************
log close
