/*******************************************************************************
Author: Alex Kaufman
Date: 12/29
Description: Impact Evaluation Assignment
*******************************************************************************/
set more off
cap ssc install diff


local dataPATH "C:\Users\fcoca\Downloads\"
local data nswd13.dta

local codePATH "C:\Users\fcoca\OneDrive\Documentos\GitHub\WWS_class"

local cov bk kfc roys 
********************************************************************************

use CK1994.dta, clear

*diff in diff
diff fte, t(treated) p(t) 
diff fte, t(treated) p(t) cov(`cov')

*check
reg fte t##treated 
reg fte t##treated `cov'

*alternative specification
sort id t
gen Dfte     = fte - fte[_n-1]
replace Dfte = . if t == 0

teffects ra (Dfte) (treated)
teffects ra (Dfte `cov') (treated)


*check
reg Dfte treated
reg Dfte treated `cov'

