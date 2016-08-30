**Rebecca Gorges
**August 2016
**Uses hrs_waves3to11_vars.dta
**Creates tabulations for initial sample size estimates

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\sample_sizes_prelim_log.txt, text replace
//log using E:\hrs\logs\sample_sizes_prelim_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 3-11 from RAND with variables coded
use `data'\hrs_wproxycog.dta, clear

**dementia vs no using TICS, dementia probability, self report
tab prob_dem_gt50, missing
tab sr_mem_dis_any , missing
tab rcogimp_tics_ind, missing

**for waves (4-8) with probability dementia imputed, age>=70 
tab prob_dem_gt50 wave, missing
drop if inlist(wave,3,9,10,11)

tab prob_dem_gt50 age_lt_70, missing
drop if age_lt_70==1

tab prob_dem_gt50, missing
tab prob_dem_gt70, missing
tab prob_dem_gt90, missing

tab sr_mem_dis_any , missing
tab rcogimp_tics_ind, missing
tab cog_missing rproxy, missing
tab iqcode_missing rproxy, missing

sum prob_dementia if cog_missing==1, detail
sum prob_dementia if cog_missing==1 &rproxy==1, detail
sum prob_dementia if cog_missing==1 &rproxy==0, detail

//all obs with prob dementia but no cognition score in my ds are proxy interviews
//why?
//check for missing components, scores not calculated if any missing iqcode questions
gen iqcode_miss1ormore=1 if iqmiss>0 & !missing(iqmiss)
replace iqcode_miss1ormore=0 if iqmiss==0
tab iqcode_miss1ormore if rproxy==1

sum prob_dementia if cog_missing==1 &rproxy==1 & iqcode_miss1ormore==1, detail
sum prob_dementia if cog_missing==1 &rproxy==1 & iqcode_miss1ormore==0, detail

//Hurd method includes obs with missing iqcode items, how many??
tab iqmiss if !missing(prob_dementia) & cog_missing==1 &rproxy==1 & iqcode_miss1ormore==1, missing
//Can't tell how this is done. Hurd includes an indicator for missing values, could this be the case here??
//Could be either missing 

tab year if cog_missing==1 &rproxy==1

la var sr_mem_dis_any "Self report memory disease"
la var rcogimp_tics_ind "TICS score <8"

//gen indicators for different tics cutoffs based on distr in sample
sum rcogtot, detail
foreach i in 10 25 50{
	sca tics`i'=r(p`i')
}

foreach i in 10 25 50{
	gen tics_ltp`i'=1 if rcogtot<tics`i'
	replace tics_ltp`i'=0 if rcogtot>tics`i' & !missing(rcogtot)
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
sum iqmean, detail
foreach i in 90 75 50{
	sca iqmean`i'=r(p`i')
}
foreach i in 90 75 50{
	gen iqmean_gtp`i'=1 if iqmean>=iqmean`i' & !missing(iqmean)
	replace iqmean_gtp`i'=0 if iqmean<iqmean`i'  
	tab iqmean_gtp`i' iqcode_missing, missing
}

gen iqmean_gtco=1 if  iqmean>=3.38 & !missing(iqmean)
replace iqmean_gtco=0 if iqmean<3.38 

la var iqmean_gtp90 "IQCODE mean score gt 90% (=5)"
la var iqmean_gtp75 "IQCODE mean score gt 75% (>4.31)"
la var iqmean_gtp50 "IQCODE mean score gt 50% (>3.18)"
la var iqmean_gtco "IQCODE mean >3.38"
la var iqcode_missing "IQCODE mean missing"

*********************************************************************
**create table 1 Dementia status 
*********************************************************************
mat tab1_1=J(1,6,.)
tab rproxy, missing matcell(pr)

mat tab1_1[1,1]=r(N)
mat tab1_1[1,3]=pr[1,1] //n non-proxy ivws
mat tab1_1[1,5]=pr[2,1] //n proxy ivws

mat rownames tab1_1="Sample size n"
frmttable, statmat(tab1_1) store(tab1_a) sdec(0)

mat tab1_2=J(1,6,.)

foreach var in sr_mem_dis_any rcogimp_tics_ind ///
   tics_ltp10 tics_ltp25 tics_ltp50 tics_missing ///
    iqmean_gtco iqmean_gtp90 iqmean_gtp75 iqmean_gtp50 iqcode_missing ///
   prob_dem_gt50 prob_dem_gt70 prob_dem_gt90{
	tab `var', missing matcell(sr)
	mat tab1_2[1,1]=sr[2,1]
	mat tab1_2[1,2]=sr[2,1]/r(N)*100

	local c=3
	foreach i in 0 1 {
		tab `var' if rproxy==`i', missing matcell(sr)
		mat tab1_2[1,`c']=sr[2,1]
		mat tab1_2[1,`c'+1]=sr[2,1]/r(N)*100
		local c = `c'+2
		}

	mat rownames tab1_2=`var'  

	frmttable, statmat(tab1_2) store(tab1_2) varlabels sdec(0,2,0,2,0,2)
	outreg, replay(tab1_3) append(tab1_2) store(tab1_3)
  } 

 
outreg using `logpath'\sample_tables_aug2016.doc, ///
replay(tab1_a) append(tab1_3) title("Table 1 - dementia classification") ///
note("Limited to 1998-2006 waves, age 70+") ///
ctitles("Method", "Overall sample","","Self interview","","Proxy interview" \ ///
"","n","%","n","%","n","%") landscape replace


*********************************************************************
**create table 2 Care setting 
*********************************************************************

mat tab2=J(4,2,.)

tab r_sr_ltc_cat, missing matcell(t2)
local n=r(N)
local r=1
forvalues i=1/4 {
mat tab2[`r',1]=t2[`i',1]
mat tab2[`r',2]=t2[`i',1]/r(N)*100
local r = `r'+1
}
frmttable, statmat(tab2) store(tab2) sdec(0,2)

outreg using `logpath'\sample_tables_aug2016.doc, ///
replay(tab2) title("Table 2 - Long term care use, n=`n'") ///
note("Limited to 1998-2006 waves, age 70+") ///
ctitles("", "n","%") ///
rtitles("None reported"\"Nursing home only"\"Home care only" \"NH+Home care" ) ///
landscape addtable

*********************************************************************
**create table 3 Care setting x Dementia
*********************************************************************
**limit to those with some type of home care
drop if inlist(r_sr_ltc_cat,0,.)
tab r_sr_ltc_cat
local n=r(N)

**indicators for race-ethnicity categories
tab r_race_eth_cat, gen(race_ind)
la var race_ind1 "White"
la var race_ind2 "Black"
la var race_ind3 "Hispanic"
la var race_ind4 "Other"

**indicator for non-medicaid
tab rmedicaid_sr, gen(mdcaid)
la var mdcaid1 "R No Medicaid, self report"

**indicator for income < 25% of sample income
sum hitot, detail
sca inc25co=r(p25)
gen incomeltp25 = 1 if hitot<=inc25co & !missing(hitot)
replace incomeltp25 = 0 if hitot>inc25co & !missing(hitot)
tab incomeltp25, missing
la var incomeltp25 "Income <25 percentile (annual < $13200)"

tab incomeltp25, gen(incomeltp25)
la var incomeltp251 "Income >25 percentile"

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

mat tab3=J(1,7,.)

tab r_sr_ltc_cat, missing matcell(t3)
local n=r(N)
local c=2

forvalues i=1/3 {
mat tab3[1,`c']=t3[`i',1]
mat tab3[1,`c'+1]=t3[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab3="Overall sample n"
frmttable, statmat(tab3) store(tab3_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab3=J(1,7,.)
foreach var in sr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   prob_dem_gt50 prob_dem_gt70 prob_dem_gt90 rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1, missing matcell(t3)
	
	mat tab3[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab3[1,`c']=t3[`i',1]
		mat tab3[1,`c'+1]=t3[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab3=`var'

	frmttable, statmat(tab3) store(tab3) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab3_1) append(tab3) store(tab3_1)
}

outreg using `logpath'\sample_tables_aug2016.doc, ///
replay(tab3_a) append(tab3_1) title("Table 3 - LTC split by dementia, medicaid, race, n=`n'") ///
note("Limited to 1998-2006 waves, age 70+, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable


log close
