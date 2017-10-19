/* -----------------------------------------------
Last Update: 10/19
Last Author: Alex Kaufman
last Change: Added xt command examples



XT DOCUMENTATION CAN BE FOUND AT
https://www.stata.com/manuals13/xt.pdf#xtxtpcse
------------------------------------------------*/

cap log close
set more off
log using CI_log, replace


*load the data
use "Commercial_imperialism_old.dta", clear

*create a numerical variable the corresponds to country
encode(country), gen(country_n)

*tell STATA that we are using panel data of counties (by year)
xtset country_n year, yearly

*now we can use a suite of xt tools to look at the data*


*summary of variables
xtset

*frequency of variables
foreach var of varlist  * {
capture noisily xttab `var'
}

*a graph of a variable against the time variable for each panel
xtline USinfluence 

*maybe we want to see one particular country
xtline USinfluence if country == "Afghanistan"

*maybe we want to see one particular country
xtline USinfluence US_support if country == "Iraq"

*to do some analysis, we can get the correlation coefficents for all the variables
foreach var1 of varlist US* COW* ln* total* year_* {
  foreach var2 of varlist US* COW* ln* total* year_* {
    cap xtreg `var1' `var2'
	cap local Bx = _b[`var2']
	cap xtreg `var2' `var1'
	cap local By = _b[`var1']
	cap local r = (`Bx'*`By')^0.5
    cap nois di "corr `var1' and `var2': `r'"
  }
}

*we can try a little more sophistcated regression
foreach var of varlist COW* {
  di "now regressing USinfluence on `var'"
  xtreg `var'  USinfluence 
  di "now the same regression controllong for GDP and population"
  xtreg `var'  USinfluence ln_total_gdp ln_total_population
}

  
  
log close
