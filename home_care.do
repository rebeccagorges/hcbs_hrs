**Rebecca Gorges
**September 2016
**Compare home care information sources
**Uses helper files + interview questions re home based care

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\home_care_log.txt, text replace
//log using E:\hrs\logs\home_care_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**********************************************************************************
** Process helper datasets **
**********************************************************************************
/*use `data'\public_raw\hrs_core\core1998\H98E_HP.dta,clear

egen hhidpn=concat(HHID PN)
destring hhidpn, replace
gen year=1998
gen wave=4

/* legend for helper relationship variable, 1998
           1831        11. CHILD  -- from HHMEM grid
              6        12. CHILD-IN-LAW -- from HHMEM grid
             20        13. UNLISTED CHILD OR CHILD-IN-LAW -- unlisted
             46        14. STEP/PARTNER CHILD  -- from HHMEM grid
            132        21. GRDKID -- from HHMEM grid
            183        22. GRANDCHILD -- unlisted
             22        31. SIBLING -- from HHMEM grid or sibling grid
              1        32. SIBLING OF SPOUSE -- from HHMEM grid or sibling grid
             17        41. PARENT OR PARENT-IN-LAW -- from HHMEM grid
             58        51. OTHER RELATIVE -- from HHMEM grid
            259        52. RELATIVE-OTHER -- unlisted
             34        61. OTHER -- from HHMEM grid
            527        62. OTHER INDIVIDUAL -- unlisted
             22        71. PROFESSIONAL -- from HHMEM grid
              5        72. EMPLOYEE OF 'INSTITUTION' -- unlisted
            290        73. ORGANIZATION -- unlisted
              2        98. DK (don't know); NA (not ascertained)
                       99. RF (refused)
                    Blank. INAP (Inapplicable): [Q456:CS CONTINUE] IS (5); [Q497:CS2b] IS
                           (A) OR [Q542:CS15C2] IS (A) OR [Q518:CS11a] IS (A);
                           [Q2635:E158] IS (36); partial interview
*/
tab F2639A,missing
gen family_helper=1 if F2639A>10 & F2639A<61
replace family_helper=0 if F2639A>52 & !missing(F2639A)
replace family_helper=. if F2639A==98 | missing(F2639A)
tab family_helper,missing

**spouse is helper? note spouses in helper files in 2002 and later waves only
gen sp_helper=0
replace sp_helper=1 if OPN=FPN_SP

**helper paid?
/*
            618         1. YES
           2573         5. NO
             13         8. DK (don't know); NA (not ascertained)
              8         9. RF (refused)
            243     Blank. INAP (Inapplicable): [Q456:CS CONTINUE] IS (5); [Q497:CS2b] IS
                           (A) OR [Q542:CS15C2] IS (A) OR [Q518:CS11a] IS (A);
                           [Q2635:E158] IS (36); [Q2642:E158] IS (96); partial interview

*/
tab F2649, missing
gen helper_paid=1 if F2649==1
replace helper_paid=0 if F2649==5

tab helper_paid if family_helper==0, missing
tab helper_paid if family_helper==1, missing

**does Medicaid or other insurance pay the helper?
/*          264         1. YES
            329         5. NO
             25         8. DK (don't know); NA (not ascertained)
                        9. RF (refused)
           2837     Blank. INAP (Inapplicable): [Q456:CS CONTINUE] IS (5); [Q497:CS2b] IS
                           (A) OR [Q542:CS15C2] IS (A) OR [Q518:CS11a] IS (A);
                           [Q2635:E158] IS (36); [Q2642:E158] IS (96); [Q2649:E162] IS (5
                           OR DK OR RF); partial interview
						   */
tab F2650,missing

sort hhidpn
*/
**************************************************************
**r level files
**************************************************************
/*

**pull help data sections, all waves into single dataset
capture program drop comb
program define comb
	args year yr file
	local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
	use `data'\public_raw\hrs_core\core`year'\H`yr'`file'_R.dta,clear
	gen core_year=`year'
	egen hhidpn=concat(HHID PN)
	save `data'\help_r_`year'.dta, replace
	end

comb 1998 98 E
comb 2000 00 E
comb 2002 02 G
comb 2004 04 G
comb 2006 06 G
comb 2008 08 G
comb 2010 10 G
comb 2012 12 G

**append into single ds
use help_r_1998.dta, clear
forvalues i=2000(2)2012 {
append using help_r_`i'.dta
}
rename *,l

save help_r_allwaves.dta,replace

**for 2002 and later, need section N re home health care services
capture program drop comb
program define comb
	args year yr file v
	local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
	use `data'\public_raw\hrs_core\core`year'\H`yr'`file'_R.dta,clear
	gen core_year=`year'
	egen hhidpn=concat(HHID PN)
	keep hhidpn core_year `v'N189 `v'N202
	save `data'\sec_n_r_`year'.dta, replace
	end

comb 2002 02 N H
comb 2004 04 N J
comb 2006 06 N K
comb 2008 08 N L
comb 2010 10 N M
comb 2012 12 N N

**append into single ds
use sec_n_r_2002.dta, clear
forvalues i=2004(2)2012 {
append using sec_n_r_`i'.dta
}
rename *,l

save sec_n_r_allwaves.dta,replace

**merge to section help
use help_r_allwaves.dta,clear
sort hhidpn core_year
merge 1:1 hhidpn core_year using sec_n_r_allwaves.dta
drop _merge
save help_r_allwaves2.dta, replace


**************************************************************
**hp level files
**************************************************************
capture program drop comb
program define comb
	args year yr file
	local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
	use `data'\public_raw\hrs_core\core`year'\H`yr'`file'_HP.dta,clear
	gen core_year=`year'
	egen hhidpn=concat(HHID PN)
	save `data'\help_hp_`year'.dta, replace
	end

comb 1998 98 E
comb 2000 00 E
comb 2002 02 G
comb 2004 04 G
comb 2006 06 G
comb 2008 08 G
comb 2010 10 G
comb 2012 12 G

**append into single ds
use help_hp_1998.dta, clear
forvalues i=2000(2)2012 {
append using help_hp_`i'.dta
}
rename *,l

save help_hp_allwaves.dta,replace
*/
**************************************************************
// ADL Helpers
**************************************************************
/*ADL Helper relationship to R
Who helps - with response being the person number of the helper
1998 Core 	F2502
2000 Core 	G2800
Format of question changed in 2002 so all information can be
obtained from the single question g033_1

What is that person's relationship to you?
1998 Core 	F2508
2000 Core 	G2806
2002 Core 	HG033_1
2004 Core 	JG033_1
2006 Core 	KG033_1
2008 Core 	LG033_1
2010 Core 	MG033_1
2012 Core 	NG033_1

Core and exit:
ADL helpers:
G033_1 thru _7

Helper 2
Anyone help? Y/N
Core 1998   F2510
Core 2000   G2808
PN?
Core 1998   F2516
Core 2000   G2814
Relationship?
Core 1998   F2517
Core 2000   G2815

Helper 3
Anyone help? Y/N
Core 1998   F2524
Core 2000   G2822
PN?
Core 1998   F2525
Core 2000   G2823
Relationship?
Core 1998   F2526
Core 2000   G2824

Helper 4
Anyone help? Y/N
Core 1998   F2528
Core 2000   G2826
PN?
Core 1998   F2529
Core 2000   G2827
Relationship?
Core 1998   F2530
Core 2000   G2828

Helper 5
Anyone help? Y/N
Core 1998   F2532
Core 2000   G2830
PN?
Core 1998   F2533
Core 2000   G2831
Relationship?
Core 1998   F2534
Core 2000   G2832

Helper 6
Anyone help? Y/N
Core 1998   F2536
Core 2000   G2834
PN?
Core 1998   F2537
Core 2000   G2835
Relationship?
Core 1998   F2538
Core 2000   G2836

Helper 7
Anyone help? Y/N
Core 1998   F2540
Core 2000   G2838
PN?
Core 1998   F2541
Core 2000   G2839
Relationship?
Core 1998   F2542
Core 2000   G2840 */

//need to convert 1st level questions to numeric variables for 1998,2000
/*destring f2502 g2800, gen(f2502_n g2800_n) 
tab f2502_n if core_year==1998, missing
tab g2800_n if core_year==2000, missing
*/
***********************************************************************
**helper type variable - go through each helper from r file, match to hp file to establish relationship
capture program drop helpers98
program define helpers98
	args opn n
	use help_r_1998.dta,clear
	gen OPN=`opn'
	sort hhidpn core_year OPN
	merge 1:1 hhidpn core_year OPN using help_hp_1998.dta
	destring OPN, replace

	keep if !missing(OPN) //just r's with adl helper
	tab _merge, missing
	tab OPN if _merge==1, missing //36=spouse; 100=professional - don't have helper files
	drop if _merge==2
**now have list of r's with adl helper listed + helper relationship
**helper relationships from helper file?
	gen helper_type_adl=1 if OPN==036 & _merge==1
	replace helper_type_adl=2 if F2639A<61 & _merge==3
	replace helper_type_adl=3  if (OPN==100  & _merge==1) | (inlist(F2639A,71,72,73) & _merge==3)
	replace helper_type_adl=4  if inlist(F2639A,61,62,98) & _merge==3

** paid if yes to paid question or if professional, not in helper file
	gen helper_paid_adl=1 if F2649==1 | (OPN==100  & _merge==1)
** not paid if no to paid question or if spouse and not in helper file
	replace helper_paid_adl=0 if F2649==5 | (OPN==36  & _merge==1)

	keep hhidpn core_year helper_type_adl helper_paid_adl
	save help_1998_adl`n'.dta, replace
end

helpers98 F2502 1 
helpers98 F2516 2 
helpers98 F2525 3 
helpers98 F2529 4 
helpers98 F2533 5 
helpers98 F2537 6 
helpers98 F2541 7 

*append the ds to get count of helpers, indicator for type,paid
use help_1998_adl1.dta,clear
forvalues i=2(1)7{
append using help_1998_adl`i'.dta
}

la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
la val helper_type_adl helper 
tab helper_type_adl, missing

*create adl helper type variables by respondant (not mutually exclusive categories)
sort hhidpn
egen help_sp_adl=max(helper_type_adl==1) ,by(hhidpn)
egen help_relative_adl=max(helper_type_adl==2) ,by(hhidpn)
egen help_prof_adl=max(helper_type_adl==3) ,by(hhidpn)
egen help_other_adl=max(helper_type_adl==4) ,by(hhidpn)
//egen helper_adl_count=count(helper_type_adl), by(hhidpn)
egen helper_anypaid_adl=max(helper_paid_adl==1), by(hhidpn)
by hhidpn: gen helper_adl_count=_N
by hhidpn: gen n=_n
keep if n==1
drop n helper_type_adl helper_paid_adl
rename core_year year
destring hhidpn, replace
save help_1998_adl_all.dta,replace

/* legend for helper relationship variable, 1998
           1831        11. CHILD  -- from HHMEM grid
              6        12. CHILD-IN-LAW -- from HHMEM grid
             20        13. UNLISTED CHILD OR CHILD-IN-LAW -- unlisted
             46        14. STEP/PARTNER CHILD  -- from HHMEM grid
            132        21. GRDKID -- from HHMEM grid
            183        22. GRANDCHILD -- unlisted
             22        31. SIBLING -- from HHMEM grid or sibling grid
              1        32. SIBLING OF SPOUSE -- from HHMEM grid or sibling grid
             17        41. PARENT OR PARENT-IN-LAW -- from HHMEM grid
             58        51. OTHER RELATIVE -- from HHMEM grid
            259        52. RELATIVE-OTHER -- unlisted
             34        61. OTHER -- from HHMEM grid
            527        62. OTHER INDIVIDUAL -- unlisted
             22        71. PROFESSIONAL -- from HHMEM grid
              5        72. EMPLOYEE OF 'INSTITUTION' -- unlisted
            290        73. ORGANIZATION -- unlisted
              2        98. DK (don't know); NA (not ascertained)
                       99. RF (refused)
                    Blank. INAP (Inapplicable): [Q456:CS CONTINUE] IS (5); [Q497:CS2b] IS
                           (A) OR [Q542:CS15C2] IS (A) OR [Q518:CS11a] IS (A);
                           [Q2635:E158] IS (36); partial interview
*/

***********************************************************************
/*tab f2502 f2508 if core_year==1998, missing
tab g2800 g2806 if core_year==2000, missing

capture program drop adlsph
program define adlsph
	args y var n
	replace adl_sp_helper = 1 if (core_year==`y' & `var'==`n')
	end
	
gen byte adl_sp_helper = 0

adlsph 1998 f2502_n 36
adlsph 2000 g2800_n 36
adlsph 2002 hg033_1 2
adlsph 2004 jg033_1 2
adlsph 2006 kg033_1 2
adlsph 2008 lg033_1 2
adlsph 2010 mg033_1 2
adlsph 2012 ng033_1 2

la var adl_sp_helper "ADL Spouse Main Helper, 1=yes"
tab adl_sp_helper core_year, missing


//note for 1998, 2000 question is different.
gen byte adl_oth_helper = 0
replace adl_oth_helper = 1 if (core_year==1998 & ( 21<=f2502_n<=35 & inlist(f2508,2,4,5,6) ) ///
	 | (41<= f2502_n & f2502_n<=995 & f2502_n!=100)  )
replace adl_oth_helper = 1 if (core_year==2000 & ( 21<=g2800_n<=35 & inlist(g2806,2,4,5,6) ) ///
	 | (41<= g2800_n & g2800_n<=995 & g2800_n!=100)  )
replace adl_oth_helper = 1 if core_year==2002 & (2< hg033_1 & hg033_1<21 | hg033_1==28)
replace adl_oth_helper = 1 if core_year==2004 & ( (2< jg033_1 & jg033_1<21) | inlist(jg033_1,38,33,90,91) )
la var adl_oth_helper "ADL Other Main Helper, 1=yes"
tab adl_oth_helper core_year, missing

//max number of helpers = 7
//create common helper variables across all years
gen adl_helper_1 = f2502 if (core_year==1998)
replace adl_helper_1 = g2800 if (core_year==2000)
replace adl_helper_1 = hg032_1 if (core_year==2002)
replace adl_helper_1 = jg032_1 if (core_year==2004)
la var adl_helper_1 "ADL Helper 1 PN"

gen adl_helper_2 = f2516 if (core_year==1998)
replace adl_helper_2 = g2814 if (core_year==2000)
replace adl_helper_2 = hg032_2 if (core_year==2002)
replace adl_helper_2 = jg032_2 if (core_year==2004)
la var adl_helper_2 "ADL Helper 2 PN"

gen adl_helper_3 = f2525 if (core_year==1998)
replace adl_helper_3 = g2823 if (core_year==2000)
replace adl_helper_3 = hg032_3 if (core_year==2002)
replace adl_helper_3 = jg032_3 if (core_year==2004)
la var adl_helper_3 "ADL Helper 3 PN"

gen adl_helper_4 = f2529 if (core_year==1998)
replace adl_helper_4 = g2827 if (core_year==2000)
replace adl_helper_4 = hg032_4 if (core_year==2002)
replace adl_helper_4 = jg032_4 if (core_year==2004)
la var adl_helper_4 "ADL Helper 4 PN"

gen adl_helper_5 = f2533 if (core_year==1998)
replace adl_helper_5 = g2831 if (core_year==2000)
replace adl_helper_5 = hg032_5 if (core_year==2002)
replace adl_helper_5 = jg032_5 if (core_year==2004)
la var adl_helper_5 "ADL Helper 5 PN"

gen adl_helper_6 = f2537 if (core_year==1998)
replace adl_helper_6 = g2835 if (core_year==2000)
replace adl_helper_6 = hg032_6 if (core_year==2002)
replace adl_helper_6 = jg032_6 if (core_year==2004)
la var adl_helper_6 "ADL Helper 6 PN"

gen adl_helper_7 = f2541 if (core_year==1998)
replace adl_helper_7 = g2839 if (core_year==2000)
replace adl_helper_7 = hg032_7 if (core_year==2002)
replace adl_helper_7 = jg032_7 if (core_year==2004)
la var adl_helper_7 "ADL Helper 7 PN"

tab hg032_3,missing

**************************************************************
// IADL Helpers
**************************************************************
/*Who helps, part 1
1998 Core 	F2582
2000 Core 	G2880
IADL helper
1998 Core 	F2583
2000 Core 	G2881
2002 Core 	HG055_1
2004 Core 	JG055_1
2006 Core 	KG055_1
2008 Core 	LG055_1
2010 Core 	MG055_1
2012 Core 	NG055_1

For 2002 and later, variables are G055_2 thru G055_6
1998 and 2000 are listed out here.

Helper 2 - Does anyone else help you with these activities? 1=Yes, 5=No
1998 Core       F2585
2000 Core 	G2883
Person number?
1998 Core       F2591
2000 Core 	G2889
Relationship?
1998 Core       F2592
2000 Core 	G2890

Helper 3
1998 Core       F2594
2000 Core 	G2892
PN?
1998 Core       F2596
2000 Core 	G2894
Relationship?
1998 Core       F2597
2000 Core 	G2895

Helper 4
Anyone help?
1998 Core       F2600
2000 Core 	G2898
PN?
1998 Core       F2602
2000 Core       G2900
Relationship?
1998 Core       F2603
2000 Core       G2901

Helper 5
Anyone help?
1998 Core       F2606
2000 Core       G2904
PN?
1998 Core       F2608
2000 Core       G2906
Relationship?
1998 Core       F2609
2000 Core       G2907

Helper 6
Anyone help?
1998 Core       F2613
2000 Core       G2911
PN?
1998 Core       F2614
2000 Core       G2912
Relationship?
1998 Core       F2615
2000 Core       G2913       */

//need to convert 1st level questions to numeric variables for 1998,2000
destring f2582 g2880, gen(f2582_n g2880_n) 
tab f2582_n if core_year==1998, missing
tab g2880_n if core_year==2000, missing

gen byte iadl_sp_helper = 0
replace iadl_sp_helper = 1 if (core_year==1998 & f2582_n==36)
replace iadl_sp_helper = 1 if (core_year==2000 & g2880_n==36)
replace iadl_sp_helper = 1 if (core_year==2002 & hg055_1==2)
replace iadl_sp_helper = 1 if (core_year==2004 & jg055_1==2)
la var iadl_sp_helper "IADL Spouse Helper, 1=yes"
tab iadl_sp_helper core_year, missing

gen byte iadl_oth_helper = 0
replace iadl_oth_helper = 1 if (core_year==1998 & ( 21<=f2582_n<=35 & inlist(f2583,2,4,5,6) ) ///
	 | (41<=f2582_n & f2582_n<=995 & f2582_n!=100)  )
replace iadl_oth_helper = 1 if (core_year==2000 & ( 21<=g2880_n<=35 & inlist(g2881,1,2,4,5,6) ) ///
	 | (41<= g2880_n & g2880_n<=995 & g2880_n!=100)  )
replace iadl_oth_helper = 1 if (core_year==2002 & 2< hg055_1 & hg055_1<21)
replace iadl_oth_helper = 1 if (core_year==2004 & 2< jg055_1 & jg055_1<21)
la var iadl_oth_helper "IADL Other Helper, 1=yes"
tab iadl_oth_helper core_year, missing

//max number of helpers = 6
//create common helper variables across all years
gen iadl_helper_1 = f2582 if (core_year==1998)
replace iadl_helper_1 = g2880 if (core_year==2000)
replace iadl_helper_1 = hg054_1 if (core_year==2002)
replace iadl_helper_1 = jg054_1 if (core_year==2004)
la var iadl_helper_1 "IADL Helper 1 PN"

gen iadl_helper_2 = f2591 if (core_year==1998)
replace iadl_helper_2 = g2889 if (core_year==2000)
replace iadl_helper_2 = hg054_2 if (core_year==2002)
replace iadl_helper_2 = jg054_2 if (core_year==2004)
la var iadl_helper_2 "IADL Helper 2 PN"

gen iadl_helper_3 = f2596 if (core_year==1998)
replace iadl_helper_3 = g2894 if (core_year==2000)
replace iadl_helper_3 = hg032_3 if (core_year==2002)
replace iadl_helper_3 = jg032_3 if (core_year==2004)
la var iadl_helper_3 "IADL Helper 3 PN"

gen iadl_helper_4 = f2602 if (core_year==1998)
replace iadl_helper_4 = g2900 if (core_year==2000)
replace iadl_helper_4 = hg054_4 if (core_year==2002)
replace iadl_helper_4 = jg054_4 if (core_year==2004)
la var iadl_helper_4 "IADL Helper 4 PN"

gen iadl_helper_5 = f2608 if (core_year==1998)
replace iadl_helper_5 = g2906 if (core_year==2000)
replace iadl_helper_5 = hg054_5 if (core_year==2002)
replace iadl_helper_5 = jg054_5 if (core_year==2004)
la var iadl_helper_5 "IADL Helper 5 PN"

gen iadl_helper_6 = f2614 if (core_year==1998)
replace iadl_helper_6 = g2912 if (core_year==2000)
replace iadl_helper_6 = hg054_6 if (core_year==2002)
replace iadl_helper_6 = jg054_6 if (core_year==2004)
la var iadl_helper_6 "IADL Helper 6 PN"
**********************************************************************************
*/
**home care questions directly from surveys
use help_r_allwaves2.dta, clear
tab g2634, missing //home health care services
tab g2638, missing //other special services

gen home_care2_ind=.
capture program drop hc1 
program define hc1
	args yr var
	replace home_care2_ind=1 if `var'==1 & core_year==`yr'
	replace home_care2_ind=0 if `var'==5 & core_year==`yr'
	end
	
hc1 1998 f2357
hc1 2000 g2634
hc1 2002 hn189
hc1 2004 jn189
hc1 2006 kn189
hc1 2008 ln189
hc1 2010 mn189
hc1 2012 nn189

la var home_care2_ind "Home care med serv used, missing if live in nh"
tab home_care2_ind core_year, missing

gen home_care_other_svc_ind=.
capture program drop hc2 
program define hc2
	args yr var
	replace home_care_other_svc_ind=1 if `var'==1 & core_year==`yr'
	replace home_care_other_svc_ind=0 if `var'==5 & core_year==`yr'
	end
	
hc2 1998 f2361
hc2 2000 g2638
hc2 2002 hn202
hc2 2004 jn202
hc2 2006 kn202
hc2 2008 ln202
hc2 2010 mn202
hc2 2012 nn202

la var home_care_other_svc_ind "Home care other serv used, missing if live in nh"
tab home_care_other_svc_ind core_year, missing

tab home_care2_ind home_care_other_svc_ind, missing

**need to bring this into main dataset!
keep hhidpn core_year home_care2_ind home_care_other_svc_ind
rename core_year year
destring hhidpn, replace
save home_care_to_merge.dta, replace

use hrs_wproxycog.dta, clear
sort hhidpn year
merge 1:1 hhidpn year using home_care_to_merge.dta
keep if _merge==3

drop _merge
merge 1:1 hhidpn year using help_1998_adl_all.dta
tab _merge
save hrs_sample.dta,replace

*************************************************************************
keep if year==1998

save hrs_sample_1998.dta,replace

**********************************************************************************
log close
