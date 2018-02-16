set more off
use "/Users/howiekaufman/Downloads/bw_smoking.dta"
cd "/Users/howiekaufman/Downloads"

label variable dbirwt "birth weight of infant (in grams)"
label variable tobacco "tobacco use indicator"
label variable dmage "mother's age"
label variable dmeduc "mother's educational attainment"
label variable mblack "mother is black"
label variable motherr "mother neither black nor white"
label variable mhispan "mother hispanic"
label variable dmar "mother is unmarried"
label variable foreignb "mother is foreign born"
label variable dfage "father's age"
label variable dfeduc "father's educational attainment"
label variable fblack "father is black"
label variable fotherr "father neither black nor white"
label variable fhispan "father is hispanic"
label variable alcohol "alcohol use indicator"
label variable drink "number of drinks per week"
label variable tripre1 "prenatal care visit in 1st trimester"
label variable tripre1 "prenatal care visit in 2nd trimester"
label variable tripre1 "prenatal care visit in 3rd trimester"
label variable tripre0 "no prenatal visits"
label variable nprevist "total number of prenatal visits"
label variable diabete "mother diabetic"
label variable anemia "mother anemic"
label variable phyper "mother had pregnancy-associated hypertension"
label variable plural "twins or greater birth"
label variable first  "first-born"
label variable dlivord "birth order of this child"
label variable disllb "months since last birth"
label variable preterm "previous birth premature or small for gestational age"
label variable pre4000 "previously had > 4000 gram newborn"
label variable fatalities "previous births where newborn died"



*summarize important / categorical variables and check the proporion of smokers 
foreach var of varlist dbirwt tobacco dmage dmedu drink dfedu npre dl dis fat {
	sum `var', det
}

*look at the frequency of the dummy variables
foreach v of varlist m* f* dmar alcohol drink trip* diab ane phy plu first pre* {
	di `"`: var label `v''"' 
	count if `v' == 1
	di r(N)/139149
}

*conditional probabilities of smoking based on controls
foreach var of varlist mb mo mh dmar for alcohol trip* diab anem phy plur first dl dis {
	di "BELOW: proportion of smokers when `var' is True"
	proportion tobacco if `var' == 1
}

*check differences in varaibles in smoking and non smoking population
foreach v of varlist dbirwt dmage dmedu drink dfedu npre dl dis fat m* f* dmar alcohol drink trip* diab ane phy plu first pre* {
	di `"BELOW: summary of `: var label `v'' in smoking pop"'
	sum `v' if tobacco == 1, det
	di `"BELOW: summary of `: var label `v'' in non-smoking pop"'
	sum `v' if tobacco == 0, det
}


/*
NOTE: see outreg2 documentation to switch output to excel format
*/
*initial regression
reg dbir tobacco, r
outreg2 using reg, tex(frag) ctitle(OLS) label replace
margins, over(tobacco)
marginsplot, x(tobacco) ytitle("Weight in Grams") xlabel(`=0' "No Smoking" `=1' "Smoking") title("Effect of Smoking on Birth Weight")
graph export g_1.png, replace

*regression controlling for mother's parental attributes
reg dbir tobac dmage dfage dmedu mb mo mh dmar for, r
outreg2 using reg, tex(frag) ctitle(Mother Attribute Controls) append label 
margins, over(tobacco)
marginsplot, x(tobacco) ytitle("Weight in Grams") xlabel(`=0' "No Smoking" `=1' "Smoking") title("Effect of Smoking on Birth Weight")
graph export g_2.png, replace

*regression controlling for mother and father parental attributes
reg dbir tobac dmage dfage dmedu mb mo mh dmar for df* fb for fh, r
outreg2 using reg, tex(frag) ctitle(Parents Attribute Controls) append label 
margins, over(tobacco)
marginsplot, x(tobacco) ytitle("Weight in Grams") xlabel(`=0' "No Smoking" `=1' "Smoking") title("Effect of Smoking on Birth Weight")
graph export g_3.png, replace

*regression controlling for additional behavior of the mother
reg dbir tobac dmage  dmedu mb mo mh dmar for alco drink trip* npre diab anem phy plur first dl dis, r
outreg2 using reg, tex(frag) ctitle(Mother Attribute and Behavior Controls) keep(tobac dmage dmedu mb mo mh dmar for alcohol drink) addtext(Drinking Behavior, YES, Health Behavior, YES, Health Conditions, YES)  append label 
margins, over(tobacco)
marginsplot, x(tobacco) ytitle("Weight in Grams") xlabel(`=0' "No Smoking" `=1' "Smoking") title("Effect of Smoking on Birth Weight")
graph export g_4.png, replace

*produce table of frequecies for control variables in smoking and non smoking populaion
bysort tobacco: outreg2 using freqs, tex(frag) replace sum(log) eqkeep(mean sd)  label


