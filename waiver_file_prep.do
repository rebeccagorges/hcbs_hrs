**Rebecca Gorges
**January 2017
**Pre-Process Medicaid waiver files and merge into single waiver file

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\waiver_data_prep_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data

cd `data'

**********************************************************
**file with target population data, originally in wide format

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

**********************************************************
/*import excel using `data'/misc_other_raw/HCBS_Waivers_all.xlsx, ///
firstrow case(l) sheet("Sheet1") 
save hcbs_waivers_all_raw.dta, replace
*/
use hcbs_waivers_all_raw.dta, clear
destring year ,replace
forvalues i=1/169{
destring scode`i',replace
}
gen begdate2=date(begdate,"DMY")
format begdate2 %td

gen enddate2=date(enddate,"DMY")
format enddate2 %td

gen year2=year(enddate2)

rename title waivertitle

**merge population served data into main waiver data file
sort state wvrnum
merge m:1 state wvrnum using hcbs_waiver_targetpop_raw_full.dta

tab _merge,missing
sort state wvrnum year2

gen merge_info=1 if _merge==1
replace merge_info=2 if _merge==2
replace merge_info=3 if _merge==3
la def merge 1 "HCBS_wavers_all sheet only" 2 " State_plans_waivers only" ///
3"Merged, in both sheets"
la val merge merge_info 
la var merge_info "waivers merge status"

**need to check/clean up typos in the year data
tab year2, missing

li wvrnum year begdate2 enddate2 state waivertitle if year2==1930
replace enddate2=td(30jun2020) if wvrnum=="383" & enddate2==td(30jun1930)
replace year2=2020 if wvrnum=="383" & enddate2==td(30jun2020)

**drop if before 1992; there were some systematic errors with date coding 1988-1992
**since we aren't using that period anyway, just drop them now
li wvrnum year begdate2 enddate2 state waivertitle if year2<1992
drop if year2<1992

li wvrnum year begdate2 enddate2 begdate enddate state waivertitle if year2>2020 & !missing(year2)

**fix dates for waiver TBI in MA
li wvrnum year2 begdate2 enddate2 year begdate enddate state if waivertitle=="TBI" & state=="MA"
replace enddate2=td(01jul2016) if year==16 & waivertitle=="TBI" & state=="MA"
replace year2=2016 if year==16 & waivertitle=="TBI" & state=="MA"
replace enddate2=td(01jul2017) if year==17 & waivertitle=="TBI" & state=="MA"
replace year2=2017 if year==17 & waivertitle=="TBI" & state=="MA"
replace enddate2=td(01jul2018) if year==18 & waivertitle=="TBI" & state=="MA"
replace year2=2018 if year==18 & waivertitle=="TBI" & state=="MA"
replace enddate2=td(01jul2019) if year==19 & waivertitle=="TBI" & state=="MA"
replace year2=2019 if year==19 & waivertitle=="TBI" & state=="MA"
li wvrnum year2 begdate2 enddate2 year begdate enddate state if waivertitle=="TBI" & state=="MA"

li wvrnum year2 begdate2 enddate2 year begdate enddate state waivertitle if year2>2020 & !missing(year2)
**fix one off errors
replace enddate2=td(30jun1999) if enddate2==td(01jun3099) & waivertitle=="A/D" & state=="ME"
replace year2=1999 if enddate2==td(30jun1999) & waivertitle=="A/D" & state=="ME"

replace enddate2=td(31oct2014) if enddate2==td(01oct3114) & wvrnum=="842" & state=="ND"
replace year2=2014 if enddate2==td(31oct2014) & wvrnum=="842" & state=="ND"

replace enddate2=td(30jun2016) if enddate2==td(01jun3016 ) & wvrnum=="40194" & state=="OR"
replace year2=2016 if enddate2==td(30jun2016) & wvrnum=="40194" & state=="OR"
li wvrnum year2 begdate2 enddate2 year begdate enddate state waivertitle if year2>2020 & !missing(year2)

**missing year2 fields?

**need to address this! these waivers had no end date!
li state wvrnum waivertitle begdate enddate merge_info if year2==.

li state wvrnum waivertitle begdate enddate year pop_1 pop_12 merge_info if wvrnum=="68.90000000000001"
li state wvrnum waivertitle begdate enddate year pop_1 pop_12 merge_info if wvrnum=="68"
drop if wvrnum=="68" & merge_info==2

**These notes wrt spreadsheet missing_to_add_manually.xlsx
**If get new versions of spreadsheets need to revisit this work!!
**AL waiver 878 exists, was not in the original master list! manually add entries
**CT waiver 1085 to be manually added
**FL 10 - Its waiver 10.9 in the other spreadsheet; added addl entries for 2011-2014

replace enddate2=td(28feb2001) if year2==. & wvrnum=="40195" & state=="HI"
replace year2=2001 if year2==. & wvrnum=="40195" & state=="HI"

li state wvrnum waivertitle enddate merge_info pop_1 pop_12 if state=="ME" & (wvrnum=="275" | wvrnum=="276")

replace pop_2=1 if state=="ME" & wvrnum=="276"
replace pop_3=1 if state=="ME" & wvrnum=="276"
replace pop_6=0 if state=="ME" & wvrnum=="276"
replace pop_12=1 if state=="ME" & wvrnum=="276"

drop if state=="ME" & wvrnum=="275" & merge_info==2

drop if state=="MT" & wvrnum=="44" & merge_info==2

drop if state=="ND" & wvrnum=="273" & year==95

drop if state=="NH" & wvrnum=="53.9" & year==92

drop if state=="NJ" & wvrnum=="160" & year==92

replace enddate2=td(28feb2001) if year2==. & wvrnum=="160" & state=="NJ" & begdate2==td(01mar2000)
replace year2=2001 if year2==. & wvrnum=="160" & state=="NJ" & begdate2==td(01mar2000)
replace enddate2=td(28feb2007) if year2==. & wvrnum=="160" & state=="NJ" & begdate2==td(01mar2006)
replace year2=2007 if year2==. & wvrnum=="160" & state=="NJ" & begdate2==td(01mar2006)

drop if state=="NV" & wvrnum=="125" & merge_info==2
drop if state=="NV" & wvrnum=="152" & merge_info==2
drop if state=="NV" & wvrnum=="4150" & merge_info==2

drop if state=="NY" & wvrnum=="238" & year==92

replace enddate2=td(30jun1998) if year2==. & wvrnum=="198" & state=="OH" & year==98
replace begdate2=td(01jul1998) if year2==. & wvrnum=="198" & state=="OH" & year==98
replace year2=1998 if year2==. & wvrnum=="198" & state=="OH" & year==98

drop if state=="OH" & wvrnum=="218" & year==92 & year2==.

drop if state=="OH" & wvrnum=="4169" & merge_info==2 & year2==.

**OH OBRA - don't know what this one is!

drop if state=="OK" & wvrnum=="9" & merge_info==2 & year2==.
replace enddate2=td(30jun2018) if state=="SC" & wvrnum=="284" & year==18
replace year2=2018 if state=="SC" & wvrnum=="284" & year==18

replace enddate2=td(30jun2017) if state=="SC" & wvrnum=="284" & year==17
replace year2=2017 if state=="SC" & wvrnum=="284" & year==17

replace enddate2=td(30jun2016) if state=="SC" & wvrnum=="284" & year==16
replace year2=2016 if state=="SC" & wvrnum=="284" & year==16

replace enddate2=td(30jun2015) if state=="SC" & wvrnum=="284" & year==15
replace year2=2015 if state=="SC" & wvrnum=="284" & year==15

replace enddate2=td(30jun2014) if state=="SC" & wvrnum=="284" & year==14
replace year2=2014 if state=="SC" & wvrnum=="284" & year==14

/*
**collapse so one entry per waiver
by state wvrnum : egen begdate3=min(begdate2)
by state wvrnum : egen enddate3=max(enddate2)
format begdate3 enddate3 %td

by state wvrnum : gen n=_n
keep if n==1

drop n begdate2 enddate2 year2

**fill in year indicators based on start and end dates
replace y1990=0

replace y1992=1 if begdate3<date("19930101","YMD") & !missing(begdate3)
replace y1992=0 if begdate3>=date("19930101","YMD") & !missing(begdate3)

replace y1994=1 if begdate3<date("19950101","YMD") & ///
	enddate3>date("19940101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y1994=0 if (begdate3>=date("19950101","YMD") | ///
	enddate3<date("19940101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y1996=1 if begdate3<date("19970101","YMD") & ///
	enddate3>date("19960101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y1996=0 if (begdate3>=date("19970101","YMD") | ///
	enddate3<date("19960101","YMD")) & !missing(begdate3) & !missing(enddate3)
	
replace y1998=1 if begdate3<date("19990101","YMD") & ///
	enddate3>date("19980101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y1998=0 if (begdate3>=date("19990101","YMD") | ///
	enddate3<date("19980101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y2000=1 if begdate3<date("20010101","YMD") & ///
	enddate3>date("20000101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2000=0 if (begdate3>=date("20010101","YMD") | ///
	enddate3<date("20000101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y2002=1 if begdate3<date("20030101","YMD") & ///
	enddate3>date("20020101","YMD") & !missing(begdate3) & !missing(enddate3)		
replace y2002=0 if (begdate3>=date("20030101","YMD") | ///
	enddate3<date("20020101","YMD")) & !missing(begdate3) & !missing(enddate3)		

replace y2004=1 if begdate3<date("20050101","YMD") & ///
	enddate3>date("20040101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2004=0 if (begdate3>=date("20050101","YMD") | ///
	enddate3<date("20040101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y2006=1 if begdate3<date("20070101","YMD") & ///
	enddate3>date("20060101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2006=0 if (begdate3>=date("20070101","YMD") | ///
	enddate3<date("20060101","YMD")) & !missing(begdate3) & !missing(enddate3)
	
replace y2008=1 if begdate3<date("20090101","YMD") & ///
	enddate3>date("20080101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2008=0 if (begdate3>=date("20090101","YMD") | ///
	enddate3<date("20080101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y2010=1 if begdate3<date("20110101","YMD") & ///
	enddate3>date("20100101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2010=0 if (begdate3>=date("20110101","YMD") | ///
	enddate3<date("20100101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y2012=1 if begdate3<date("20130101","YMD") & ///
	enddate3>date("20120101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2012=0 if (begdate3>=date("20130101","YMD") | ///
	enddate3<date("20120101","YMD")) & !missing(begdate3) & !missing(enddate3)

replace y2014=1 if begdate3<date("20150101","YMD") & ///
	enddate3>date("20140101","YMD") & !missing(begdate3) & !missing(enddate3)
replace y2014=0 if (begdate3>=date("20150101","YMD") | ///
	enddate3<date("20140101","YMD")) & !missing(begdate3) & !missing(enddate3)

drop wvrnum_numeric dup _merge merge_info begdate3 enddate3 begdate enddate year
save add_to_target_pop_sheet.dta , replace

describe

use hcbs_waiver_targetpop_raw_full.dta, clear

describe

drop wvrnum_numeric
order wvrnum, after(waivertitle)

sort state wvrnum
merge 1:m state wvrnum using add_to_target_pop_sheet.dta

rename _merge xlssheet
la def xlssheet 1 "orig target pop sheet" 2 "in waivers all but not target pop"
la val xlssheet sheet
tab xlssheet, missing

sort state wvrnum
capture drop dup
quietly by  state wvrnum :  gen dup = cond(_N==1,0,_n)
tab dup, missing
drop dup

export excel using waivers_merged_rg_20170215.xlsx, firstrow(varlabels) replace

/*append using add_to_target_pop_sheet.dta, gen(sheet)
la def sheet 0 "orig target pop sheet" 1 "in waivers all but not target pop"
la val sheet sheet
tab sheet, missing





/*

keep title wvrnum state year2




rename year2 y
rename title waivertitle

egen wvrid = concat(state wvrnum)

capture drop dup
sort wvrid y
quietly by  wvrid y :  gen dup = cond(_N==1,0,_n)
tab dup, missing

keep if dup==0

replace y=1900+y if 92<=y<=99
//replace y=2000+y if 00<=y<=21
/*
bysort wvrid (waivertitle): replace waivertitle = waivertitle[1]
gen y2=y

reshape wide y2,i(wvrid) j(y)

save add_to_state_plans_waivers.dta,replace


/*

**export into excel


/*


sort state year wvrnum
quietly by state year wvrnum:  gen dup = cond(_N==1,0,_n)
tab dup, missing
li state wvrnum year title if dup==4

*deal with duplicates
*replace incorrect dates
replace year=14 if state=="NC" & wvrnum=="1037" & enddate=="31jul2014"
replace year=15 if state=="NC" & wvrnum=="1037" & enddate=="31jul2015"
replace year=16 if state=="NC" & wvrnum=="1037" & enddate=="31jul2016"
replace year=17 if state=="NC" & wvrnum=="1037" & enddate=="31jul2017"
replace year=18 if state=="NC" & wvrnum=="1037" & enddate=="31jul2018"

replace enddate="31aug2012" if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==1
replace year=13 if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==2
replace enddate="31aug2013" if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==2
replace begdate="01sep2012" if state=="NH" & wvrnum=="53" & enddate=="31aug2013" & dup==2
replace year=14 if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==3
replace enddate="31aug2014" if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==3
replace begdate="01sep2013" if state=="NH" & wvrnum=="53" & enddate=="31aug2014" & dup==3
replace year=15 if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==4
replace enddate="31aug2015" if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==4
replace begdate="01sep2014" if state=="NH" & wvrnum=="53" & enddate=="31aug2015" & dup==4
replace year=16 if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==5
replace begdate="01sep2015" if state=="NH" & wvrnum=="53" & enddate=="31aug2016" & dup==5

*fixed so merge works later
replace year=99 if state=="DC" & wvrnum=="334" & begdate=="04jan1999" & year==0
forvalues y=0/9{
replace year=`y' if state=="DC" & wvrnum=="334" & begdate=="04jan200`y'" & year==`y'+1
}
replace year=10 if state=="DC" & wvrnum=="334" & begdate=="04jan2010" & year==11
forvalues y=11/16{
replace year=`y' if state=="DC" & wvrnum=="334" & begdate=="04jan20`y'" & year==`y'+1
}

drop dup
sort state year wvrnum
quietly by state year wvrnum:  gen dup = cond(_N==1,0,_n)
tab dup, missing

replace year=1992 if year==92
replace year=1993 if year==93
replace year=1994 if year==94
replace year=1995 if year==95
replace year=1996 if year==96
replace year=1997 if year==97
replace year=1998 if year==98
replace year=1999 if year==99
replace year=2000 if year==0
replace year=2001 if year==1
replace year=2002 if year==2
replace year=2003 if year==3
replace year=2004 if year==4
replace year=2005 if year==5
replace year=2006 if year==6
replace year=2007 if year==7
replace year=2008 if year==8
replace year=2009 if year==9
replace year=2010 if year==10
replace year=2011 if year==11
replace year=2012 if year==12
replace year=2013 if year==13
replace year=2014 if year==14
replace year=2015 if year==15
replace year=2016 if year==16
replace year=2017 if year==17
replace year=2018 if year==18
replace year=2019 if year==19
replace year=2020 if year==20
replace year=2021 if year==21

tab year, missing
li state year wvrnum begdate enddate if year==.
drop if year==.

bys state year wvrnum: egen reciptotall= total( reciptot )
bys state year wvrnum: egen dollartotall= total( dollarto )

//get variables for each service code, just indicator if covered in the waiver
forvalues c = 1/30{
	gen svc_code_`c'=0
		forvalues i = 1/169{
			replace svc_code_`c'=1 if scode`i'==`c'
		}
	}
tab svc_code_2, missing

forvalues c = 1/30{
bys state year wvrnum: egen svc_code_`c'_a= max( svc_code_`c' )
}

**now one observation per each year-waiver id
bys state year wvrnum: gen n=_n
keep if n==1
drop n

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

bys state year : gen wvr_count_sy= _N
bys state year : gen n= _n

*get totals by state-year of service codes, recipients, dollars
forvalues c = 1/30{
bys state year: egen svc_code_`c'_sy= max( svc_code_`c'_a )
}

bys state year: egen reciptotall_sy= total( reciptotall )
bys state year: egen dollartotall_sy= total( dollartotall )

**check for keywords in waiver name **not completed now, not sure how to do this well
/*gen wvr_namekw_alz=strpos(title,"Alzheimer")
tab wvr_namekw_alz, missing

drop wvr_namekw_dem
gen wvr_namekw_dem=strpos(title,"dementia")
tab wvr_namekw_dem, missing
*/

drop dup
sort state year
quietly by state year :  gen dup = cond(_N==1,0,_n)
tab dup, missing

li state wvrnum year title if dup==15

keep if n==1
keep state year *_sy

gen svc_code_count_sy=0 //total number of service codes variable
forvalues c = 1/30{
replace svc_code_count_sy=svc_code_count_sy+svc_code_`c'_sy
}
tab svc_code_count_sy, missing

li if state=="AK" & year==2000

tab year, missing
tab svc_code_10, missing
tab svc_code_12, missing
tab svc_code_18, missing

gen svc_code_demsp=0
replace svc_code_demsp=1 if svc_code_10==1|svc_code_12==1|svc_code_18
tab svc_code_demsp, missing
la var svc_code_demsp "Service code 10, 12 or 18"

preserve
collapse svc_code_demsp,by(year)
twoway scatter svc_code_demsp year 
restore

/*some notes re missingness
AZ has no waivers in the spreadsheet, CMS website indicates 1st in late 2011
DC has no waivers 1998
CA, CT, HI , LA, MO, OK, OR, SD, UT no waivers in 2011
ID, MA, MS, NV, TN, WV  have no waivers in 2012
IA none 2011 and 2012
PR not in spreadsheet
RI no waivers 2010 and 2012
VT none 2006 or later
*/

**perform imputations on cases where states are missing info in 2011/2012

//need lead year variables
sort state year
by state: gen year_p1=year[_n+1]
gen yeardiff=year-year_p1
tab yeardiff, missing

gen lastobs=1 if missing(yeardiff)
replace lastobs=0 if !missing(yeardiff)

li state year yeardiff if yeardiff<-1 & !missing(yeardiff)

/*  li state year yeardiff if yeardiff<-1 & !missing(yeardiff)
      +-------------------------+
      | state   year   yeardiff |
      |-------------------------|
  17. |    AK   2010         -2 |
  94. |    CA   2010         -2 |
 150. |    CT   2010         -2 |
 171. |    DC   2010         -2 |
 198. |    DE   2012         -3 |**new waiver numbers before/after, do not impute
      |-------------------------|
 278. |    HI   2010         -2 |
 302. |    IA   2010         -3 |**same waiver no before/after, impute using prev year
 328. |    ID   2010         -3 |**same waiver no before/after, impute using prev year
 468. |    LA   2010         -2 |
 495. |    MA   2010         -4 |**same waiver no before/after, impute using prev year
      |-------------------------|
 632. |    MO   2010         -2 |
 659. |    MS   2010         -3 |**same waiver no before/after, impute using prev year
 874. |    NV   2010         -3 |**same waiver no before/after, impute using prev year
 951. |    OK   2010         -2 |
 978. |    OR   2010         -2 |
      |-------------------------|
1079. |    SD   2010         -2 |
1105. |    TN   2010         -3 |**same waiver no before/after, impute using prev year
1160. |    UT   2010         -2 |
1287. |    WV   2010         -5 |**same waiver no before/after, impute using prev year
      +-------------------------+
*/

**when just one year skipped, just carry forward the earlier years waiver information
**see above notes when >1 year skipped, case by case decisions
gen impute_fl=0
replace impute_fl=1 if yeardiff==-2
replace impute_fl=1 if yeardiff<-2 & inlist(state,"IA","ID","MA","MS","NV","TN","WV")
tab impute_fl, missing

encode state, generate(state_num)
tsset state_num year 
tsfill 

bysort state_num: carryforward state impute_fl, replace


bysort state_num: carryforward wvr_count_sy svc_code_count_sy ///
	svc_code_demsp reciptotall_sy dollartotall_sy if impute_fl==1, replace


forvalues c=1/30{
bysort state_num: carryforward svc_code_`c'_sy if impute_fl==1, replace
}

**fill in 0 if decided not to impute, just DE **2 obs
foreach v in wvr_count_sy svc_code_count_sy svc_code_demsp reciptotall_sy dollartotall_sy {
	replace `v'=0 if missing(`v') & impute_fl==0 
}
forvalues c=1/30{
	replace svc_code_`c'_sy=0 if missing(svc_code_`c'_sy) & impute_fl==0
}
**get count of waivers by state,year
/*preserve
keep if inlist(state,"CA","CO","ID","IL","MA","MD","NY","OR","PA")
keep if year>2005 & year<2010
keep year state wvr_count_sy
reshape wide wvr_count_sy, i(state) j(year)
li state wvr_count_sy*

restore*/

**percent change in the number of waivesrs from year to year
sort state year
by state: gen n2=_n
gen firstobs=1 if n2==1
by state: gen wvr_count_p1=wvr_count_sy[_n-1]
gen wvr_count_pctchange = (wvr_count_p1-wvr_count_sy) / wvr_count_sy * 100
replace wvr_count_pctchange=1 if firstobs==1 //set to 1 for first obs in the series
la var wvr_count_pctchange "% change in waiver count from prev year"
sum wvr_count_pctchange, detail

gen wvr_count_incr=1 if wvr_count_pctchange>0 & !missing(wvr_count_pctchange) & firstobs!=1
replace wvr_count_incr=0 if (wvr_count_pctchange<=0 & !missing(wvr_count_pctchange)) | firstobs==1
la var wvr_count_incr "Increase in number of waivers from prev year"

gen wvr_count_nodecr=1 if wvr_count_pctchange>=0 & !missing(wvr_count_pctchange) & firstobs!=1
replace wvr_count_nodecr=0 if (wvr_count_pctchange<0 & !missing(wvr_count_pctchange)) | firstobs==1
la var wvr_count_nodecr "Same or increase in number of waivers from prev year"

drop n2 firstobs wvr_count_p1

**save the dataset
//rename year riwendy  //update variable name to match merge dataset
la var impute_fl "State waiver information imputed from prev year"
drop yeardiff lastobs year_p1
save hcbs_waivers_tomerge.dta, replace

**2nd version to merge by interview year only
keep state year wvr_count_sy
rename year riwendy  //update variable name to match merge dataset
rename wvr_count_sy wvr_count_sy2
save hcbs_waivers_tomerge2.dta, replace


//save hcbs_waivers_all_raw.dta, replace



log close
