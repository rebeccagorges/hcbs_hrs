**Rebecca Gorges
**July 2016
**Starts with RAND version P public dataset, keeps only relevant variables
**Converts dataset from wide to long format so final ds has one row per core interview
**Final dataset is saved as rand_waves3to11.dta


**rev 4/21 added s education variable

capture log close
clear all
set more off
set maxvar 15000

//log using C:\Users\Rebecca\Documents\UofC\research\hcbs\logs\setup1_log.txt, text replace
log using E:\hrs\logs\setup1_log.txt, text replace
//log using \\itsnas\udesk\users\rjgorges\Documents\hcbs_hrs\logs\setup1_log.txt, text replace

//local data C:\Users\Rebecca\Documents\UofC\research\hcbs\data
local data E:\hrs\data
//local data \\itsnas\udesk\users\rjgorges\Documents\hcbs_hrs\data
cd `data'


*********************************************************************************
**save dataset with just needed variables, get cognition variables from HRS xwave file
/*use `data'\public_raw\rndhrs_p.dta, clear

keep *hhidpn *hhid pn *cohort *cohbyr inw* *iwstat *cendiv *wtresp *wtr_nh * *shlt *hlthlm *depres *effort ///
 *sleepr *whappy *flone *fsad *going *enlife ///
 *cesd *cesdm *walkr *walkrh *walkre *dress *dressh *bath *bathh *eat *eath ///
*bed *bedh *bede *toilt *toilth *walkra *dressa *batha *eata *beda *toilta ///
*adla *adlwa *map *phone *money *meds *shop *meals *mapa *phonea *moneya ///
*medsa *shopa *mealsa *iadla *iadlza *bmi *oopmd *lbrf *retemp *unemp *jhours *jhour2 *hosp *hspnit *hsptim ///
*memry *memryq *memrye *memryf *alzhe *demen *memrys *slfmem *fslfme *pstmem *fpstme ///
*nrshom *nrsnit *nhmliv *nhmday *homcar ///
*byear *bmonth *bflag *bdate *dyear *dmonth *ddate *nyear *nmonth *ndate *iyear ///
*imonth *idate *ndatef *idatef ///
*agem_b *agey_b *agey_b *agem_e *agey_e ///
*gender ///
*racem *hispan *mstat *mpart *mcurln *child *livsib *evbrn *hhres ///
*itot *atota *educ *wthh *proxy *iwbeg ///
*iwbegf *iwend *iwendf *iwmid *iwmidf *iwendm *iwendy ///
*higov *govmr *govmd *govva *covr *covs *henum *hiothp *hiltc *tyltc  ///
*hibp *diab *cancr *lung *heart *strok *psych *arthr ///
*hibpe *diabe *cancre *lunge *hearte *stroke *psyche *arthre 

save rand_trunc.dta, replace  
*/

*****************************************************************************
**convert data to long format
*****************************************************************************

*****************************************************************************
**for variables common to all waves 
*****************************************************************************
forvalues i=3/11{
use rand_trunc.dta, clear

**keep only specific wave variables
keep hhidpn s`i'hhidpn hhid pn inw`i' *`i'iwstat *`i'cendiv *`i'wtresp ///
hacohort racohbyr s`i'cohbyr ///
 *`i'shlt *`i'hlthlm *`i'depres *`i'effort ///
*`i'sleepr *`i'whappy *`i'flone *`i'fsad *`i'going *`i'enlife ///
 *`i'cesd *`i'cesdm *`i'walkr *`i'walkrh *`i'walkre *`i'dress *`i'dressh ///
 *`i'bath *`i'bathh *`i'eat *`i'eath *`i'bed *`i'bedh *`i'bede *`i'toilt ///
 *`i'toilth *`i'walkra *`i'dressa *`i'batha *`i'eata *`i'beda *`i'toilta ///
*`i'adla *`i'adlwa *`i'map *`i'phone *`i'money *`i'meds *`i'shop *`i'meals ///
*`i'mapa *`i'phonea *`i'moneya *`i'medsa *`i'shopa *`i'mealsa *`i'iadla ///
*`i'iadlza *`i'bmi *`i'oopmd *`i'lbrf *`i'retemp *`i'unemp *`i'jhours *`i'jhour2 *`i'hosp *`i'hspnit *`i'hsptim ///
*`i'slfmem *`i'fslfme *`i'pstmem *`i'fpstme  ///
*`i'nrshom *`i'nrsnit r`i'nhmliv s`i'nhmliv *`i'nhmday *`i'homcar rabyear rabmonth ///
rabflag rabdate radyear radmonth raddate ranyear ranmonth randate raiyear ///
raimonth raidate randatef raidatef ///
s`i'byear s`i'bmonth ///
s`i'bflag s`i'bdate s`i'dyear s`i'dmonth s`i'ddate s`i'nyear s`i'nmonth s`i'ndate s`i'iyear ///
s`i'imonth s`i'idate s`i'ndatef s`i'idatef ///
 *`i'agem_b *`i'agey_b *`i'agey_b *`i'agem_e *`i'agey_e ///
ragender raracem rahispan ///
s`i'gender s`i'racem s`i'hispan ///
*`i'mstat *`i'mpart *`i'mcurln *`i'child *`i'livsib raevbrn s`i'evbrn *`i'hhres ///
h`i'itot h`i'atota raeduc s`i'educ *`i'proxy *`i'iwbeg ///
*`i'iwbegf *`i'iwend *`i'iwendf *`i'iwmid *`i'iwmidf *`i'iwendm *`i'iwendy ///
*`i'higov *`i'govmr *`i'govmd *`i'govva *`i'covr *`i'covs *`i'henum *`i'hiothp *`i'hiltc *`i'tyltc ///
*`i'hibp *`i'diab *`i'cancr *`i'lung *`i'heart *`i'strok *`i'psych *`i'arthr  ///
*`i'hibpe *`i'diabe *`i'cancre *`i'lunge *`i'hearte *`i'stroke *`i'psyche *`i'arthre  

gen year=`i'*2+1990
gen wave=`i'

*only keep persons who had an interview in the specific wave
drop if inw`i'==0 
drop inw`i'

**rename variables that are both r/s variables
local rsvars iwstat cendiv wtresp shlt hlthlm depres effort sleepr whappy flone fsad going enlife ///
 cesd cesdm walkr walkrh walkre dress dressh bath bathh eat eath ///
 bed bedh bede toilt toilth walkra dressa batha eata beda toilta ///
adla adlwa map phone money meds shop meals mapa phonea moneya ///
medsa shopa mealsa iadla iadlza bmi oopmd lbrf retemp unemp jhours jhour2 hosp hspnit hsptim ///
slfmem fslfme pstmem fpstme  ///
nrshom nrsnit nhmliv nhmday homcar agem_b agey_b agem_e agey_e ///
mstat mpart mcurln  livsib   proxy iwbeg ///
iwbegf iwend iwendf iwmid iwmidf iwendm iwendy ///
higov govmr govmd govva covr covs henum hiothp hiltc tyltc ///
hibp diab cancr lung heart strok psych arthr  ///
hibpe diabe cancre lunge hearte stroke psyche arthre 

**wave 12 notes: missing slfmem

foreach v in r s {
	foreach name in `rsvars' {
		rename `v'`i'`name' `v'`name'
		}
	
	}
	
**rename spouse only variables
local svars hhidpn cohbyr byear bmonth bflag bdate dyear dmonth ddate nyear nmonth ndate iyear ///
imonth idate ndatef idatef gender racem hispan evbrn educ

foreach name in `svars' {
	rename s`i'`name' s`name'
	}	

**rename household variables	
local hhvars itot atota child hhres 
foreach name in `hhvars' {
	rename h`i'`name' h`name'
	}	
	
**generate income asset quintile variables
local moneyvars itot atota
foreach name in `moneyvars' {
	xtile h`name'5=h`name',nq(5)
	} 
	
save rand_w`i'.dta, replace
}

**specific wave notes
**wave 3 has no extra variables

**add to wave 4
local i=4
use rand_trunc.dta, clear

keep hhidpn inw`i' *`i'memry *`i'memryq *`i'memrye 
drop if inw`i'==0 
drop inw`i'

foreach v in r s {
	foreach name in memry memryq memrye  {
		rename `v'`i'`name' `v'`name'
		}
	
	}
	
save wave4vars.dta, replace
use rand_w4.dta
merge 1:1 hhidpn using wave4vars.dta
drop _merge
save rand_w4_m.dta, replace

**add to wave 5-9
forvalues i=5/9 {
use rand_trunc.dta, clear

keep hhidpn inw`i' *`i'wtr_nh *`i'memry *`i'memryq *`i'memrye *`i'memrys *`i'memryf
drop if inw`i'==0 
drop inw`i'

foreach v in r s {
	foreach name in wtr_nh memry memryq memrye memrys memryf {
		rename `v'`i'`name' `v'`name'
		}
	
	}
	
save wave`i'vars.dta, replace
use rand_w`i'.dta
merge 1:1 hhidpn using wave`i'vars.dta
drop _merge
save rand_w`i'_m.dta, replace
}


**wave 10
local i=10 
use rand_trunc.dta, clear

keep hhidpn inw`i' *`i'wtr_nh *`i'alzhe *`i'demen
drop if inw`i'==0 
drop inw`i'

foreach v in r s {
	foreach name in wtr_nh alzhe demen {
		rename `v'`i'`name' `v'`name'
		}
	
	}
	
save wave`i'vars.dta, replace
use rand_w`i'.dta
merge 1:1 hhidpn using wave`i'vars.dta
drop _merge
save rand_w`i'_m.dta, replace


**wave 11
local i=11 
use rand_trunc.dta, clear

keep hhidpn inw`i'  *`i'alzhe *`i'demen
drop if inw`i'==0 
drop inw`i'

foreach v in r s {
	foreach name in  alzhe demen {
		rename `v'`i'`name' `v'`name'
		}
	
	}
	
save wave`i'vars.dta, replace
use rand_w`i'.dta
merge 1:1 hhidpn using wave`i'vars.dta
drop _merge
save rand_w`i'_m.dta, replace



**bring waves 3-11 into single, long dataset
use rand_w3.dta, clear
forvalues i=4/11{
append using rand_w`i'_m.dta
}
save rand_waves3to11.dta, replace

log close
