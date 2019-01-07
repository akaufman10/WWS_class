/*******************************************************************************
Author: Alex Kaufman
Date: 12/29
Description: Impact Evaluation Assignment
*******************************************************************************/
set more off
cap ssc install stddiff
cap ssc install psmatch2


local dataPATH "C:\Users\fcoca\Downloads\"
local data nswd13.dta

local codePATH "C:\Users\fcoca\OneDrive\Documentos\GitHub\WWS_class"

local vars age age2 ed black hisp married nodeg 

********************************************************************************
cd `codePATH'
cap log close
cap log using ie.log, replace


cd `dataPATH'
use `data', clear

**************************************Q1****************************************
preserve

keep if sample == 0


*standardize control variables and check balance 
foreach var of local vars {
	egen `var'_std = std(`var')
	tab treat `var'_std if sample == 0, nofreq row
	stddiff `var', by(treat)
}

*check balance of lagged dep var
foreach var of varlist re74 re75 {
	stddiff `var', by(treat)
}

*examine effect of treatment variable in sample
reg re78 treat

restore

*************************************Q2*****************************************

*create a flag for CPS only treatment control
gen treat2 = .
replace treat2 = 1 if sample == 0 & treat == 1
replace treat2 = 0 if sample == 1 & treat == 0

*check
*tab treat2 sample

*check balance in control variables 
foreach var of local vars {
	tab treat2 `var'_std, nofreq row
	stddiff `var', by(treat2)
	}

*check balance of lagged dep var
foreach var of varlist re74 re75 {
	stddiff `var', by(treat)
}

	
*examine effect of treatment variable in sample
reg re78 treat2 

*************************************Q3*****************************************

*control for observables using CPS control group
reg re78 `vars' re74 re75


************************************Q4******************************************

qui psmatch2 treat2 `vars' re74 re75
ren _pscore pscore
ren _support csupport

*check common support
tab treat2 csupport

*check common support
bysort treat2: sum pscore, det


*manually calculate pscore and check common support
logit treat2 `var' re74 re75
predict pscore_m

*check common support
bysort treat2: sum pscore_m, det

*graphical check
/*
graph twoway \\\
	(kdensity pscore if treat2 == 1) \\\
	(kdensity pscore if treat2 == 0 & pscore > .003)
*/

*manual common support
egen min_pscm_t = min(pscore_m) if treat == 1
egen min_pscm = min(min_pscm_t)
gen csupport_m = 1
replace csupport_m = 0 if pscore_m < min_pscm
tab csupport_m

drop _*

************************************Q6******************************************

*propensity score matching estimation
psmatch2 treat2 `vars' re74 re75, out(re78) ate common

*examine ATE, ATT, ATU

di "------------Average Treatment Effects------------------"
di `r(ate)'

di "------------Average Treatment On Treat-----------------"
di `r(att)'

di "------------Average Treatment On Untreated-------------"
di `r(atu)'




*repeat using teffects pscore matching 
teffects psmatch (re78) (treat2 `vars'), ate  pstolerance(1e-9)
teffects psmatch (re78) (treat2 `vars'), atet pstolerance(1e-9)

*repeat excercise using Angrist (2009) restriction
keep if _pscore > .1
keep if _pscore < .9


psmatch2 treat2 `vars' re74 re75, out(re78) ate common

teffects psmatch (re78) (treat2 `vars'), ate  pstolerance(1e-9)
teffects psmatch (re78) (treat2 `vars'), atet pstolerance(1e-9)


********************************************************************************





cap restore not
cap log close

