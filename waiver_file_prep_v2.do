**New waiver prep file
**Takes initial file from Terence NG UCSF
**Adds waiver description by year
**Collapses to state-year with waiver counts, totals by service code

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\waiver_data_prep_v2_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data

cd `data'

**********************************************************
**file with target population data, originally in wide format
/*
**will merge just on state and waiver number
import excel using `data'/waivers/waivers_merged_lw_20170404.xlsx, ///
firstrow case(l) sheet("Sheet1") 

drop if state==""
drop if wvrnum==""

sort state wvrnum
quietly by state wvrnum :  gen dup = cond(_N==1,0,_n)
tab dup, missing

li if dup==1

rename intellectualdisabilitiesid pop_1
rename physicaldisabilities pop_2
rename blind pop_3
rename developmentaldisabilitiesdd pop_4
rename mentalhealthdisorders pop_5 
rename autism pop_6
rename alzheimers pop_7
rename braininjurybi pop_8
rename hivaids pop_9
rename pregnantwomen pop_10
rename children pop_11
rename elderlyage60or65 pop_12
rename notspecifiedadultsgeneralpo pop_13

la var pop_1 "Intellectual Disabilities (ID)/ Mental Retardation (MR)"
la var pop_2 "Physical Disabilities"
la var pop_3 "Blind"
la var pop_4 "Developmental Disabilities (DD)"
la var pop_5 "Mental Health Disorders"
la var pop_6 "Autism"
la var pop_7 "Alzheimers"
la var pop_8 "Brain Injury (BI)"
la var pop_9 "HIV/AIDS"
la var pop_10 "Pregnant Women"
la var pop_11 "Children"
la var pop_12 "Elderly (age >=60 or 65)"
la var pop_13 "Not specified,adults,general population"

forvalues i=1/13{
tab pop_`i',missing
destring pop_`i',replace
}

rename e y1990
rename f y1992
rename g y1994
rename h y1996
rename i y1998
rename j y2000
rename k y2002
rename l y2004
rename m y2006
rename n y2008
rename o y2010
rename p y2012
rename q y2014

sort state wvrnum

**save a version with all data fields
save hcbs_waiver_targetpop_raw_full.dta,replace

**drop data fields that we don't need and save
keep waivertitle wvrnum state waivertype pop_*

save hcbs_waiver_targetpop_raw.dta,replace
******************************************************
******************************************************
clear 

/*import excel using "`data'/misc_other_raw/92-10 Waiver Wade.xlsx", ///
firstrow case(l) sheet("Sheet1") 
save hcbs_waivers_all_raw_orig.dta, replace */

use hcbs_waivers_all_raw_orig.dta, clear
destring year ,replace
forvalues i=1/169{
destring scode`i',replace
destring recips`i',replace
destring days`i',replace
destring dollar`i',replace
}
rename days1699 days169

gen byte notnumeric=real(daystot)==.
tab notnumeric, missing
li wvrnum state daystot if notnumeric==1 & !missing(daystot)
replace daystot="" if notnumeric==1
destring daystot, replace
drop notnumeric

//gen begdate2=date(begdate,"DMY")
//format begdate2 %td

gen enddate2=date(enddate,"DMY")
format enddate2 %td

gen year2=year(enddate2)

rename title waivertitle

li state wvrnum year begdate enddate enddate2 waivertitle if year2==.

**manually fill in missing dates / year variable
replace enddate2=td(28feb2001) if state=="HI" & wvrnum=="40195" & year==1
replace enddate2=td(31dec1995) if state=="ND" & wvrnum=="273" & year==95
replace enddate2=td(31aug1992) if state=="NH" & wvrnum=="53.9" & year==92
replace enddate2=td(28feb1992) if state=="NJ" & wvrnum=="160" & year==92
replace enddate2=td(28feb2001) if state=="NJ" & wvrnum=="160" & year==1
replace enddate2=td(28feb2007) if state=="NJ" & wvrnum=="160" & year==7
replace enddate2=td(31aug1992) if state=="NY" & wvrnum=="238" & year==92
replace enddate2=td(30jun1998) if state=="OH" & wvrnum=="198" & year==98
replace enddate2=td(30jun1992) if state=="OH" & wvrnum=="218" & year==92
replace enddate2=td(31dec2009) if state=="WI" & wvrnum=="433" & year==9
replace enddate2=td(31dec2010) if state=="WI" & wvrnum=="433" & year==10
replace enddate2=td(31dec2009) if state=="WI" & wvrnum=="484" & year==9
replace enddate2=td(31dec2010) if state=="WI" & wvrnum=="484" & year==10
replace enddate2=td(31dec2009) if state=="WI" & wvrnum=="485" & year==9
replace enddate2=td(31dec2010) if state=="WI" & wvrnum=="485" & year==10
replace enddate2=td(30jun2009) if state=="WY" & wvrnum=="451" & year==9
replace enddate2=td(30jun2010) if state=="WY" & wvrnum=="451" & year==10
replace year2=year(enddate2) if year2==.

tab year2, missing

li wvrnum state begdate enddate2 year if year2==3099
replace enddate2=td(30jun1999) if state=="ME" & wvrnum=="276" & year==99
replace year2=year(enddate2) if year2==3099

**just keep 1998 and later to match HRS sample
drop if year2<1998

sort state wvrnum year2
quietly by state wvrnum year2:  gen dup = cond(_N==1,0,_n)
tab dup, missing

li state wvrnum year year2 begdate enddate enddate2 waivertitle if dup==4

**before deal with duplicates; aggregate totals by service code numbers
forvalues i = 1/30{
gen scode_`i'_ind=0
gen scode_`i'_recips_tot=0
gen scode_`i'_dollar_tot=0
gen scode_`i'_days_tot=0
	forvalues t = 1/169{
		replace scode_`i'_ind=1 if scode`t'==`i'
		replace scode_`i'_recips_tot=scode_`i'_recips_tot+recips`t' if scode`t'==`i' & !missing(recips`t')
		replace scode_`i'_dollar_tot=scode_`i'_dollar_tot+dollar`t' if scode`t'==`i' & !missing(dollar`t')
		replace scode_`i'_days_tot=scode_`i'_days_tot+days`t' if scode`t'==`i' & !missing(days`t')
		}
	}

**now create totals over instances of duplicates by state-year-waiver
sort state wvrnum year2
forvalues  i = 1/30{	
egen scode_`i'_inda=total(scode_`i'_ind), by(state wvrnum year2)
replace scode_`i'_inda=1 if scode_`i'_inda>1 & !missing(scode_`i'_inda)
egen scode_`i'_recips_a=total(scode_`i'_recips_tot), by(state wvrnum year2)
egen scode_`i'_dollar_a=total(scode_`i'_dollar_tot), by(state wvrnum year2)
egen scode_`i'_days_a=total(scode_`i'_days_tot), by(state wvrnum year2)
}
egen reciptot_a=total(reciptot), by(state wvrnum year2)
egen dollartot_a=total(dollarto), by(state wvrnum year2)
egen daystot_a=total(daystot), by(state wvrnum year2)


**drop variables/duplicates, rename variables
forvalues  i = 1/169{	
drop scode`i' recips`i' dollar`i' days`i'
}

forvalues  i = 1/30{	
drop scode_`i'_ind scode_`i'_recips_tot scode_`i'_dollar_tot scode_`i'_days_tot
rename scode_`i'_inda scode_`i'_ind
rename scode_`i'_recips_a scode_`i'_recips
rename scode_`i'_dollar_a scode_`i'_dollar
rename scode_`i'_days_a scode_`i'_days
}

drop reciptot dollarto daystot
rename reciptot_a reciptot
rename dollartot_a dollartot
rename daystot_a daystot

drop if dup>0
drop dup

**create aggregate by service code types (following ucsf groupings)
gen case_manag_svc=0
replace case_manag_svc=1 if scode_1_ind==1

gen personal_home_care_svc=0
foreach i in 2 3 10 11 12{
replace personal_home_care_svc=1 if scode_`i'_ind==1
}

gen prof_svc=0
foreach i in 14 15 16{
replace prof_svc=1 if scode_`i'_ind==1
}

gen therapy_svc=0
foreach i in 20 24 25 26 29{
replace therapy_svc=1 if scode_`i'_ind==1
}

gen respite_svc=0
foreach i in 4 6 18{
replace respite_svc=1 if scode_`i'_ind==1
}

gen residential_svc=0
foreach i in 7 17 19{
replace residential_svc=1 if scode_`i'_ind==1
}

gen supplies_dme_svc=0
foreach i in 5 9 13{
replace residential_svc=1 if scode_`i'_ind==1
}

gen transit_drugs_svc=0
foreach i in 21 22 28{
replace transit_drugs_svc=1 if scode_`i'_ind==1
}

save waivers_92_2010_clean.dta,replace
clear
******************************************************************
******************************************************************
**merge the two sheets by waiver number, state
use waivers_92_2010_clean.dta, clear
sort state wvrnum
merge m:1 state wvrnum using hcbs_waiver_targetpop_raw_full.dta

tab _merge,missing

**spot check of these is that waivers from target pop sheet missing in main
**sheet are missing because they are either before 1998 or after 2010
**so drop them all here
drop if _merge==2

drop _merge

save waivers_92_2010_clean_targetpop.dta,replace */
****************************************************
**now need to get dataset down to state-year level to merge with HRS
****************************************************
use waivers_92_2010_clean_targetpop.dta,clear

drop dup

sort state wvrnum year2
quietly by state wvrnum year2:  gen dup = cond(_N==1,0,_n)
tab dup, missing

sort state year2 wvrnum

forvalues c = 1/30{
egen scode_`c'_ind_a= max( scode_`c'_ind ), by(state year2)
egen scode_`c'_recips_a=total(scode_`c'_recips), by(state year2)
egen scode_`c'_dollar_a=total(scode_`c'_dollar), by(state year2)
egen scode_`c'_days_a=total(scode_`c'_days), by(state year2)
}

foreach v in case_manag personal_home_care prof therapy respite residential ///
supplies_dme transit_drugs {
egen `v'_svc_a=max(`v'_svc), by(state year2)
}

forvalues c = 1/13{
egen pop_`c'_a=max(pop_`c'), by(state year2)
}

egen reciptot_a=total(reciptot), by(state year2)
egen dollartot_a=total(dollartot), by(state year2)
egen daystot_a=total(daystot), by(state year2)

egen wvr_count=count(wvrnum),  by(state year2)

tab wvr_count,missing

******************************************************
** before collapsing to state-year, get counts for Tamara
//get count of new waivers from 2000-2012
/*preserve
sort state wvrnum begdate2
bys state  wvrnum: gen n=_n
keep if n==1 //keep first year of each waiver
keep if begdate2>=td(1jan2000) & begdate2<td(1jan2013)
egen n_new_waivers=total(n)
sum n_new_waivers

sort state wvrnum
bys state: gen n2=_n
bys state: gen nowaivers=_N

keep if n2==1
*count of waivers by state
sum nowaivers
restore  */

//get count of new waivers from 2005-2012
/*preserve
sort state wvrnum begdate2
bys state  wvrnum: gen n=_n
keep if n==1 //keep first year of each waiver
keep if begdate2>=td(1jan2005) & begdate2<td(1jan2013)
egen n_new_waivers=total(n)
sum n_new_waivers

sort state wvrnum
bys state: gen n2=_n
bys state: gen nowaivers=_N

keep if n2==1
*count of waivers by state
sum nowaivers
restore  */


//get count of new waivers for specific states (email 10/27)
/* preserve
sort state wvrnum begdate2
bys state  wvrnum: gen n=_n
keep if n==1 //keep first year of each waiver
keep if begdate2>=td(1jan2006) & begdate2<td(1jan2010) //want waivers 2007, 2008, 2009
keep if inlist(state,"CA","CO","ID","IL","MA","MD","NY","OR","PA")
sort state year
li state year wvrnum begdate2
restore */

********************************************************************
**now one observation per each year-waiver id
bys state year2 : gen n=_n
keep if n==1
drop n

keep state year2 wvr_count scode_*_a reciptot_a dollartot_a daystot_a *_svc_a pop_*_a

forvalues i=1/30{
rename scode_`i'_ind_a scode_`i'_ind
rename scode_`i'_recips_a scode_`i'_recips
rename scode_`i'_dollar_a scode_`i'_dollar
rename scode_`i'_days_a scode_`i'_days
}

rename reciptot_a wvr_recipttot
rename dollartot_a wvr_dollartot
rename daystot_a wvr_daystot

foreach v in case_manag personal_home_care prof therapy respite residential ///
supplies_dme transit_drugs {
rename `v'_svc_a wvr_`v'_svc
}

forvalues c = 1/13{
rename pop_`c'_a wvr_pop_`c'
}

rename year2 year
********************************************************************
save waivers_92_2010_to_merge.dta, replace

********************************************************************
log close
