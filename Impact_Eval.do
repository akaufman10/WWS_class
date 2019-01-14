/*******************************************************************************
Author: Alex Kaufman
Date: 12/29
Description: Impact Evaluation Assignment
*******************************************************************************/
set more off
*cap ssc install stddiff
*cap ssc install psmatch2


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
reg re78 treat re75
reg re78 treat `vars' re75 re74
restore
BREAK!
*************************************Q2*****************************************

*create a flag for CPS only treatment control
gen treat2 = .
replace treat2 = 1 if sample == 0 & treat == 1
replace treat2 = 0 if sample == 1 & treat == 0

*check
*tab treat2 sample

*check balance in control variables 
foreach var of local vars {
	egen `var'_std = std(`var')
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
reg re78 treat2 `vars' re74 re75

************************************Q4******************************************
*examine income trends to check if parallel
sum re74 if treat == 1
sum re74 if treat == 0
sum re75 if treat == 1
sum re75 if treat == 0

drop if treat2 == .

psmatch2 treat2 `vars' re74 re75, common
ren _pscore pscore
ren _support csupport

*check common support 
tab treat2 csupport

*check common support
bysort treat2: sum pscore, det


*manually calculate pscore and check common support
probit treat2 `vars' re74 re75
predict double pscore_m

*check common support
bysort treat2: sum pscore_m, det

*graphical check
/*
graph twoway \\\
	(kdensity pscore if treat2 == 1) \\\
	(kdensity pscore if treat2 == 0 & pscore > .003)
*/

*check for common support by hand
egen min_pscm_t = min(pscore_m) if treat2 == 1
egen min_pscm = min(min_pscm_t)
egen max_pscm_t = max(pscore_m) if treat2 == 0
egen max_pscm = max(max_pscm_t)

gen csupport_m = 1
replace csupport_m = 0 if pscore_m < min_pscm | pscore_m > max_pscm

tab csupport_m
tab csupport_m treat2
drop _*

************************************Q6******************************************

*restrict sample to common support
*keep if csupport_m == 1


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



********************************************************************************





cap restore not
cap log close

