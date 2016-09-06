**Rebecca Gorges
**August 2016
**Based on code from Amy Kelley , Evan Bollends Lund via Github
**pre processing steps only
**saves 2 datasets
**1. proxy interview IQCODE: proxycog_allyrs2.dta
**2. adams dementia diagnoses:  dementia_dx_adams_wave1_only.dta

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\dem_prob1_log.txt, text replace
//log using E:\hrs\logs\setup1_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

***************************************************************************
**Get proxy interview questions re cognition from main core ds
***************************************************************************
**for 1998,2000 waves
capture program drop proxycog 
program define proxycog
	args year yr vars1 vars2
 	local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
	use `data'\public_raw\hrs_core\core`year'\H`yr'PC_R.dta, clear
	keep HHID PN `vars1'-`vars2'
	gen year=`year'
	rename HHID hhid
	rename PN pn
	save `data'\proxycog_`year'.dta, replace
	end

proxycog 1998 98 F1389 F1459
proxycog 2000 00 G1543 G1613

**for 2002 and later waves
capture program drop proxycog 
program define proxycog
	args year yr pre
 	local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
	use `data'\public_raw\hrs_core\core`year'\H`yr'D_R.dta, clear
	keep HHID PN `pre'D506-`pre'D554
	gen year=`year'
	rename HHID hhid
	rename PN pn
	save `data'\proxycog_`year'.dta, replace
	end

proxycog 2002 02 H
proxycog 2004 04 J
proxycog 2006 06 K
proxycog 2008 08 L
proxycog 2010 10 M
proxycog 2012 12 N

**merge into single dataset
local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
use `data'\proxycog_1998.dta, clear
foreach y in 2000 2002 2004 2006 2008 2010 2012{
append using `data'\proxycog_`y'.dta
}

save proxycog_allyrs.dta, replace


use proxycog_allyrs.dta, clear
 **recode variable names from 98,00 to match later waves naming convention
local fvars 1389 1394 1399 1404 1409 1414 1419 1424 1429 1434 ///
 1439 1444 1448 1451 1454 1457

local i=506
foreach f of local fvars {
	gen FD`i'=F`f'
	gen FD`=`i'+1'=F`=`f'+1'
	gen FD`=`i'+2'=F`=`f'+2'
	local i=`i'+3
}

local gvars 1543 1548 1553 1558 1563 1568 1573 1578 1583 1588 1593 ///
1598 1602 1605 1608 1611

local i=506
foreach g of local gvars {
	gen GD`i'=G`g'
	gen GD`=`i'+1'=G`=`g'+1'
	gen GD`=`i'+2'=G`=`g'+2'
	local i=`i'+3
}

**create crosswave IQCODE variables 
keep hhid pn *D* year
tokenize F G H J K L M N
gen cy2=(year-1996)/2
local j=1
local k=506
forvalues i=1/16 {
	gen base=.
	gen bet=.
	gen worse=.
	forvalues j=1/8 {
		replace base=``j''D`k' if cy2==`j'
		replace bet=``j''D`=`k'+1' if cy2==`j'
		replace worse=``j''D`=`k'+2' if cy2==`j'
}
	gen pc`i'=3 if base==2
	replace pc`i'=bet if inlist(bet,1,2)
	replace pc`i'=worse if inlist(worse,4,5)
	drop base bet worse
	local k=`k'+3
	local j=`j'+1
}
foreach x in miss total mean {
	egen iq`x'=row`x'(pc1-pc16)
	if "`x'"!="miss" {
	replace iq`x'=. if iqmiss>0
}
}

drop if iqmiss==16

la def pc 1 "Much improved" 2 "A bit improved" 3"Not much changed" ///
4"A bit worse" 5"Much worse"
la val pc1-pc16 pc

la var iqmiss "Count of IQCODE missing items"
la var iqtotal "IQCODE total score 16-80 range"
la var iqmean "IQCODE mean score 1-5 range"

tab pc1 year,missing
sum iqtotal, detail
sum iqmean, detail

save proxycog_allyrs2.dta, replace


***************************************************************************
** Get ADAMS data, diagnosis for comparison to imputations
***************************************************************************
/*Note: this do file constructs a panel dataset with categorical variables of 
 cognitive diagnosis based on the final primary diagnosis at each adams_wave as well
 as the interview date.
 
 The core_year variable indicates the HRS core interview wave preceding the first 
 ADAMS assessment (some were 2000, most were 2002)
 
 Code here from Evan Bollends-Lund on 9/1/16*/
use `data'\adams_raw\stata_all_waves\ADAMS1AD_R.dta, clear
gen adams_wave=1

label define adams_wave 1 "A" 2 "B" 3 "C" 4 "D"
label values adams_wave adams_wave

append using `data'\adams_raw\stata_all_waves\ADAMS1BD_R.dta
replace adams_wave=2 if adams_wave==.

append using `data'\adams_raw\stata_all_waves\ADAMS1CD_R.dta
replace adams_wave=3 if adams_wave==.

append using `data'\adams_raw\stata_all_waves\ADAMS1DD_R.dta
replace adams_wave=4 if adams_wave==.
rename *,l

tab adams_wave, missing

gen dx_adams=.

label var dx_adams "Final Diagnosis"
label define dx_adams 1 "Demented" 2 "CIND" 3 "Normal/Non-Case"
label values dx_adams dx_adams

foreach x in ad bd cd dd {
	replace dx_adams=1 if `x'fdx1<20 & !missing(`x'fdx1)
	replace dx_adams=2 if `x'fdx1>=20 & `x'fdx1<31 & !missing(`x'fdx1)
	replace dx_adams=3 if `x'fdx1==31 & !missing(`x'fdx1)
}

gen id=hhid+pn

keep id hhid pn adams_wave dx_adams*

gen dementia=(dx==1)
gen cind=(dx==2)
gen normal_cog=(dx==3)

**merge final dignosis with ADAMS tracker file
merge m:1 hhid pn using `data'\adams_raw\stata_all_waves\ADAMS1TRK_R.dta, ///
 keepusing(hhid pn amonth ayear bmonth byear cmonth cyear dmonth dyear wavesel) nogen

foreach x in month year {
gen adams_`x'=a`x' if adams_wave==1
replace adams_`x'=b`x' if adams_wave==2
replace adams_`x'=c`x' if adams_wave==3
replace adams_`x'=d`x' if adams_wave==4
drop a`x' b`x' c`x' d`x'
}

gen core_year=2000 if wavesel==1
replace core_year=2002 if wavesel==2
drop wavesel

save dementia_dx_adams.dta, replace

keep if adams_wave==1
save dementia_dx_adams_wave1_only.dta, replace

******************************************************************************
log close
