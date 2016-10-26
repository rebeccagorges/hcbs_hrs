**Rebecca Gorges
**October 2016
**Merge in geographic data from Jing's dataset
**Process Medicaid waiver file and merge in

capture log close
clear all
set more off

log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\geo_data_merge_log.txt, text replace
//log using E:\hrs\logs\geo_data_merge_log.txt, text replace

local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
//local data E:\hrs\data

cd `data'

**********************************************************
/*
**open original file from Jing
local jdpath "C:\Users\Rebecca\Documents\UofC\research\hcbs\from_jing_20161006_data"

use `jdpath'\reg_ready.dta

keep hhidpn shhidpn year wave state totpop ptotf ptotm p65m p65f p85m p85f ///
 hpicmb nhbed tot85 tot65 nhbed1k nhbed1k65 nhbed1k85 CCRC ALR ILR ttlhcbsexp homehealthppl ///
 ttlhcbsppl homehealthexp personalcareppl personalcareexp waiverppl waiverexp ///
 cmsttlhcbsexp cmsttlltcexp cmshcbswvexp cmspersonalcareexp cmshomehealthexp ///
 cms1915wvexp cms1115wvexp cms1929wvexp cms1115_1915_1932wvexp hcbsofltc ///
 skillednursingfacilities skillednursfactotalbeds skillednursfaccertifiedbeds ///
 nursingfacilities nursingfacilitiestotalbeds nursingfacilitiescertbeds ///
 homehealthagencies tot_pop_st tot_pop_us prop_totf_st prop_totf_us ///
 prop_totm_st prop_totm_us prop_nhw_st prop_nhw_us prop_nhb_st prop_nhb_us ///
 prop_har_st prop_har_us prop_otherrace_st prop_otherrace_us prop_age65upm_st /// 
 prop_age65upm_us prop_age65upf_st prop_age65upf_us prop_age85upm_st ///
 prop_age85upm_us prop_age85upf_st prop_age85upf_us prop_poverty_st ///
 prop_poverty_us hhinc_st hhinc_us employed_st employed_us unemployed_st ///
 unemployed_us skillednursingfacilities_st skillednursingfacilities_us ///
 skillednursfactotalbeds_st skillednursfactotalbeds_us ///
 skillednursfaccertifiedbeds_st skillednursfaccertifiedbeds_us ///
 nursingfacilities_st nursingfacilities_us nursingfacilitiestotalbeds_st ///
 nursingfacilitiestotalbeds_us nursingfacilitiescertbeds_st ///
 nursingfacilitiescertbeds_us homehealthagencies_st homehealthagencies_us ///
 nhbed_st nhbed_us

save geo_to_merge.dta, replace 

*/
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
preserve
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
restore 

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

**save the dataset
rename year riwendy  //update variable name to match merge dataset
la var impute_fl "State waiver information imputed from prev year"
drop yeardiff lastobs year_p1
save hcbs_waivers_tomerge.dta, replace

***********************************************k***********
**merge into dataset

use hrs_sample.dta, clear
drop _merge
sort hhidpn year

merge 1:1 hhidpn year using geo_to_merge.dta //bring in jd's dataset

drop if _merge==2 //mostly years not in my main dataset 
drop _merge

sort state riwendy

merge m:1 state riwendy using hcbs_waivers_tomerge.dta
tab _merge
 
tab state if _merge==1
tab year if _merge==1 & state=="RI"

/* notes re missing state-years
AZ had no waivers
DC first waiver in 1999
RI last waiver in 2009
VT last waiver in 2005
*/

**fill in missing values to 0
local var wvr_count_sy reciptotall_sy dollartotall_sy svc_code_count_sy svc_code_demsp
foreach v in `var'{
replace `v'=0 if _merge==1
}

forvalues c = 1/30{
replace svc_code_`c'_sy=0 if _merge==1
}

tab riwendy if _merge==2 //mostly years outside of date range (pre 1998 or after 2012)
drop if _merge==2

save hrs_sample2.dta, replace

log close
