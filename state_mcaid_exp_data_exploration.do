** LTSS expenditures data exploration
** Data from .....

local data C:\Users\Rebecca\Documents\UofC\research\data\state

use `data'\ltss_exp_all_states_1996-2014.dta, clear
scatter pop1_mc year

bys year: sum pop1_mc

gen pop1_share_mc = pop1_mc/pop1_total

bys year: sum pop1_share_mc

scatter pop1_share_mc year

tab state if pop1_share_mc>.4 &!missing(pop1_share_mc)

tab state year if pop1_share_mc>.2 &!missing(pop1_share_mc)

sum pop1_share_mc if state=="FL" &year==2010
sum pop1_share_mc if state=="FL" &year==2012
sum pop1_share_mc if state=="FL" &year==2014

gen hcbs_share_ltss = hcbs_exp/ltss_exp
sum hcbs_share_ltss
sum hcbs_share_ltss if year==2014

preserve
collapse hcbs_share_ltss, by(year)

scatter hcbs_share_ltss year
restore


preserve
collapse hcbs_share_ltss, by(year state)

scatter hcbs_share_ltss year, by(state)
restore
