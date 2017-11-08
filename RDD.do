
cap log close
set more off
log using CI_log, replace

*create running variable
use "\\files\ak29\ClusterDownloads\Commercial_imperialism_old.dta", clear

*cleaning commands
count if year_after_onset > 0 & USinfluence == 0 & US_install_and_support  == 0 & US_support_only == 0
*create trend variable
local influence USinfluence

*creat a variable that indicates the instance of influence intervention
gen new_intervention = 0
replace new_intervention = 1 if `influence' == 1 & `influence'[_n-1] != 1 & `influence'[_n-2] != 1 & country[_n-1] == country[_n]
sort country year
bysort country: gen inc_count = sum(new_intervention)
replace inc_count = 0 if new_intervention != 1
drop new_intervention

*calcualte the distance from the first intervention (for each country)
sort country year 
by country: gen c_obs = _n
by country: gen influence_count = _n if `influence' == 1
by country: egen min_influ = min(influence_count)
gen yr_from_influ1 = c_obs - min_influ
drop c_obs min_inf

*calcualte the distance from the second intervention (for each country)
sort country year 
by country: gen c_obs = _n
by country: egen second_mode = mode(influence_count) if inc_count == 2
by country: egen min_influ = mode(second_mode)
gen yr_from_influ2 = c_obs - min_influ

*flag the end of an intervention
gen end_flag = 0
replace end_flag = 1 if `influence' == 0 & `influence'[_n-1] == 1 & `influence'[_n+1] != 1
sort country year
*create running sum of "after intervention" flag
bysort country: gen second_int = sum(end_flag)

*create the final "distance" variable
gen distance_from_intv = yr_from_influ1
replace distance_from_intv = yr_from_influ2 if second_int > 0

*create varaibles measuring trade
gen intntl_trade = (COW_importsWORLD + COW_exportsWORLD ) / total_gdp
gen US_trade = (COW_importsUS + COW_exportsUS ) / total_gdp
gen real_intntl_trade = COW_importsWORLD + COW_exportsWORLD
gen real_US_trade = COW_importsUS + COW_exportsUS

*worldwide aggregates
bysort year: egen sum_global_int_trade = sum(real_intntl_trade)
bysort year: egen sum_global_US_trade = sum(real_US_trade)
bysort year: egen sum_global_gdp = sum(total_gdp)

*worldwide trade adjusted by gdp
gen global_int_trade = sum_global_int_trade / sum_global_gdp
gen global_US_trade = sum_global_US_trade / sum_global_gdp


bysort year: egen global_rl_int_trade = total(intntl_trade)
bysort year: egen global_rl_US_trade = total(US_trade)

*--------------calculate growth rates------------

*create lagged variables
foreach var in global_int_trade global_US_trade global_rl_int_trade global_rl_US_trade intntl_trade US_trade real_intntl_trade real_US_trade {

	sort country year
	by country: gen l1_`var' = `var'[_n-1]

	*calcualte growth rate
	gen `var'_growth = (`var'- l1_`var' ) / l1_`var'

}

*calculate difference in growth rates!!!
*diff in adj US growth
gen diff_adj_intl_trade = intntl_trade_growth - global_int_trade_growth

*diff in adj intl growth
gen diff_adj_US_trade = US_trade_growth - global_US_trade_growth

*diff in total US growth
gen diff_intl_trade = real_intntl_trade_growth - global_rl_int_trade_growth

*diff in total intl growth
gen diff_us_trade = real_US_trade_growth - global_rl_US_trade_growth


twoway scatter US_trade_growth year

*run RDD on trend 
local trade_var real_US_trade_growth
rdplot `trade_var' distance_from_intv if -5<= distance_from_intv & distance_from_intv <= 5, p(1)

*run DID?


log close
