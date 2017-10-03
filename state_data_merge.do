**R Gorges
**October 2017

**Merge the State level policy datasets together
**Files to merge are
** 1. UCSF provided Waiver information (1992-2012)
** 2. Truven, Eiken HCBS Rebalancing Report data (1996-2014)
** 3. KFF LTC HCBS Program data (1999-2013)

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\state_data_merge_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data

local state C:\Users\Rebecca\Documents\UofC\research\data\state

cd `data'
**********************************************************
use waivers_92_2012_to_merge, clear

sort state year

la var wvr_pop_1 "Intellectual Disabilities (ID)/ Mental Retardation (MR)"
la var wvr_pop_2 "Physical Disabilities"
la var wvr_pop_3 "Blind"
la var wvr_pop_4 "Developmental Disabilities (DD)"
la var wvr_pop_5 "Mental Health Disorders"
la var wvr_pop_6 "Autism"
la var wvr_pop_7 "Alzheimers"
la var wvr_pop_8 "Brain Injury (BI)"
la var wvr_pop_9 "HIV/AIDS"
la var wvr_pop_10 "Pregnant Women"
la var wvr_pop_11 "Children"
la var wvr_pop_12 "Elderly (age >=60 or 65)"
la var wvr_pop_13 "Not specified,adults,general population"

la var wvr_case_manag_svc "Waiver Case Management Services"
la var wvr_personal_home_care_svc "Waiver Personal,Home Care Services"
la var wvr_prof_svc "Waiver Professional Services"
la var wvr_therapy_svc "Waiver Therapy Services"
la var wvr_respite_svc "Waiver Respite Services"
la var wvr_residential_svc "Waiver Residential Services" 
la var wvr_supplies_dme_svc "Waiver, Supplies, DME Services"
la var wvr_transit_drugs_svc "Waiver, Transportation or Rx"

la var wvr_count "Count of waivers"
la var wvr_recipttot "Count of waiver recipients"
la var wvr_dollartot "Count of waiver expenditures"
la var wvr_daystot "Count of waiver days"

forvalues i = 1/30{
la var scode_`i'_ind "Service code `i' indicator 1=yes"
la var scode_`i'_recips "Service code `i' Recipients"
la var scode_`i'_dollar "Service code `i' Expenditures"
la var scode_`i'_days "Service code `i' Days"
}

**********************************************************
**merge in the Truven report data on Expenditures
capture drop _merge
merge 1:1 state year using `state'/ltss_exp_all_states_1996-2014.dta

drop _merge

merge 1:1 state year using `state'/kff_state_hcbs.dta
tab year if _merge==1
tab year if _merge==2
drop _merge
**********************************************************
**save state-year level dataset
save Medicaid_state_data_combined.dta, replace

describe

**********************************************************
log close
