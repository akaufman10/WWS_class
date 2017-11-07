/* -----------------------------------------------
Last Update: 11/6
Last Author: Alex Kaufman
last Change: Added RD regressions and various other plots, added fe to xtreg


XT DOCUMENTATION CAN BE FOUND AT
https://www.stata.com/manuals13/xt.pdf#xtxtpcse

XT example:
https://www.statalist.org/forums/forum/general-stata-discussion/general/1327627-difference-in-differences-model

RD ROBUST INSTALL CODE:
net install rdrobust, from(https://sites.google.com/site/rdpackages/rdrobust/stata) replace
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

*a graph of a variable against the time variable for each panel overliad
xtline USinfluence, overlay


*maybe we want to see one particular country
xtline USinfluence if country == "Afghanistan"

*maybe we want to see one particular country
xtline USinfluence US_support if country == "Iraq"

*generate the mean of imports from the US for country and year
bysort country: egen importsUSA_mean_country = mean(COW_importsUSA)
bysort year: egen importsUSA_mean_year = mean(COW_importsUSA)

*plot the means for each country
twoway scatter COW_importsUSA country_n, msymbol(circle_hollow) || connected importsUSA_mean_country country_n, msymbol(diamond) || 

*plot the average imports across years
twoway scatter COW_importsUSA year, msymbol(circle_hollow) || connected importsUSA_mean_year year, msymbol(diamond) || 

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

/*if we use this estimation strategy we need to estimate the following variables*
gen TREATMENT = if(USinfluence = 1)
gen POST = 1 after USinfluence
gen INTERACTION = treatment*post
*/

foreach var of varlist COW* {
  di "now regressing USinfluence on `var'"
  xtreg `var'  USinfluence i.year, fe robust
  di "now the same regression controllong for GDP and population"
  xtreg `var'  USinfluence ln_total_gdp ln_total_population, fe robust
}




* we can also do a difference in difference estimation in three steps*

*step 1: create a variable denoting distance (in years) from an interventino*
gen intv_year = year if USinfluence == 1
egen intv_year_mode = mode(intv_year), by(country) minmode
gen distance_from_intv = year - intv_year_mode

*step 2: run a DID estimation looking at an intervention
rdrobust COW_exportsUSA distance_from_intv , c(1975)

*step 3: plot the graph of the interventions
rdplot COW_exportsUSA distance_from_intv if -2<= distance & distance <= 2, c(0) 

  
log close
