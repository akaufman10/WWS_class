set more off
cap ssc install extremes

/******************************************************************
This file:

* corrects and create new variables to be used in further analysis

* drops observations that do not contain values for USinfluence and COW_imports USA

------------------------------------------------------------------
The following observations are dropped in order:
	instances for which there is no value for the USinfluence dummy
	instances in which there is no value for COW_importsUSA

The following variables are cleaned and corrected:
	country
	year

The following variables are created:
	continent (categorical)
	ln_importsUSA
	ln_correct_gdp
	prop_US_trade
	democrat_president (dummy, 1 = democrat)

The following variables are dropped after useage:
	[total_population], [ln_total_population]: total population from Maddison (thousands of people)
	[per_capita_income], [ln_per_capita_income]
	[ln_total_GDP]: ln total gross domestic product
	[xrat] PWT 6.3: Exchange rate,
	[p] PWT 6.3: GDP deflator (inverse of price level)
	[kg] PWT 6.3:  Govt share of GDP (constant prices)
	[s2unUSA] USA: Annual  scores, UNGA votes, excluding abstentions
	[economic], [military], [food]: aid
	[exim_loan]: ex-im loans in millions of historical US dollars
	[US_outbound_fdi_numaff],[US_outbound_fdi_sales], [US_outbound_fdi_numemp]: BEA variables

-------------------------------------------------------------------
*******************************************************************/
cap log using "cleaning_log", replace

use "\\files\ak29\ClusterDownloads\Commercial_imperialism_old.dta", clear

*drop observations with missing values for USinfluence or COWimprotsUSA
drop if USinfluence == .
drop if COW_importsUSA == .

*check for gaps in years and consistency of ccode

gen yearDiff = year - year[_n-1] 

egen iqr_code = iqr(ccode), by(country)

count if yearDiff!=-1 & year!= 1945 // should be zero

tab iqr // should always be zero

drop yearDiff iqr

*check and fix country duplicates

duplicates examples ccode year

*br if ccode == 770

*comebine Bangladesh / Packistan and Packistan into a single country
drop if isocode == "BGD_PAK" & year > 1970
drop if isocode == "PAK" & year <1971


*check for country repeats
tab country



/* continued overlap is not a problem - countries treated seperately


NOTE: these countries will be thrown out in the regressions 

Vietnam, Dem. Rep. 816

Vietnam 815

Yemen, Arab Republic (North) ccode 678

People's Democratic Republic of Yemen (South) 680

German Democratic Republic (East) 265

German Federal Republic (West) 260


*/

//checking for US influence in these countries

sum country USinfluence US_install_and_support US_support_only year if ccode==816|ccode==815|ccode==678|ccode==680|ccode==770|ccode==771


*create a categorical variable indicating continent (used for fixed effects)


gen continent =.

replace continent=1 if cont_africa==1

replace continent=2 if cont_asia==1

replace continent=3 if cont_europe==1

replace continent=4 if cont_oceania==1

replace continent=5 if cont_north_america==1

replace continent=6 if cont_south_america==1

foreach i of num 1/6 {
	di "continent `i' below"
	duplicates examples country if continent == `i'
}

* Recreate the GDP variable (Lachie discovered that the original GDP variable was borked)

gen correct_gdp = total_population*per_capita_income 
gen ln_correct_gdp = log(correct_gdp)

gen ln_importsUS = log(COW_importsUSA)
gen ln_exportsUS = log(COW_exportsUSA)
gen ln_tradeUS = log(COW_exportsUSA+COW_importsUSA)
gen prop_US_trade =(COW_exportsUSA+COW_importsUSA)/(COW_exportsWORLD+COW_importsWORLD)


/* 
Last update: 11/6
Last author: Emily Chen
Purpose: Clean continuous variables

***Commercial Imperialism***
*/

clear all
set more off

cd "//files/eichen/ClusterDesktop/Stata"
log using "//files/eichen/ClusterDesktop/CI_project.smcl", replace

use Commercial_imperialism_old.dta, clear

encode country, gen(country_n)
xtset country_n year, yearly

***drop following unused indicator variables***
*Isocode, obs, year_in_office
drop ccode obs year_in_office

***drop following unused continous variables****
*[total_population], [ln_total_population]: total population from Maddison (thousands of people)
*[per_capita_income], [ln_per_capita_income]
*[ln_total_GDP]: ln total gross domestic product
*[xrat] PWT 6.3: Exchange rate,
*[p] PWT 6.3: GDP deflator (inverse of price level)
*[kg] PWT 6.3:  Govt share of GDP (constant prices)
*[s2unUSA] USA: Annual  scores, UNGA votes, excluding abstentions
*[economic], [military], [food]: aid
*[exim_loan]: ex-im loans in millions of historical US dollars
*[US_outbound_fdi_numaff],[US_outbound_fdi_sales], [US_outbound_fdi_numemp]: BEA variables

drop total_population ln_total_population per_capita_income ln_per_capita_income ln_total_gdp 
drop xrat p kg s2unUSA economic military food exim_loan
drop US_outbound_fdi_numaff US_outbound_fdi_sales US_outbound_fdi_numemp

***identify and drop outliers***

*logged us imports
extremes ln_importsUSA
drop if ln_importsUSA < -10

*proportion of trade with US
extremes prop_US_trade

*total GDP
extremes ln_correct_gdp

/*
*produce histograms of the clean variables

foreach var of varlist ln_importsUSA prop_US_trade ln_correct_gdp {
	hist `var', kdenstity
	graph export "`var'_hist.png", as(png) replace
}


*/


*Create a new variable that shows the part of the US president for each year
gen democrat_president = 0

foreach i in  1945 1956 1947 1948 1949 1950 1951 1952 1961 1962 1963 1964 1965 1966 1967 1968 1977 1978 1979 1980  {
	replace democrat_president = 1 if year == `i'
	}

/*complete presidential year data
1945	1
1946	1
1947	1
1948	1
1949	1
1950	1
1951	1
1952	1
1953	0
1954	0
1955	0
1956	0
1957	0
1958	0
1959	0
1960	0
1961	1
1962	1
1963	1
1964	1
1965	1
1966	1
1967	1
1968	1
1969	0
1970	0
1971	0
1972	0
1973	0
1974	0
1975	0
1976	0
1977	1
1978	1
1979	1
1980	1
1981	0
1982	0
1983	0
1984	0
1985	0
1986	0
1987	0
1988	0
1989	0
1990	0
*/
log close
