**exploratory work, trends over time for overall sample information
**september 2017

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\sample_sizes_prelim_log_2.txt, text replace
//log using E:\hrs\logs\sample_sizes_prelim_log_2.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
use hrs_sample3.dta, clear

tab year, missing

*********************************************************************
**Drop observations, assign sample variables
*********************************************************************
**wave 3(1996) doesn't have full cog battery asked so drop from the ds
tab pred_dem_cat1 wave, missing
drop if wave==3

**age 65+
gen sample1=1 if rage_lt_65==0
**age 65+ and spouse interview
gen sample2=1 if rage_lt_65==0&s_ivw_yes==1

**generate indicators for the three definitions of home care
**home care using medical home care services question only
gen ltc_ind1=1 if inlist(r_sr_ltc_cat,1,2,3)
replace ltc_ind1=0 if r_sr_ltc_cat==0

tab r_sr_ltc_cat ltc_ind1,missing

**home care medical and/or other services questions
gen ltc_ind2=1 if inlist(r_sr_ltc_cat2,1,2,3)
replace ltc_ind2=0 if r_sr_ltc_cat2==0

tab r_sr_ltc_cat2 ltc_ind2,missing

**home care medical and/or other services questions and/or adl/iadl helper
gen ltc_ind3=1 if inlist(r_sr_ltc_cat3,1,2,3)
replace ltc_ind3=0 if r_sr_ltc_cat3==0

tab r_sr_ltc_cat3 ltc_ind3,missing
*********************************************************************
** Plot of care setting among R's reporting nursing home and/or home care
*********************************************************************
preserve
tab r_sr_ltc_cat2 if r_sr_ltc_cat2!=0, gen(ltc_cat_ind) 
collapse ltc_cat_ind1 ltc_cat_ind2 ltc_cat_ind3 , by(year)

la var ltc_cat_ind1 "Nursing home only"
la var ltc_cat_ind2 "Home care only"
la var ltc_cat_ind3 "Nursing home and home care"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	|| scatter ltc_cat_ind3 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 2: medical services and/or other services") 
graph save plot2, replace

restore
*********************************************************************
preserve
tab r_sr_ltc_cat if r_sr_ltc_cat!=0, gen(ltc_cat_ind) 
collapse ltc_cat_ind1 ltc_cat_ind2 ltc_cat_ind3 , by(year)

la var ltc_cat_ind1 "Nursing home only"
la var ltc_cat_ind2 "Home care only"
la var ltc_cat_ind3 "Nursing home and home care"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	|| scatter ltc_cat_ind3 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 1: medical services only") 
graph save plot1, replace
restore

graph combine plot1.gph plot2.gph
*********************************************************************
** For high vs low HCBS states
** Combine so nursing home only vs home care only + nh+hc categories
*********************************************************************
gen statecat=1 if inlist(state,"MS","IN","FL") //low HCBS share states
replace statecat=2 if inlist(state,"OR","MN","NM") //high HCBS share states
** classified using 2014 LTSS Share, top and bottom 3 states

gen ltc_cat_binary=1 if r_sr_ltc_cat2==2 | r_sr_ltc_cat2==3
replace ltc_cat_binary=0 if r_sr_ltc_cat2==1 //nh only
/*
preserve
drop if statecat!=1
tab ltc_cat_binary , gen(ltc_cat_ind) 

collapse ltc_cat_ind1 ltc_cat_ind2  , by(year)
la var ltc_cat_ind1 "Nursing home only"
la var ltc_cat_ind2 "Home care (nh+hc and hc only)"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 2, low HCBS states in 2014: MS, IN, FL") 
graph save plot1, replace

restore

preserve
drop if statecat!=2
tab ltc_cat_binary , gen(ltc_cat_ind) 

collapse ltc_cat_ind1 ltc_cat_ind2  , by(year)
la var ltc_cat_ind1 "Nursing home only"
la var ltc_cat_ind2 "Home care (nh+hc and hc only)"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 2, high HCBS states in 2014: OR, MN, NM") 
graph save plot2, replace

restore
graph combine plot1.gph plot2.gph
*/
*********************************************************************
**limit to medicaid 
*********************************************************************

drop if rmedicaid_sr==0
preserve
drop if statecat!=1
tab ltc_cat_binary , gen(ltc_cat_ind) 

collapse ltc_cat_ind1 ltc_cat_ind2  , by(year)
la var ltc_cat_ind1 "Nursing home only"
la var ltc_cat_ind2 "Home care (nh+hc and hc only)"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 2, low HCBS states in 2014: MS, IN, FL") 
graph save plot1, replace

restore

preserve
drop if statecat!=2
tab ltc_cat_binary , gen(ltc_cat_ind) 

collapse ltc_cat_ind1 ltc_cat_ind2  , by(year)
la var ltc_cat_ind1 "Nursing home only"
la var ltc_cat_ind2 "Home care (nh+hc and hc only)"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 2, high HCBS states in 2014: OR, MN, NM") 
graph save plot2, replace

restore
graph combine plot1.gph plot2.gph
