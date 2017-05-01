**Rebecca Gorges
**September 2016
**Cleans variables used for analysis for full dataset created in geo_data_merge.do

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\coding_vars2_log.txt, text replace
//log using E:\hrs\logs\coding_vars2_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'
**long ds with waves 4-11 from RAND with variables coded
use hrs_sample2.dta, clear
****************************************************************
tab year, missing

****************************************************************
**Dementia indicators
****************************************************************
**dementia vs no using TICS, dementia probability, self report
la def pred_dem_cat 1 "Dementia" 2"CIND" 3"Normal"
la val pred_dem_cat pred_dem_cat
 
tab pred_dem_cat, missing
tab rsr_mem_dis_any , missing
tab rcogimp_tics_ind, missing

**indicators for dementia, cind categories
tab pred_dem_cat,gen(pred_dem_cat)
la var pred_dem_cat1 "Predicted dementia"
la var pred_dem_cat2 "Predicted CIND"
la var pred_dem_cat3 "Predicted normal"

tab pred_dem_cat1, missing
tab rsr_mem_dis_any , missing
tab rcogimp_tics_ind, missing
tab cog_missing rproxy, missing //cog_missing=1 if both iqcode and tics are missing
tab iqcode_missing rproxy, missing

sum pdem if cog_missing==1, detail //probability dementia not calculated if cog missing in this methodology
sum pdem if cog_missing==1 &rproxy==1, detail
sum pdem if cog_missing==1 &rproxy==0, detail

la var rsr_mem_dis_any "R Self report memory disease"
la var rcogimp_tics_ind "TICS score <8"

//gen indicators for different tics cutoffs based on distr in sample
//sample limited to age 70+, wave 1998 and later
gen sample_criteria=0
replace sample_criteria=1 if rage_lt_70==0 & wave>3
tab sample_criteria, missing

sum rcogtot if sample_criteria==1, detail
foreach i in 10 25 50{
	sca tics`i'=r(p`i')
}

foreach i in 10 25 50{
	gen tics_ltp`i'=1 if rcogtot<tics`i' & sample_criteria==1
	replace tics_ltp`i'=0 if rcogtot>tics`i' & !missing(rcogtot) & sample_criteria==1
	tab tics_ltp`i' tics_missing, missing
}

tab rcogtot if tics_ltp10==1, missing //tics <13 is bottom 10%
tab rcogtot if tics_ltp25==1, missing //tics <17 is bottom 25%
tab rcogtot if tics_ltp50==1, missing //tics <21 is bottom 50%

la var tics_ltp10 "TICS score lower 10% (<13)"
la var tics_ltp25 "TICS score lower 25% (<17)"
la var tics_ltp50 "TICS score lower 50% (<21)"
la var tics_missing "TICS score missing"

//indicators for iqcode cutoffs, using the mean variable
sum iqmean if sample_criteria==1, detail
foreach i in 90 75 50{
	sca iqmean`i'=r(p`i')
}
foreach i in 90 75 50{
	gen iqmean_gtp`i'=1 if iqmean>=iqmean`i' & !missing(iqmean) & sample_criteria==1
	replace iqmean_gtp`i'=0 if iqmean<iqmean`i' & sample_criteria==1
	tab iqmean_gtp`i' iqcode_missing, missing
}

gen iqmean_gtco=1 if  iqmean>=3.38 & !missing(iqmean)
replace iqmean_gtco=0 if iqmean<3.38 

la var iqmean_gtp90 "IQCODE mean score gt 90% (=5)"
la var iqmean_gtp75 "IQCODE mean score gt 75% (>4.31)"
la var iqmean_gtp50 "IQCODE mean score gt 50% (>3.125)"
la var iqmean_gtco "IQCODE mean >3.38"
la var iqcode_missing "IQCODE mean missing"

**************************************************************************
**cognition variables, using both proxy and self interviews
gen cog_comb=1 if rcogimp_tics_ind==1 | iqmean_gtco==1
replace cog_comb=0 if (rcogimp_tics_ind==0 & rproxy==0) | (iqmean_gtco==0 & rproxy==1)
la var cog_comb "TICS score <8 or IQMEAN>3.38"

tab cog_comb rproxy, missing

gen cog_comb1=1 if tics_ltp10==1 | iqmean_gtp90==1
replace cog_comb1=0 if (tics_ltp10==0 & rproxy==0) | (iqmean_gtp90==0 & rproxy==1)
la var cog_comb1 "TICS score 10% or IQMEAN>90%"

gen cog_comb2=1 if tics_ltp25==1 | iqmean_gtp75==1
replace cog_comb2=0 if (tics_ltp25==0 & rproxy==0) | (iqmean_gtp75==0 & rproxy==1)
la var cog_comb2 "TICS score<25% or IQMEAN>75%"

gen cog_comb3=1 if tics_ltp50==1 | iqmean_gtp50==1
replace cog_comb3=0 if (tics_ltp50==0 & rproxy==0) | (iqmean_gtp50==0 & rproxy==1)
la var cog_comb3 "TICS score<50% or IQMEAN>50%"

**************************************************************************
**dementia indicators - using all 3 measures
**first version, missing if missing any of the three measures
gen dem_vars_cat=0 if rsr_mem_dis_any==0 & pred_dem_cat1==0 & cog_comb==0
replace dem_vars_cat=1 if rsr_mem_dis_any==1 & pred_dem_cat1==0 & cog_comb==0
replace dem_vars_cat=2 if rsr_mem_dis_any==0 & pred_dem_cat1==1 & cog_comb==0
replace dem_vars_cat=3 if rsr_mem_dis_any==0 & pred_dem_cat1==0 & cog_comb==1
replace dem_vars_cat=4 if rsr_mem_dis_any==1 & pred_dem_cat1==1 & cog_comb==0
replace dem_vars_cat=5 if rsr_mem_dis_any==1 & pred_dem_cat1==0 & cog_comb==1
replace dem_vars_cat=6 if rsr_mem_dis_any==0 & pred_dem_cat1==1 & cog_comb==1
replace dem_vars_cat=7 if rsr_mem_dis_any==1 & pred_dem_cat1==1 & cog_comb==1

la def dem_vars_cat 0 "No dementia" 1 "SR mem disease only" ///
2 "Predicted dementia only" 3 "Cog score only" ///
4 "SR mem disease + pred dementia" 5 "SR mem disease + Cog score" ///
6 "Pred dem + Cog score" 7 "SR mem disease+Pred dem+Cog score" ///

la val dem_vars_cat dem_vars_cat
la var dem_vars_cat "Dementia classification, variables comparison, version 1"

tab dem_vars_cat, missing

**second version, assigning to dementia ignoring missing
gen dem_vars_cat2=dem_vars_cat
replace dem_vars_cat2=1 if rsr_mem_dis_any==1 & inlist(pred_dem_cat1,0,.) & inlist(cog_comb,0,.)
replace dem_vars_cat2=2 if inlist(rsr_mem_dis_any,0,.) & pred_dem_cat1==1 & inlist(cog_comb,0,.)
replace dem_vars_cat2=3 if inlist(rsr_mem_dis_any,0,.) & inlist(pred_dem_cat1,0,.) & cog_comb==1
replace dem_vars_cat2=4 if rsr_mem_dis_any==1 & pred_dem_cat1==1 & inlist(cog_comb,0,.)
replace dem_vars_cat2=5 if rsr_mem_dis_any==1 & inlist(pred_dem_cat1,0,.) & cog_comb==1
replace dem_vars_cat2=6 if inlist(rsr_mem_dis_any,0,.) & pred_dem_cat1==1 & cog_comb==1
la val dem_vars_cat2 dem_vars_cat

tab dem_vars_cat2, missing

**indicator for any dementia indicator
gen dem_any_vars_ind=0 if dem_vars_cat2==0
replace dem_any_vars_ind=1 if dem_vars_cat2>0 & !missing(dem_vars_cat2)
la var dem_any_vars_ind "Dementia indicator, sr mem disease or cog score or pred dem"
tab dem_vars_cat2 dem_any_vars_ind, missing

****************************************************************
**Long term care / home care categorizations with different variables
****************************************************************
tab r_sr_ltc_cat, missing //based on medical home care question only

tab r_sr_ltc_cat home_care2_ind , missing
tab r_sr_ltc_cat home_care_other_svc_ind,missing
replace home_care_other_svc_ind=0 if rnhmliv==1 & missing(home_care_other_svc_ind)

**alternate definition, medical care or other services at home
gen r_sr_ltc_cat2 = 0 if rsr_nh_ind==0&rsr_homecare_ind==0&home_care_other_svc_ind==0
replace r_sr_ltc_cat2 = 1 if rsr_nh_ind==1&rsr_homecare_ind==0&home_care_other_svc_ind==0
replace r_sr_ltc_cat2 = 2 if rsr_nh_ind==0&(rsr_homecare_ind==1|home_care_other_svc_ind==1)
replace r_sr_ltc_cat2 = 3 if rsr_nh_ind==1&(rsr_homecare_ind==1|home_care_other_svc_ind==1)
//la def ltccat 0 "No LTC" 1 "Nursing home only" 2 "Home care only" 3 "Nursing home and home care"
la val r_sr_ltc_cat2 ltccat
la var r_sr_ltc_cat2 "R self report nh and/or home care, hc includes med and other services"
tab r_sr_ltc_cat2,missing

**finally, identify using helper file relationship/paid question also
gen rhc_any=0
replace rhc_any=1 if rsr_homecare_ind==1 | home_care_other_svc_ind==1 | help_paid_comb_ind==1 | help_prof_comb==1
la var rhc_any "R Home care, any of 4 variables"

la var help_prof_comb "Professional / organization ADL/IADL helper"

**combine helper variables into single indicator
gen help_adl_prof_or_paid=1 if help_paid_comb_ind==1 | help_prof_comb==1
replace  help_adl_prof_or_paid=0 if help_paid_comb_ind==0 & help_prof_comb==0
tab help_adl_prof_or_paid
la var help_adl_prof_or_paid "ADL/IADL professional or paid helper"

**3rd categorical variable using any of the 4 home care definitions
gen r_sr_ltc_cat3=0 if rsr_nh_ind==0 & rhc_any==0
replace r_sr_ltc_cat3=1 if rsr_nh_ind==1 & rhc_any==0
replace r_sr_ltc_cat3=2 if rsr_nh_ind==0 & rhc_any==1
replace r_sr_ltc_cat3=3 if rsr_nh_ind==1 & rhc_any==1
la val r_sr_ltc_cat3 ltccat
la var r_sr_ltc_cat3 "R self report nh and/or home care, hc includes med + other services + helper"
tab r_sr_ltc_cat3,missing

****************************************************************
**Demographics, SES variables
****************************************************************
**indicators for race-ethnicity categories
tab r_race_eth_cat, gen(race_ind)
la var race_ind1 "White"
la var race_ind2 "Black"
la var race_ind3 "Hispanic"
la var race_ind4 "Other"

**indicator for non-medicaid
tab rmedicaid_sr, gen(mdcaid)
la var mdcaid1 "R No Medicaid, self report"

**indicator for income < 25% of sample income (sample is 70+/1998+)
**first income and assets for inflation so all 2012$
**use the average CPI (overall CIP) for the year
foreach v in hitot hatota{
gen `v'_ia=`v'*1.46 if year==1996
replace `v'_ia=`v'*1.41 if year==1998
replace `v'_ia=`v'*1.33 if year==2000
replace `v'_ia=`v'*1.28 if year==2002
replace `v'_ia=`v'*1.22 if year==2004
replace `v'_ia=`v'*1.14 if year==2006
replace `v'_ia=`v'*1.07 if year==2008
replace `v'_ia=`v'*1.05 if year==2010
replace `v'_ia=`v' if year==2012
}

**indicator for bottom x% for income and assets
foreach v in hitot_ia hatota_ia{
foreach c in 25 75 80 90 {
	_pctile `v' if sample_criteria==1, p(`c')
	sca `v'`c'co=r(r1)
	gen `v'_ltp`c' = 1 if `v'<=`v'`c'co & !missing(`v') & sample_criteria==1
	replace `v'_ltp`c' = 0 if `v'>`v'`c'co & !missing(`v') & sample_criteria==1
	tab `v'_ltp`c', missing
	}
}

foreach c in 25 75 80 90 {
rename hitot_ia_ltp`c' incomeltp`c'
rename hatota_ia_ltp`c' assetsltp`c'
}

la var incomeltp25 "HH Income <25 percentile (annual < $16,821)" 
la var assetsltp25 "HH Assets <25 percentile ( < $46,848)"

tab incomeltp25, gen(incomeltp25)
la var incomeltp251 "Income >25 percentile"

foreach c in 75 80 90 {
la var incomeltp`c' "HH Income <`c' percentile " 
la var assetsltp`c' "HH Assets <`c' percentile "
}
****************************************************************
save hrs_sample3.dta, replace

log close
