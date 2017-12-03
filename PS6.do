set more off
/**************************PS6 GROWTH******************************
Author: Alex Kaufman
Date: Dec 3, 2017
About: Code for problem set 6
******************************************************************/

cd "\\Files\ak29\GitHub\WWS_class"

use "\\files\ak29\ClusterDownloads\Growth.dta", clear

/*
a) Construct a scatterplot of average annual growth rate (Growth) on the average trade share
(TradeShare). Does there appear to be a relationship between the variables?
*/

twoway (scatter growth tradeshare,mlabel(country)), title("Part A")
graph export "PartA.png", replace
/*
(b) One country, Malta, has a trade share much larger than the other countries. Find Malta
on the scatterplot. Does Malta look like an outlier?
*/

twoway (scatter growth tradeshare if country_name != "Malta",mlabel("country")) (scatter growth tradeshare if country_name == "Malta",mcolor(red) mlabel("country")) (lfit growth tradeshare), title("Part B")
graph export "PartB.png", replace

/*
(c) Using all observations, run a regression of Growth on TradeShare. What is the estimated
slope? What is the estimated intercept? Use the regression to predict the growth rate for
a country with a trade share of 0.5 and with a trade share equal to 1.0.
*/

reg growth tradeshare
outreg2 using growth_ts, tex(frag) replace
matrix list e(b) // get coefficients
di _b[_cons] + _b[tradeshare]*.5
di _b[_cons] + _b[tradeshare]*1

/*
(d) Estimate the same regression, excluding the data from Malta. Answer the same questions
in (c).
*/

reg growth tradeshare if country_name != "Malta"
outreg2 using growth_ts_control, tex(frag) replace
matrix list e(b) // get coefficients
di _b[_cons] + _b[tradeshare]*.5
di _b[_cons] + _b[tradeshare]*1

/*
 Plot the estimated regression functions from (c) and (d). Using the scatterplot in (a),
explain why the regression function that includes Malta is steeper than the regression
function that excludes Malta.
*/

twoway (scatter growth tradeshare,mlabel(country)) (lfit growth tradeshare), title("Part C")
graph export "PartC.png", replace


twoway (scatter growth tradeshare if country_name != "Malta",mlabel(country)) (lfit growth tradeshare), title("Part D") 
graph export "PartD.png", replace

