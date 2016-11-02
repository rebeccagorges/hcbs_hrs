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
	destring OPN,replace
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

**1998 adl helpers
capture program drop helpers98
program define helpers98
	args opn n type
	use help_r_1998.dta,clear
	gen OPN=`opn'
	destring OPN, replace
	sort hhidpn core_year OPN
	merge 1:1 hhidpn core_year OPN using help_hp_1998.dta

	keep if !missing(OPN) //just r's with adl helper
	tab _merge, missing
	tab OPN if _merge==1, missing //36=spouse; 100=professional - don't have helper files
	drop if _merge==2
**now have list of r's with adl helper listed + helper relationship
**helper relationships from helper file?
	gen helper_type_`type'=1 if OPN==036 & _merge==1
	replace helper_type_`type'=2 if F2639A<61 & _merge==3
	replace helper_type_`type'=3  if (OPN==100  & _merge==1) | (inlist(F2639A,71,72,73) & _merge==3)
	replace helper_type_`type'=4  if inlist(F2639A,61,62,98) & _merge==3

** paid if yes to paid question or if professional, not in helper file
	gen helper_paid_`type'=1 if F2649==1 | (OPN==100  & _merge==1)
** not paid if no to paid question or if spouse and not in helper file
	replace helper_paid_`type'=0 if F2649==5 | (OPN==36  & _merge==1)

	keep hhidpn core_year helper_type_`type' helper_paid_`type'
	save help_1998_`type'`n'.dta, replace
end

helpers98 F2502 1 adl
helpers98 F2516 2 adl 
helpers98 F2525 3 adl
helpers98 F2529 4 adl
helpers98 F2533 5 adl
helpers98 F2537 6 adl
helpers98 F2541 7 adl

*append the ds to get count of helpers, indicator for type,paid
use help_1998_adl1.dta,clear
forvalues i=2(1)7{
append using help_1998_adl`i'.dta
}

la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
la val helper_type_adl helper 
tab helper_type_adl, missing

*create adl helper type variables by respondant (not mutually exclusive categories)
capture program drop makevars
program define makevars
	args type year
	sort hhidpn
	egen help_sp_`type'=max(helper_type_`type'==1) ,by(hhidpn)
	egen help_relative_`type'=max(helper_type_`type'==2) ,by(hhidpn)
	egen help_prof_`type'=max(helper_type_`type'==3) ,by(hhidpn)
	egen help_other_`type'=max(helper_type_`type'==4) ,by(hhidpn)

	egen helper_anypaid_`type'=max(helper_paid_`type'==1), by(hhidpn)
	by hhidpn: gen helper_`type'_count=_N
	by hhidpn: gen n=_n
	keep if n==1
	drop n helper_type_`type' helper_paid_`type'
	rename core_year year
	destring hhidpn, replace
	save help_`year'_`type'_all.dta,replace
end

makevars adl 1998

***********************************************************************
**1998 iadl helpers, use helpers98 program from above, set type=iadl
helpers98 F2582 1 iadl
helpers98 F2591 2 iadl
helpers98 F2596 3 iadl
helpers98 F2602 4 iadl
helpers98 F2608 5 iadl
helpers98 F2614 6 iadl

*append the ds to get count of helpers, indicator for type,paid
use help_1998_iadl1.dta,clear
forvalues i=2(1)6{
append using help_1998_iadl`i'.dta
}

la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
la val helper_type_iadl helper 
tab helper_type_iadl, missing

*create iadl helper type variables by respondant (not mutually exclusive categories)
makevars iadl 1998

***********************************************************************
** 2000 adl helpers

/* 2000 helper relationship question
G2947A    HELPER RELATIONSHIP COMBINED SOURCE       
          Section: E            Level: Helper          CAI Reference: Q12947
          Type: Numeric         Width: 2               Decimals: 0
          ................................................................................
           1193        10. R's SPOUSE
           1622        11. CHILD  -- from HHMEM grid
              4        12. CHILD-IN-LAW -- from HHMEM grid
             15        13. UNLISTED CHILD OR CHILD-IN-LAW -- unlisted
             26        14. STEP/PARTNER CHILD  -- from HHMEM grid
              2        15. FORMER STEP-CHILD -- unlisted
            121        21. GRDKID -- from HHMEM grid
            127        22. GRANDCHILD -- unlisted
             19        31. SIBLING -- from HHMEM grid or sibling grid
              2        32. SIBLING OF SPOUSE -- from HHMEM grid or sibling grid
             13        41. PARENT OR PARENT-IN-LAW -- from HHMEM grid
             43        51. OTHER RELATIVE -- from HHMEM grid
            243        52. RELATIVE-OTHER -- unlisted
             38        61. OTHER -- from HHMEM grid
            411        62. OTHER INDIVIDUAL -- unlisted
              9        71. PROFESSIONAL -- from HHMEM grid
              3        72. EMPLOYEE OF 'INSTITUTION' -- unlisted
            263        73. ORGANIZATION -- unlisted
                       97. Other
                       98. DK (don't know); NA (not ascertained)
                       99. RF (refused)
              2     Blank. Information not available
			  */
capture program drop helpers00
program define helpers00
	args opn n type
	use help_r_2000.dta,clear
	gen OPN=`opn'
	destring OPN, replace
	sort hhidpn core_year OPN
	merge 1:1 hhidpn core_year OPN using help_hp_2000.dta

	keep if !missing(OPN) //just r's with adl helper
	tab _merge, missing
	tab OPN if _merge==1, missing //36=spouse; 100=professional - 2000 spouse in helper files
	drop if _merge==2
**now have list of r's with adl helper listed + helper relationship
**helper relationships from helper file?
	gen helper_type_`type'=1 if (OPN==036 & _merge==1) | (G2947A==10 & _merge==3)
	replace helper_type_`type'=2 if G2947A> 10 & G2947A<61 & _merge==3
	replace helper_type_`type'=3  if (OPN==100  & _merge==1) | (inlist(G2947A,71,72,73) & _merge==3)
	replace helper_type_`type'=4  if inlist(G2947A,61,62,98) & _merge==3

** paid if yes to paid question or if professional, not in helper file
	gen helper_paid_`type'=1 if G2957==1 | (OPN==100  & _merge==1)
** not paid if no to paid question or if spouse and not in helper file
	replace helper_paid_`type'=0 if G2957==5 | (OPN==36  & _merge==1)

	keep hhidpn core_year helper_type_`type' helper_paid_`type'
	save help_2000_`type'`n'.dta, replace
end

helpers00 G2800 1 adl
helpers00 G2814 2 adl 
helpers00 G2823 3 adl
helpers00 G2827 4 adl
helpers00 G2831 5 adl
helpers00 G2835 6 adl
helpers00 G2839 7 adl

*append the ds to get count of helpers, indicator for type,paid
use help_2000_adl1.dta,clear
forvalues i=2(1)7{
append using help_2000_adl`i'.dta
}

la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
la val helper_type_adl helper 
tab helper_type_adl, missing

makevars adl 2000

***********************************************************************
** 2000 iadl helpers
helpers00 G2880 1 iadl
helpers00 G2889 2 iadl 
helpers00 G2894 3 iadl
helpers00 G2900 4 iadl
helpers00 G2906 5 iadl
helpers00 G2912 6 iadl

*append the ds to get count of helpers, indicator for type,paid
use help_2000_iadl1.dta,clear
forvalues i=2(1)6{
append using help_2000_iadl`i'.dta
}

la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
la val helper_type_iadl helper 
tab helper_type_iadl, missing

makevars iadl 2000


***********************************************************************
** 2002-2012 adl helpers

/* 2002 helper relationship question
HG069    HELPER RELATIONSHIP
         Section: G     Level: Helper          Type: Numeric    Width: 2   Decimals: 0
         CAI Reference: BG_helpers.G069AHlprRel                      Ref 2000: G2947
        ..................................................................................
                        1. SELF
         1133           2. SPOUSE/PARTNER
          534           3. SON
           10           4. STEPSON
           70           5. SPOUSE/PARTNER OF DAUGHTER
         1114           6. DAUGHTER
           29           7. STEPDAUGH
          144           8. SPOUSE/PARTNER OF SON
          213           9. GRANDCHILD
            1          10. FATHER
                       11. FATHER OF SPOUSE/PARTNER
            8          12. MOTHER
                       13. MOTHER OF SPOUSE/PARTNER
                       14. R'S PARENTS
            6          15. BROTHER
            1          16. BROTHER OF SPOUSE/PARTNER
           17          17. SISTER
            2          18. SISTER OF SPOUSE/PARTNER
          254          19. OTHER RELATIVE
          435          20. OTHER INDIVIDUAL
          268          21. ORGANIZATION
          394          22. EMPLOYEE OF 'INSTITUTION'
                       23. PAID HELPER
                       24. PROFESSIONAL
                       25. PROFESSIONAL (SPECIFY)
            1          27. FORMER SPOUSE
           18          28. UNLISTED CHILD OR CHILD-IN-LAW
                       29. NOT PROXY INTERVIEW
                       30. FORMER STEP-CHILD
            2          31. FORMER CHILD-IN-LAW
            1          32. RELATIONSHIP UNKNOWN
            6          33. SP/P OF GRANDCHILD
           25       Blank. INAP (Inapplicable)

			  */
set more off
capture program drop help0212
program define help0212
	args year pre end type typevar
		forvalues i=1/`end'{
			use help_r_`year'.dta,clear
			gen OPN=`pre'`typevar'_`i'
			destring OPN, replace
			
			sort hhidpn core_year OPN
			merge 1:1 hhidpn core_year OPN using help_hp_`year'.dta
			keep if !missing(OPN) //just r's with adl helper
			tab _merge, missing
			tab OPN if _merge==1, missing //unknown helper, not a person number
			drop if _merge==2
**now have list of r's with adl helper listed + helper relationship
**helper relationships from helper file?
			gen helper_type_`type'=1 if `pre'G069==2 //spouse
			replace helper_type_`type'=2 if `pre'G069> 2 & `pre'G069<20 | ///
				`pre'G069>25 & `pre'G069<32 | `pre'G069==33 //other family
			replace helper_type_`type'=3  if inlist(`pre'G069,21,22,23,24,25) | OPN==96
			replace helper_type_`type'=4  if `pre'G069==20
** paid if yes to paid question or if professional, not in helper file
			gen helper_paid_`type'=1 if `pre'G076==1 | inlist(`pre'G069,22,23)
** not paid if no to paid question or if spouse so question not asked
			replace helper_paid_`type'=0 if `pre'G076==5 | `pre'G069==2
			keep hhidpn core_year helper_type_`type' helper_paid_`type'
			save help_`year'_`type'`i'.dta, replace
			}
end

******************************************
/*
******************************************
local year 2002
local pre H
local typevar G054
local i 1
			use help_r_`year'.dta,clear
			gen OPN=`pre'`typevar'_`i'
			destring OPN, replace
			
			sort hhidpn core_year OPN
			merge 1:1 hhidpn core_year OPN using help_hp_`year'.dta
			keep if !missing(OPN) //just r's with adl helper
			tab _merge, missing
			tab OPN if _merge==1, missing //unknown helper, not a person number
			drop if _merge==2
**now have list of r's with adl helper listed + helper relationship
**helper relationships from helper file?
			gen helper_type_`type'=1 if `pre'G069==2 //spouse
			replace helper_type_`type'=2 if `pre'G069> 2 & `pre'G069<20 | ///
				`pre'G069>25 & `pre'G069<32 | `pre'G069==33 //other family
			replace helper_type_`type'=3  if inlist(`pre'G069,21,22,23,24,25) | OPN==96
			replace helper_type_`type'=4  if `pre'G069==20
** paid if yes to paid question or if professional, not in helper file
			gen helper_paid_`type'=1 if `pre'G076==1 | inlist(`pre'G069,22,23)
** not paid if no to paid question or if spouse so question not asked
			replace helper_paid_`type'=0 if `pre'G076==5 | `pre'G069==2
			keep hhidpn core_year helper_type_`type' helper_paid_`type'

*/


******************************************

******************************************

help0212 2002 H 7 adl G032
help0212 2002 H 6 iadl G054

help0212 2004 J 7 adl G032
help0212 2004 J 6 iadl G054

help0212 2006 K 7 adl G032
help0212 2006 K 6 iadl G054

help0212 2008 L 7 adl G032
help0212 2008 L 6 iadl G054

help0212 2010 M 7 adl G032
help0212 2010 M 6 iadl G054

help0212 2012 N 7 adl G032
help0212 2012 N 6 iadl G054


*append the ds to get count of helpers, indicator for type,paid
**adl variables
forvalues y=2002(2)2012{
	use help_`y'_adl1.dta,clear
	forvalues i=2(1)7{
		append using help_`y'_adl`i'.dta
		la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
		la val helper_type_adl helper 
		tab helper_type_adl, missing
		}			
	makevars adl `y'
	}

**iadl variables
forvalues y=2002(2)2012{
	use help_`y'_iadl1.dta,clear
	forvalues i=2(1)6{
		append using help_`y'_iadl`i'.dta
		la def helper 1"spouse" 2"family, not spouse" 3"professional" 4"other",replace
		la val helper_type_iadl helper 
		tab helper_type_iadl, missing
		}			
	makevars iadl `y'
	}

**now have 2 ds per year, one for adl, one for iadl, need to combine
***********************************************************************
**create additional variables, merge datasets

forvalues y = 1998(2)2012{
	use help_`y'_adl_all.dta,clear
	sort hhidpn year
	merge 1:1 hhidpn year using help_`y'_iadl_all.dta

**indicators for any adl / iadl helpers
	foreach t in adl iadl{
		gen help_`t'_any=1 if !missing(helper_`t'_count)
		replace help_`t'_any=0 if missing(helper_`t'_count)
		replace helper_anypaid_`t'=0 if missing(helper_`t'_count)	
		replace helper_`t'_count=0 if missing(helper_`t'_count)
		tab helper_`t'_count help_`t'_any,missing

		foreach v in sp relative prof other{
			replace help_`v'_`t'=0 if help_`t'_any==0 & missing(help_`v'_`t')
			}

		}
	gen help_comb_ind = 1 
	la var help_comb_ind "Helper reported for adl,iadl or both, 1=yes"
	
	gen help_paid_comb_ind = 0
	replace help_paid_comb_ind = 1 if helper_anypaid_adl==1 | helper_anypaid_iadl==1
	la var help_paid_comb_ind "Paid helper reported (either adl or iadl) 1=yes"

	foreach v in sp relative prof other{
		gen help_`v'_comb = 0
		replace help_`v'_comb = 1 if help_`v'_adl==1 | help_`v'_iadl==1
		}
	la var help_sp_comb "Spouse helper adl or iadl"
	la var help_relative_comb "Relative (not spouse) helper adl or iadl"
	la var help_sp_comb "Professional helper adl or iadl"
	la var help_sp_comb "Other helper adl or iadl"
	
	save help_`y'_adl_all2.dta,replace
	}
					
**merge datasets
use help_1998_adl_all2.dta,clear
forvalues y = 2000(2)2012{
	append using help_`y'_adl_all2.dta
	}
tab year,missing	
drop _merge
save help_allyrs_tomerge.dta,replace

***********************************************************************
*merge helper information into main dataset
use pdem_fullds_allwaves.dta, clear
sort hhidpn year

merge 1:1 hhidpn year using help_allyrs_tomerge.dta

**those without entry in helper ds do not have helper information, assign 0 indicators
foreach v in help_comb_ind help_paid_comb_ind {
	replace `v'=0 if _merge==1
}

foreach v in sp relative prof other{
	replace help_`v'_comb=0 if _merge==1
}

foreach t in adl iadl{
	foreach v in help_`t'_any	helper_`t'_count  helper_anypaid_`t' {
		replace `v'=0 if _merge==1
	}	
	foreach v in sp relative prof other{
		replace help_`v'_`t'=0 if _merge==1
	}
}

tab help_comb_ind year, missing
tab help_paid_comb_ind helper_anypaid_iadl if helper_anypaid_adl==0

save pdem_help_fullds_allwaves.dta,replace

**********************************************************************************
**********************************************************************************
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

use pdem_help_fullds_allwaves.dta, clear
sort hhidpn year
drop _merge
merge 1:1 hhidpn year using home_care_to_merge.dta
tab year if _merge==1
drop if _merge==2

drop _merge
merge 1:1 hhidpn year using help_1998_adl_all.dta
tab _merge
save hrs_sample.dta,replace

*************************************************************************
keep if year==1998

save hrs_sample_1998.dta,replace

**********************************************************************************
log close
