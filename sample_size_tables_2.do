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
graph export `logpath'\treat_time1.pdf, replace

*********************************************************************
** Plot of care setting among R's reporting nursing home and/or home care
** Now care setting breakdown nursing home only vs home care + nh together
*********************************************************************
preserve
tab r_sr_ltc_cat2 if r_sr_ltc_cat2!=0, gen(ltc_cat_ind) 
replace ltc_cat_ind2=1 if ltc_cat_ind3==1
collapse ltc_cat_ind1 ltc_cat_ind2 , by(year)

la var ltc_cat_ind1 "Nursing home"
la var ltc_cat_ind2 "Home care"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 2: medical services and/or other services; Home care includes those with both NH and HC") 
graph save plot2, replace

restore
*********************************************************************
preserve
tab r_sr_ltc_cat if r_sr_ltc_cat!=0, gen(ltc_cat_ind) 
replace ltc_cat_ind2=1 if ltc_cat_ind3==1
collapse ltc_cat_ind1 ltc_cat_ind2  , by(year)

la var ltc_cat_ind1 "Nursing home"
la var ltc_cat_ind2 "Home care"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Share of LTC users, by setting") ///
	note("LTC defn 1: medical services only; Home care includes those with both NH and HC") 
graph save plot1, replace
restore

graph combine plot1.gph plot2.gph
graph export `logpath'\treat_time2.pdf, replace


*********************************************************************
**limit to medicaid, treat vs control categories only
*********************************************************************
preserve
drop if rmedicaid_sr==0

tab r_sr_ltc_cat2 if r_sr_ltc_cat2!=0, gen(ltc_cat_ind) 
replace ltc_cat_ind2=1 if ltc_cat_ind3==1
collapse ltc_cat_ind1 ltc_cat_ind2 , by(year)

la var ltc_cat_ind1 "Nursing home"
la var ltc_cat_ind2 "Home care"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Medicaid sample: Share of LTC users, by setting") ///
	note("LTC defn 2: medical services and/or other services; Home care includes those with both NH and HC") 
graph save plot2, replace

restore
*********************************************************************
preserve
tab r_sr_ltc_cat if r_sr_ltc_cat!=0, gen(ltc_cat_ind) 
replace ltc_cat_ind2=1 if ltc_cat_ind3==1
collapse ltc_cat_ind1 ltc_cat_ind2  , by(year)

la var ltc_cat_ind1 "Nursing home"
la var ltc_cat_ind2 "Home care"
sort year
scatter ltc_cat_ind1 year,connect(l) ///
	|| scatter ltc_cat_ind2 year,connect(l) ///
	title("Medicaid sample: Share of LTC users, by setting") ///
	note("LTC defn 1: medical services only; Home care includes those with both NH and HC") 
graph save plot1, replace
restore

graph combine plot1.gph plot2.gph
graph export `logpath'\treat_time3.pdf, replace

*********************************************************************
**by state
*********************************************************************
preserve

tab r_sr_ltc_cat if r_sr_ltc_cat!=0, gen(ltc_cat_ind) 
replace ltc_cat_ind2=1 if ltc_cat_ind3==1
collapse ltc_cat_ind1 ltc_cat_ind2 ,by(state year)

la var ltc_cat_ind2 "Home care"

sort state year
twoway connected ltc_cat_ind2 year, connect(L) ///
title("Share of LTC users with Home Care") ///
note("LTC defn 1: medical services only; Home care includes those with both NH and HC") 
graph save plot1, replace
restore

**now medicaid only
preserve
drop if rmedicaid_sr==0

tab r_sr_ltc_cat if r_sr_ltc_cat!=0, gen(ltc_cat_ind) 
replace ltc_cat_ind2=1 if ltc_cat_ind3==1
collapse ltc_cat_ind1 ltc_cat_ind2 ,by(state year)

la var ltc_cat_ind2 "Home care"

sort state year
twoway connected ltc_cat_ind2 year, connect(L) ///
title("Medicaid sample: Share of LTC users with Home Care") ///
note("LTC defn 1: medical services only; Home care includes those with both NH and HC") 
graph save plot2, replace
restore

graph combine plot1.gph plot2.gph
graph export `logpath'\treat_time4.pdf, replace

*********************************************************************
**count of observations per state-year

sort state year
by state year : gen dup = cond(_N==1,0,_n) //number observation
by state year : egen nobs=max(dup)

keep if inlist(dup,0,1)
 
li state year nobs


 
*********************************************************************
log close
