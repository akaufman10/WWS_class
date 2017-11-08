/*************************************
Last Modified: 11/8
Author: Alex Kaufman
Changes Made: Corrected growth variables, added tile info, other tweaks

NOTE: Users will need to change the file location of the data set being read in

If the Rdplot command is failing, run the following command
net install rdrobust, from(https://sites.google.com/site/rdpackages/rdrobust/stata) replace

For info on the Rdplot function (how to change things on the graphs)
http://fmwww.bc.edu/repec/bocode/r/rdplot.html

*************************************/

cap log close
set more off
log using CI_log, replace

use "\\files\ak29\ClusterDownloads\Commercial_imperialism_old.dta", clear

cd "\\Files\ak29\GitHub\WWS_class\

*-------------------create running variable------------------------------*


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

*----------------------Check correlations of influence ------------------------*
foreach var of varlist `influence' new_intervention `influence' {
	corr(`var' ln_total_gdp ln_total_population war economic RUS *_force)
}

*----------------------create varaibles measuring trade ------------------------*
*CLEANING TASK: figure out why some observations of intntl and US trade > 1
gen adj_int_trade = (COW_importsWORLD + COW_exportsWORLD ) / total_gdp 
gen adj_US_trade = (COW_importsUS + COW_exportsUS ) / total_gdp
*CLEANING TASK: id outliers for nommial trade aggregates
gen nom_int_trade = COW_importsWORLD + COW_exportsWORLD
gen nom_US_trade = COW_importsUS + COW_exportsUS

*worldwide aggregates
bysort year: egen sum_global_int_trade = sum(nom_int_trade)
	
*trim the variable to remove extreme values
bysort year: egen sum_global_US_trade = sum(nom_US_trade)
bysort year: egen sum_global_gdp = sum(total_gdp)

*worldwide trade adjusted by gdp
gen global_adj_int_trade = sum_global_int_trade / sum_global_gdp
gen global_adj_US_trade = sum_global_US_trade / sum_global_gdp


bysort year: egen global_nom_int_trade = total(nom_int_trade)
bysort year: egen global_nom_US_trade = total(nom_US_trade)

*-----------------------calculate growth rates---------------------------------*


foreach var of varlist adj* nom* global*{
 
	*create lagged variable
	sort country year
	by country: gen l1_`var' = `var'[_n-1]

	*calcualte growth rate
	gen `var'_rough = (`var'- l1_`var') / l1_`var'
	replace `var'_rough = . if `var'_rough > 10
	sum `var'_rough, detail
	gen `var'_growth = `var'_rough if `var'_rough <= r(p99)
	
	drop *_rough

}

*-------------Use a regression design to test the effect of US influence------*


foreach treat of varlist USinfluence new_intervention {
	foreach var of varlist adj* nom* *_growth {
		local treatment `treat'
	    *check correlation
	    di "now regressing `treat' on `var'"
	    xtreg `var'  `treat', fe robust
	    *control for other factors
	    di "now the same regression controllong for stuff"
	    xtreg `var'  `treat' ln_total_gdp ln_total_population war economic RUS *_force, fe robust
    }
}

*---------------calculate difference in growth rates--------------*
*diff in adj US growth
gen diff_adj_intl_trade = adj_int_trade_growth - global_adj_int_trade_growth

*diff in adj intl growth
gen diff_adj_US_trade = adj_US_trade_growth - global_adj_US_trade_growth

*diff in total US growth
gen diff_intl_trade = nom_int_trade_growth - global_nom_int_trade_growth

*diff in total intl growth
gen diff_US_trade = nom_US_trade_growth - global_nom_US_trade_growth


*twoway scatter US_trade_growth year

*run RDD on trend 
foreach var of varlist diff* {
	local trade_var `var'
	rdplot `trade_var' distance_from_intv if -3<= distance_from_intv & distance_from_intv <= 3, p(1) graph_options( title("Effect of USinfluence on Trade (`var')") ytitle("Difference Between National and Global Trade Growth Rate"))
	graph export "`var'_p1.png", as(png) replace
	rdplot `trade_var' distance_from_intv if -3<= distance_from_intv & distance_from_intv <= 3, p(3) graph_options( title("Effect of USinfluence on Trade (`var')") ytitle("Difference Between National and Global Trade Growth Rate"))
	graph export "`var'_p3.png", as(png) replace
	}



log close
