**Rebecca Gorges
**October 2016
**Uses hrs_waves3to11_vars.dta
**Creates tabulations for initial sample size estimates
**Tables saved in file: sample_tables_dementia_hcbs.doc
**Limits dataset to 1998-2012 waves

**Note: Have to manually fill in notes re. sample restrictions
**on age and spouse interview in the word document with output

capture log close
clear all
set more off

local logpath C:\Users\Rebecca\Documents\UofC\research\hcbs\logs

log using `logpath'\sample_sizes_prelim_log.txt, text replace
//log using E:\hrs\logs\sample_sizes_prelim_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**long ds with waves 4-11 from RAND with variables coded
use hrs_sample3.dta, clear

tab year, missing

*********************************************************************
**Drop observations 
*********************************************************************

**wave 3(1996) doesn't have full cog battery asked so drop from the ds
tab pred_dem_cat1 wave, missing
drop if wave==3

*********************************************************************
**Summary of panel gender-race char before dropping anyone
**drop age <65
//drop if age_lt_65==1

preserve
sort hhidpn year
by hhidpn: gen n=_n
keep if n==1
**race/eth table by gender
tab r_female_ind, missing

mat re_table=J(1,5,.)
foreach r in 2 1 3 { //order is black, white, other
tab r_female_ind if raracem==`r' & rahispan==0, matcell(g)

mat re_table[1,1]=g[2,1]
mat re_table[1,2]=g[1,1]

tab r_female_ind if raracem==`r' & rahispan==1, matcell(g)

mat re_table[1,3]=g[2,1]
mat re_table[1,4]=g[1,1]
mat re_table[1,5]= re_table[1,1] + re_table[1,2] + re_table[1,3] + re_table[1,4]

mat list re_table

frmttable , statmat(re_table) store(re_tab1) ///
ctitles( "","Non hispanic","","Hispanic","","" \ ///
 "","Female","Male","Female","Male","Total" ) ///
rtitles("`r'")  sdec(0)

outreg, replay(re_tab2) append(re_tab1) store(re_tab2)
}

**get totals row
tab r_female_ind if !missing(raracem) & rahispan==0, matcell(g)
mat re_table[1,1]=g[2,1]
mat re_table[1,2]=g[1,1]

tab r_female_ind if !missing(raracem) & rahispan==1, matcell(g)
mat re_table[1,3]=g[2,1]
mat re_table[1,4]=g[1,1]
mat re_table[1,5]= re_table[1,1] + re_table[1,2] + re_table[1,3] + re_table[1,4]

frmttable , statmat(re_table) store(re_tab1) ///
ctitles("", "Non hispanic","","Hispanic","","" \ ///
"","Female","Male","Female","Male","Total" ) ///
 sdec(0)
 
**output the table
outreg, replay(re_tab2) append(re_tab1) store(re_tab2)

outreg using `logpath'\sample_tables_dementia_hcbs.doc, replay(re_tab2) ///
title("Planned enrollment report, 2000-2012 HRS Panel") ///
rtitles("Black" \ "White" \ "Other" \ "Totals") replace

restore

*******************************************************************
**split by age, married
tab rage_lt_65, missing
tab rage_lt_65 r_married, missing

tab r_married sid_ind, missing
tab r_married s_ivw_yes, missing

**table
**first - r's less than , gt 65
tab rage_lt_65, matcell(t1)
mat age=J(8,2,.)
mat age[1,1]=t1[2,1] //n lt 65
mat age[1,2]=t1[2,1]/r(N)*100 // % lt 65
mat age[2,1]=t1[1,1] //n gt 65
mat age[2,2]=t1[1,1]/r(N)*100 // % gt 65

** have spouse
tab s_ivw_yes if rage_lt_65==0, missing matcell(t2)
mat age[3,1]=t2[2,1]
mat age[3,2]=t2[2,1]/r(N)*100
mat age[4,1]=t2[1,1]
mat age[4,2]=t2[1,1]/r(N)*100

**70 split
tab rage_lt_70, matcell(t1)
mat age[5,1]=t1[2,1] //n lt 70
mat age[5,2]=t1[2,1]/r(N)*100 // % lt 70
mat age[6,1]=t1[1,1] //n gt 70
mat age[6,2]=t1[1,1]/r(N)*100 // % gt 70

** have spouse
tab s_ivw_yes if rage_lt_70==0, missing matcell(t2)
mat age[7,1]=t2[2,1]
mat age[7,2]=t2[2,1]/r(N)*100
mat age[8,1]=t2[1,1]
mat age[8,2]=t2[1,1]/r(N)*100

frmttable , statmat(age) sdec(0,2) ///
ctitles("","N","%") ///
rtitles("R age <65" \ "R age 65+" \ "Of those 65+, R spouse interview" \ ///
"Of those 65+, R no spouse interview" \ "R age <70" \ "R age 70+" \ ///
"Of those 70+, R spouse interview" \ "Of those 70+, R no spouse interview") ///
store(age_t1)

outreg using `logpath'\sample_tables_dementia_hcbs.doc, replay(age_t1) ///
title("HRS 1998-2012 waves age / spouse interview breakdown") ///
addtable

*******************************************************************
**sample cuts

**age 65+
gen sample1=1 if rage_lt_65==0
**age 65+ and spouse interview
gen sample2=1 if rage_lt_65==0&s_ivw_yes==1


**age 70+
gen sample3=1 if rage_lt_70==0
**age 70+ and spouse interview
gen sample4=1 if rage_lt_70==0&s_ivw_yes==1

tab pred_dem_cat1 rage_lt_70, missing
tab dem_vars_cat2 dem_any_vars_ind, missing

*********************************************************************
**create table 1 Dementia status 
*********************************************************************
**sample 65+, cannot use predicted dementia variable so omit those rows
tab dem_any_vars_ind if sample1==1
tab dem_vars_cat2 dem_any_vars_ind if sample1==1
tab dem_any_vars_ind_lt70 if sample1==1

foreach i in 1 2 {
mata: mata clear

mat tab1_1=J(1,6,.)
tab rproxy if sample`i'==1, matcell(pr)

mat tab1_1[1,1]=r(N)
mat tab1_1[1,3]=pr[1,1] //n non-proxy ivws
mat tab1_1[1,5]=pr[2,1] //n proxy ivws

mat rownames tab1_1="Sample size n"
frmttable, statmat(tab1_1) store(tab1_a) sdec(0)

mat tab1_2=J(1,6,.)

foreach var in rsr_mem_dis_any rcogimp_tics_ind ///
   tics_ltp10 tics_ltp25 tics_ltp50 tics_missing ///
    iqmean_gtco iqmean_gtp90 iqmean_gtp75 iqmean_gtp50 iqcode_missing ///
    dem_any_vars_ind_lt70 {
	tab `var' if sample`i'==1, missing matcell(sr)
	mat tab1_2[1,1]=sr[2,1]
	mat tab1_2[1,2]=sr[2,1]/r(N)*100

	local c=3
	foreach j in 0 1 {
		tab `var' if rproxy==`j' & sample`i'==1, missing matcell(sr)
		mat tab1_2[1,`c']=sr[2,1]
		mat tab1_2[1,`c'+1]=sr[2,1]/r(N)*100
		local c = `c'+2
		}

	mat rownames tab1_2=`var'  

	frmttable, statmat(tab1_2) store(tab1_2) varlabels sdec(0,2,0,2,0,2)
	outreg, replay(tab1_3) append(tab1_2) store(tab1_3)
  } 

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab1_a) append(tab1_3)  ///
title("Table 1-`i': Dementia Classifications") ///
ctitles("Method", "Overall sample","","Self interview","","Proxy interview" \ ///
"","n","%","n","%","n","%") ///
note("HRS 1998-2012, Age 65+ ***Fill in spouse yes or no!! ***") /// 
landscape addtable

}
***********************************************************
**age 70+ samples, now can use predicted dementia variables also

foreach i in 3 4 {
mata: mata clear

mat tab1_1=J(1,6,.)
tab rproxy if sample`i'==1, matcell(pr)

mat tab1_1[1,1]=r(N)
mat tab1_1[1,3]=pr[1,1] //n non-proxy ivws
mat tab1_1[1,5]=pr[2,1] //n proxy ivws

mat rownames tab1_1="Sample size n"
frmttable, statmat(tab1_1) store(tab1_a) sdec(0)

mat tab1_2=J(1,6,.)

foreach var in rsr_mem_dis_any rcogimp_tics_ind ///
   tics_ltp10 tics_ltp25 tics_ltp50 tics_missing ///
    iqmean_gtco iqmean_gtp90 iqmean_gtp75 iqmean_gtp50 iqcode_missing ///
   pred_dem_cat1 pred_dem_cat2 dem_any_vars_ind {
	tab `var' if sample`i'==1, missing matcell(sr)
	mat tab1_2[1,1]=sr[2,1]
	mat tab1_2[1,2]=sr[2,1]/r(N)*100

	local c=3
	foreach j in 0 1 {
		tab `var' if rproxy==`j' & sample`i'==1, missing matcell(sr)
		mat tab1_2[1,`c']=sr[2,1]
		mat tab1_2[1,`c'+1]=sr[2,1]/r(N)*100
		local c = `c'+2
		}

	mat rownames tab1_2=`var'  

	frmttable, statmat(tab1_2) store(tab1_2) varlabels sdec(0,2,0,2,0,2)
	outreg, replay(tab1_3) append(tab1_2) store(tab1_3)
  } 

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab1_a) append(tab1_3)  ///
title("Table 1-`i': Dementia Classifications") ///
ctitles("Method", "Overall sample","","Self interview","","Proxy interview" \ ///
"","n","%","n","%","n","%") ///
note("HRS 1998-2012, Age 70+ ***Fill in spouse yes or no!! ***") /// 
landscape addtable

}
**lower rate of dementia in the spouse interview sample driven by age
bys dem_any_vars_ind: sum ragey_e if sample3==1
bys s_ivw_yes: sum ragey_e if sample3==1

**********************************
**Venn diagram, dementia measures
**********************************
venndiag rsr_mem_dis_any pred_dem_cat1 cog_comb
graph export `logpath'\dementia_vars_venn.tif, as(tif) replace

venndiag rsr_mem_dis_any pred_dem_cat1 cog_comb2
graph export `logpath'\dementia_vars_venn2.tif, as(tif) replace
tab r_sr_ltc_cat, missing
*********************************************************************
**create table 2 Care setting 
*********************************************************************
foreach j in 1 2 3 4{
mata: mata clear
mat tab2=J(4,2,.)

tab r_sr_ltc_cat if sample`j'==1, matcell(t2)
local n=r(N)
local r=1
forvalues i=1/4 {
mat tab2[`r',1]=t2[`r',1]
mat tab2[`r',2]=t2[`r',1]/r(N)*100
local r = `r'+1
}
frmttable, statmat(tab2) store(tab2) sdec(0,2)

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab2) title("Table 2-`j' - Long term care use, n=`n'") ///
note("HRS 1998-2012 waves, *****fill this in *****") ///
ctitles("", "n","%") ///
rtitles("None reported"\"Nursing home only"\"Home care only" \"NH+Home care" ) ///
landscape addtable
}

**table looking at the different ltc questions
tab r_sr_ltc_cat r_sr_ltc_cat2,missing 

**second version of the table using this broader home care definition
foreach i in 1 2 3 4{
mata: mata clear
mat tab2=J(4,2,.)

tab r_sr_ltc_cat2 if sample`i'==1, matcell(t2)
local n=r(N)
local r=1
forvalues j=1/4 {
mat tab2[`r',1]=t2[`r',1]
mat tab2[`r',2]=t2[`r',1]/r(N)*100
local r = `r'+1
}
frmttable, statmat(tab2) store(tab2) sdec(0,2)

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab2) title("Table 2A-`i' - Long term care use, n=`n'" \ ///
"Home care defined as medical or other special services") ///
note("HRS 1998-2012 waves, *****fill this in *****") ///
ctitles("", "n","%") ///
rtitles("None reported"\"Nursing home only"\"Home care only" \"NH+Home care" ) ///
landscape addtable
}
*********************************************************************
**table 2B Home care variables comparison
*********************************************************************
tab rsr_nh_ind, missing //self report nursing home use *a028/*n114
tab rsr_homecare_ind,missing //question re home care for med services *n198
tab home_care_other_svc_ind, missing //question re home care for other services *n202
tab help_paid_comb_ind, missing //question from helper file
tab help_prof_comb, missing //relationship to helper from helper file

**additional variables for combinations of hc questions
tab rhc_any, missing
tab help_prof_comb, missing

local varlist rsr_homecare_ind home_care_other_svc_ind help_paid_comb_ind help_prof_comb rhc_any

**age 65+ sample, dementia by self report or cog test (not Hurd)
foreach i in 1 2{
mata: mata clear

mat t2b=J(1,5,.)

local r = 1
foreach v in `varlist'{
tab `v' if sample`i'==1, matcell(c1)
mat t2b[`r',1]=c1[2,1] //overall n

tab rsr_nh_ind if `v'==1 & sample`i'==1, matcell(c2)
mat t2b[`r',2]=c2[2,1] //n with nh=yes
mat t2b[`r',3]=c2[2,1]/r(N)*100 //%

tab dem_any_vars_ind_lt70 if `v'==1 & sample`i'==1, matcell(c2)
mat t2b[`r',4]=c2[2,1] //n with dementia=yes
mat t2b[`r',5]=c2[2,1]/r(N)*100 //%

mat rownames t2b=`v'  

frmttable, statmat(t2b) store(tab2b_1) varlabels sdec(0,0,2,0,2)
outreg, replay(tab2b_2) append(tab2b_1) store(tab2b_2)
 }

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab2b_2) ///
title("Table 2B-`i' - Home care variables comparison" ) ///
ctitles("","overall","Nursing home n","%","Dementia n","%") ///
note("HRS 1998-2012 waves, age 65+, spouse ??*****fill this in *****" \ ///
"Dementia status from self report or cog test") ///
addtable
}

**age 70+ sample, switch dementia classification variable bc of imputation
foreach i in 3 4{
mata: mata clear

mat t2b=J(1,5,.)

local r = 1
foreach v in `varlist'{
tab `v' if sample`i'==1, matcell(c1)
mat t2b[`r',1]=c1[2,1] //overall n

tab rsr_nh_ind if `v'==1 & sample`i'==1, matcell(c2)
mat t2b[`r',2]=c2[2,1] //n with nh=yes
mat t2b[`r',3]=c2[2,1]/r(N)*100 //%

tab dem_any_vars_ind if `v'==1 & sample`i'==1, matcell(c2)
mat t2b[`r',4]=c2[2,1] //n with dementia=yes
mat t2b[`r',5]=c2[2,1]/r(N)*100 //%

mat rownames t2b=`v'  

frmttable, statmat(t2b) store(tab2b_1) varlabels sdec(0,0,2,0,2)
outreg, replay(tab2b_2) append(tab2b_1) store(tab2b_2)
 }

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab2b_2) ///
title("Table 2B-`i' - Home care variables comparison" ) ///
ctitles("","overall","Nursing home n","%","Dementia n","%") ///
note("HRS 1998-2012 waves, age 70+, spouse??*****fill this in *****" \ ///
"Dementia status from self report, cog test, or predicted dementia") ///
addtable
}

***********************
**Venn diagram
***********************
**combined two adl/iadl variables
tab help_adl_prof_or_paid, missing

venndiag rsr_homecare_ind home_care_other_svc_ind help_adl_prof_or_paid
graph export `logpath'\home_care_vars_venn.tif, as(tif) replace

*********************************************************************
**create table 3 Care setting x Dementia, note 3 versions based on hc definition
*********************************************************************
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

*************************************************************
**first table
*************************************************************
**65+ group; use dementia indicator using SR and cog score (no Hurd pred)
foreach j in 1 2{
mata: mata clear
mat tab3=J(1,7,.)

tab r_sr_ltc_cat if ltc_ind1==1 & sample`j'==1,  matcell(t3)
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
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1 & ltc_ind1==1 & sample`j'==1, matcell(t3)
	
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

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab3_a) append(tab3_1) title("Table 3A-`j': LTC split by dementia, medicaid, race, n=`n'") ///
note("HRS 1998-2012 waves, age 65+, *** Spouse?? *****, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}

**70+ group; use dementia indicator using SR and cog score and Hurd pred
foreach j in 3 4 {
mata: mata clear
mat tab3=J(1,7,.)

tab r_sr_ltc_cat if ltc_ind1==1 & sample`j'==1,  matcell(t3)
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
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2 rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1 & ltc_ind1==1 & sample`j'==1, matcell(t3)
	
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

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab3_a) append(tab3_1) title("Table 3A-`j' - LTC split by dementia, medicaid, race, n=`n'") ///
note("HRS 1998-2012 waves, age 70+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}

*************************************************************************************
**second version
outreg, clear

**65+ group
foreach j in 1 2{
mata: mata clear
mat tab3=J(1,7,.)

tab r_sr_ltc_cat2 if ltc_ind2==1 & sample`j'==1,  matcell(t3)
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
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
    rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat2 if `var'==1 & ltc_ind2==1 & sample`j'==1, matcell(t3)
	
	mat tab3[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab3[1,`c']=t3[`i',1]
		mat tab3[1,`c'+1]=t3[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab3=`var'

	frmttable, statmat(tab3) store(tab3) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab3a_1) append(tab3) store(tab3a_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab3_a) append(tab3a_1) title("Table 3B-`j' - LTC split by dementia, medicaid, race, n=`n'" \ ///
"Home care includes medical care and special services" ) ///
note("HRS 1998-2012 waves, age 65+, *** Spouse?? ****, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}

***********************************************
**70+ group
foreach j in 3 4 {
mata: mata clear
mat tab3=J(1,7,.)

tab r_sr_ltc_cat2 if ltc_ind2==1 & sample`j'==1,  matcell(t3)
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
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2 rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat2 if `var'==1 & ltc_ind2==1 & sample`j'==1, matcell(t3)
	
	mat tab3[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab3[1,`c']=t3[`i',1]
		mat tab3[1,`c'+1]=t3[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab3=`var'

	frmttable, statmat(tab3) store(tab3) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab3a_1) append(tab3) store(tab3a_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab3_a) append(tab3a_1) title("Table 3B-`j' - LTC split by dementia, medicaid, race, n=`n'" \ ///
"Home care includes medical care and special services" ) ///
note("HRS 1998-2012 waves, age 70+, *** Spouse?? ****, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}



*************************************************************************************
**3rd version, definition any of the 4 questions 
outreg, clear

**65+ group
foreach j in 1 2 {
mata: mata clear
mat tab3=J(1,7,.)

tab r_sr_ltc_cat3 if ltc_ind3==1 & sample`j'==1, matcell(t3)
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
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat3 if `var'==1 & ltc_ind3==1 & sample`j'==1, matcell(t3)
	
	mat tab3[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab3[1,`c']=t3[`i',1]
		mat tab3[1,`c'+1]=t3[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab3=`var'

	frmttable, statmat(tab3) store(tab3) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab3b_1) append(tab3) store(tab3b_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab3_a) append(tab3b_1) title("Table 3C-`j' - LTC split by dementia, medicaid, race, n=`n'" \ ///
"Home care includes medical care, special services, and professional or paid help with ADL/IADLs" ) ///
note("HRS 1998-2012 waves, age 65+, ??? spouse ??? , report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}

*************************************
**70+ group
foreach j in 3 4{
mata: mata clear
mat tab3=J(1,7,.)

tab r_sr_ltc_cat3 if ltc_ind3==1 & sample`j'==1, matcell(t3)
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
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2 rmedicaid_sr mdcaid1 incomeltp25 incomeltp251 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat3 if `var'==1 & ltc_ind3==1 & sample`j'==1, matcell(t3)
	
	mat tab3[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab3[1,`c']=t3[`i',1]
		mat tab3[1,`c'+1]=t3[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab3=`var'

	frmttable, statmat(tab3) store(tab3) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab3b_1) append(tab3) store(tab3b_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab3_a) append(tab3b_1) title("Table 3C-`j' - LTC split by dementia, medicaid, race, n=`n'" \ ///
"Home care includes medical care, special services, and professional or paid help with ADL/IADLs" ) ///
note("HRS 1998-2012 waves, age 70+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}

*********************************************************************
**Table 4, Medicaid / income cutoff only sub-samples
*********************************************************************
tab rmedicaid_sr,missing

outreg, clear

**version a - home care from medical care question only, Medicaid sample
**65+ group
foreach j in 1 2 {
mata: mata clear
mat tab4=J(1,7,.)

tab r_sr_ltc_cat if ltc_ind1==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'
local c=2

forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1 & ltc_ind1==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 4A-`j' - LTC-Medicaid sample split by dementia, race" \ ///
"Home care includes home medical care only" ) ///
note("HRS 1998-2012 waves, age 65+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
**70+ group
foreach j in 3 4  {
mata: mata clear
mat tab4=J(1,7,.)

tab r_sr_ltc_cat if ltc_ind1==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'
local c=2

forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2  ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1 & ltc_ind1==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 4A-`j' - LTC-Medicaid sample split by dementia, race" \ ///
"Home care includes home medical care only" ) ///
note("HRS 1998-2012 waves, age 70+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
*********************************************************************
**version b - home care medical or other services, Medicaid sample
**65+
foreach j in 1 2 {
mata: mata clear
mat tab4=J(1,7,.)

tab r_sr_ltc_cat2 if ltc_ind2==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat2 if `var'==1 & ltc_ind2==1 & rmedicaid_sr==1  & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 4B-`j' - LTC-Medicaid sample split by dementia, race" \ ///
"Home care includes home medical care and/or other home care services" ) ///
note("HRS 1998-2012 waves, age 65+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
****************************************
**70+
foreach j in 3 4 {
mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat2 if ltc_ind2==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2  ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat2 if `var'==1 & ltc_ind2==1 & rmedicaid_sr==1  & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 4B-`j' - LTC-Medicaid sample split by dementia, race" \ ///
"Home care includes home medical care and/or other home care services" ) ///
note("HRS 1998-2012 waves, age 70+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
*********************************************************************
**version c - home care medical or other services or helper, Medicaid sample
**65+
foreach j in 1 2{
mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat3 if ltc_ind3==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat3 if `var'==1 & ltc_ind3==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 4C-`j' - LTC-Medicaid sample split by dementia, race" \ ///
"Home care includes home medical care, other home care services, adl/iadl helpers" ) ///
note("HRS 1998-2012 waves, age 65+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
**70+
foreach j in 3 4{
mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat3 if ltc_ind3==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2  ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat3 if `var'==1 & ltc_ind3==1 & rmedicaid_sr==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 4C-`j' - LTC-Medicaid sample split by dementia, race" \ ///
"Home care includes home medical care, other home care services, adl/iadl helpers" ) ///
note("HRS 1998-2012 waves, age 70+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
********************************************************************************
**income cutoff versions
**version a - home care from medical care question only, income<25% sample

**65+
foreach j in 1 2 {
mata: mata clear
mat tab4=J(1,7,.)

tab r_sr_ltc_cat if ltc_ind1==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'
local c=2

forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1 & ltc_ind1==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 5A-`j' - LTC-Income<25% sample split by dementia, race" \ ///
"Home care includes home medical care only" ) ///
note("HRS 1998-2012 waves, age 65+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
*************************
**70+
foreach j in 3 4 {
mata: mata clear
mat tab4=J(1,7,.)

tab r_sr_ltc_cat if ltc_ind1==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'
local c=2

forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2  ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat if `var'==1 & ltc_ind1==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 5A-`j' - LTC-Income<25% sample split by dementia, race" \ ///
"Home care includes home medical care only" ) ///
note("HRS 1998-2012 waves, age 70+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
*********************************************************************
**version b - home care medical or other services, Income sample
**65+
foreach j in 1 2{
 mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat2 if ltc_ind2==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat2 if `var'==1 & ltc_ind2==1 & incomeltp25==1 & sample`j'==1,  matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 5B-`j' - LTC-Income<25% sample split by dementia, race" \ ///
"Home care includes home medical care and/or other home care services" ) ///
note("HRS 1998-2012 waves, age 65+, ?? Spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
**************************************
**70+
foreach j in 3 4{
mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat2 if ltc_ind2==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2  ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat2 if `var'==1 & ltc_ind2==1 & incomeltp25==1 & sample`j'==1,  matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 5B-`j' - LTC-Income<25% sample split by dementia, race" \ ///
"Home care includes home medical care and/or other home care services" ) ///
note("HRS 1998-2012 waves, age 70+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
*********************************************************************
**version c - home care medical or other services or helper, Income sample
**65+
foreach j in 1 2 {
mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat3 if ltc_ind3==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind_lt70 rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat3 if `var'==1 & ltc_ind3==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 5C-`j' - LTC-Income<25% sample split by dementia, race" \ ///
"Home care includes home medical care, other home care services, adl/iadl helpers" ) ///
note("HRS 1998-2012 waves, age 65+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
***************************
**70+
foreach j in 3 4 {
mata: mata clear

mat tab4=J(1,7,.)

tab r_sr_ltc_cat3 if ltc_ind3==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
local n=r(N)
mat tab4[1,1]=`n'

local c=2
forvalues i=1/3 {
mat tab4[1,`c']=t4[`i',1]
mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
local c = `c'+2
}
mat rowname tab4="Overall sample n"
frmttable, statmat(tab4) store(tab4_a) sdec(0,0,2,0,2,0,2)

**split by categories
mat tab4=J(1,7,.)
foreach var in dem_any_vars_ind rsr_mem_dis_any cog_comb cog_comb1 cog_comb2 cog_comb3 ///
   pred_dem_cat1 pred_dem_cat2  ///
   race_ind1 race_ind2 race_ind3 race_ind4{
	tab r_sr_ltc_cat3 if `var'==1 & ltc_ind3==1 & incomeltp25==1 & sample`j'==1, matcell(t4)
	
	mat tab4[1,1]=r(N)
	
	local c = 2
	forvalues i=1/3 {
		mat tab4[1,`c']=t4[`i',1]
		mat tab4[1,`c'+1]=t4[`i',1]/r(N)*100
		local c = `c'+2
		}
	mat rowname tab4=`var'

	frmttable, statmat(tab4) store(tab4) sdec(0,0,2,0,2,0,2) varlabels

	outreg, replay(tab4_1) append(tab4) store(tab4_1)
}

outreg using `logpath'\sample_tables_dementia_hcbs.doc, ///
replay(tab4_a) append(tab4_1) title("Table 5C-`j' - LTC-Income<25% sample split by dementia, race" \ ///
"Home care includes home medical care, other home care services, adl/iadl helpers" ) ///
note("HRS 1998-2012 waves, age 70+, ?? spouse ??, report nursing home and/or home care use") ///
ctitles("", "N" "NH only","","Home care","","NH+Home care" \ ///
"","","n","%","n","%","n","%") ///
landscape addtable
}
*********************************************************
**Venn diagram home care variables limited to Medicaid sr
venndiag rsr_homecare_ind home_care_other_svc_ind help_adl_prof_or_paid if rmedicaid_sr==1, ///
t1title("Home care variables comparison") t2title("Medicaid sample")
graph export `logpath'\home_care_vars_venn_medicaid.tif, as(tif) replace

**Venn diagram home care variables limited to income <25%
venndiag rsr_homecare_ind home_care_other_svc_ind help_adl_prof_or_paid if incomeltp25==1, ///
t1title("Home care variables comparison") t2title("Income<25% sample")
graph export `logpath'\home_care_vars_venn_income.tif, as(tif) replace

**Venn diagram dementia variables limited to Medicaid
venndiag rsr_mem_dis_any pred_dem_cat1 cog_comb if rmedicaid_sr==1, ///
t1title("Dementia variables comparison") t2title("Medicaid sample")
graph export `logpath'\dementia_vars_venn_medicaid.tif, as(tif) replace

**Venn diagram dementia variables limited to income <25%
venndiag rsr_mem_dis_any pred_dem_cat1 cog_comb if incomeltp25==1, ///
t1title("Dementia variables comparison") t2title("Income<25% sample")
graph export `logpath'\dementia_vars_venn_income.tif, as(tif) replace

log close
