set more off
set matsize 10000

use "\\files\ak29\ClusterDownloads\foxnews.dta", clear

cd "\\files\ak29\ClusterDownloads\WWS_class-master\WWS_class-master\New folder"

*Calculate voteshare variables
gen RvoteShare96 = reppresvotes1996 / demreppresvotes1996
gen RvoteShare00 = reppresvotes2000 / demreppresvotes2000

label variable RvoteShare96 "Republican Vote Share 1996"
label variable RvoteShare00 "Republican Vote Share 2000"


*gen DvoteShare96 = demreppresvotes1996 / (reppresvotes1996 + demreppresvotes1996)


*Calculate change in republican vote share 1996 to 2000
gen voteShareChange = RvoteShare00 - RvoteShare96
label variable voteShareChange "Republican Vote Share Change"

*lets take a look
bysort fox: outreg2 using freqs, tex(frag) replace sum(log) eqkeep(mean sd)  label

/*Calculate change in repulbican turn out rate
gen turnoutChange = (reppresvotes1996 / pop18p1996) 
* Oh wait, you can't because there is no matching population data for 1996 and 2000 and I'm not gonna go get it for some dumb stats project*/

/*Calculate the percent of the population that have cable
gen cable_pct = sub2000 / poptot2000
*/

*determine if the cable subscriber variables are totally messed up
count if sub2000 > poptot2000 & sub2000 < .
count if sub2000 <= poptot2000 & sub2000 < .
corr pop18 poptot2000

*calculate the pct of potential subscribers anyway
gen pct_sub = sub2000 / poptot2000
replace pct_sub = 1 if pct_sub > 1
label variable pct_sub "% of Pop. Subscribed to Cable"

*determine if HS,HSP,COLLEGE variables are cumulative
count if college2000 > hs2000 // TURNS OUT THEY ARE MUTUALLY EXCLUSIVE

*determine if the cnn variable has any variation (it does not)
sum cnn
drop cnn

*create a numerical variables for state
encode(state), gen(state_n)

*creage a numerical variable for county
egen county_n = group(state county)

*swap state_n and county_n to exchange state fixed effects and county fixed effect
local geoFEvar county_n

*Run some basic regressions to examine the impact of Fox News on Republican Vote Share
reg voteShare fox
outreg2 using reg_1, tex(frag) ctitle(OLS) label replace

reg voteShare fox RvoteShare96 
outreg2 using reg_1, tex(frag) ctitle(Party Control) append label 

reg voteShare fox RvoteShare96 i.`geoFEvar'
outreg2 using reg_1, tex(frag) ctitle(Fixed Effects) keep(fox RvoteShare96) addtext(County Fixed Effects,YES) append label 

reg voteShare fox RvoteShare96 pop2 income2 male2 college2 i.`geoFEvar'
outreg2 using reg_1, tex(frag) ctitle(Population Controls) keep(fox RvoteShare96 pop2 income2 male2 college2) addtext(County Fixed Effects,YES) append label 

reg voteShare fox RvoteShare96 pop2 income2 male2 college2 unempl2 black2000 urban2000 i.`geoFEvar'
outreg2 using reg_1, tex(frag) ctitle(Demographic Controls) keep(fox RvoteShare96 pop2 income2 male2 college2 unempl2 black2 urban2) addtext(County Fixed Effects,YES) append label 

reg voteShare fox RvoteShare96 nochannels i.`geoFEvar'
outreg2 using reg_2, tex(frag) ctitle(Cable Controls) keep(fox RvoteShare96 nochanne) addtext(County Fixed Effects,YES) label replace

reg voteShare fox RvoteShare96 pct_sub nochannels i.`geoFEvar'
outreg2 using reg_2, tex(frag) ctitle(Cable Controls) keep(fox RvoteShare96 nochanne pct) addtext(County Fixed Effects,YES) append label

reg voteShare fox RvoteShare96 pop2 income2 male2 college2 unempl2 black2000 urban2000 nochann i.`geoFEvar'
outreg2 using reg_2, tex(frag) ctitle(Full Controls) keep(fox RvoteShare96 pop2 income2 male2 college2 unempl2 black2000 urban2000 nochanne) addtext(County Fixed Effects,YES) append label

reg voteShare fox RvoteShare96 pop2 income2 male2 college2 unempl2 black2000 urban2000 nochannels pct_sub  i.`geoFEvar'
outreg2 using reg_2, tex(frag) ctitle(Full Controls) keep(fox RvoteShare96 pop2 income2 male2 college2 unempl2 black2000 urban2000 nochanne pct) addtext(County Fixed Effects,YES) append label

*-------------------------interaction effects----------------------------------*
local geoFEvar county_n

reg voteShare  RvoteShare96 urban2 income2 foxnews2000##c.urban2000 foxnews2000##c.income2000 pop2 male2 college2 unempl2 black2000 i.`geoFEvar'
outreg2 using reg_3, tex(frag) ctitle(Demographic Interaction) keep(fox urban2 income2 foxnews2000##c.urban2000 foxnews2000##c.income2000 ) addtext(County Fixed Effects,YES, Full Pop. and Dem. Controls, YES) label replace

margins, dydx(foxnews2000) at(urban2=(0(.1)1)) vsquish
marginsplot, yline(0) title("Marginal Effects of Fox News - urban population interaction")
graph export urban_ME.png, replace

margins, dydx(foxnews2000) at(income2=(0(2)20)) vsquish
marginsplot, yline(0) title("Marginal Effects of Fox News - income interaction")
graph export income_ME.png, replace

reg voteShare nochann pct_sub foxnews2000##c.nochannel foxnews2000##c.pct_sub RvoteShare96 pop2 male2 college2 unempl2 black2000 urban2 income2  i.`geoFEvar'
outreg2 using reg_3, tex(frag) ctitle(Cable Interaction) keep(fox nochann pct_sub foxnews2000##c.nochannel foxnews2000##c.pct_sub) addtext(County Fixed Effects,YES, Full Pop. and Dem. Controls, YES) append label

margins, dydx(foxnews2000) at(nochannel=(0(10)100)) vsquish
marginsplot, yline(0) title("Marginal Effects of Fox News - No. of channels interaction")
graph export channel_ME.png, replace

margins, dydx(foxnews2000) at(pct_sub=(0(.1)1)) vsquish
marginsplot, yline(0) title("Marginal Effects of Fox News - % of pop. subscribed interaction")
graph export subscribers_ME.png, replace

reg voteShare nochann pct_sub foxnews2000##c.nochannel foxnews2000##c.pct_sub foxnews2000##c.urban2000 foxnews2000##c.income2000 RvoteShare96 pop2 male2 college2 unempl2 black2000 urban2 income2  i.`geoFEvar'
outreg2 using reg_3, tex(frag) ctitle(Full Interaction) keep(fox nochann pct_sub urban2 income2 foxnews2000##c.nochannel foxnews2000##c.pct_sub foxnews2000##c.urban2000 foxnews2000##c.income2000 ) addtext(County Fixed Effects,YES, Full Pop. and Dem. Controls, YES) append label

margins, dydx(foxnews2000) at(urban2=(0(.1)1)) vsquish
margins, dydx(foxnews2000) at(income2=(0(2)20)) vsquish
margins, dydx(foxnews2000) at(nochannel=(0(10)100)) vsquish
margins, dydx(foxnews2000) at(pct_sub=(0(.1)1)) vsquish


*Include some basic controls for population and demographics

*-----------------------Examine the assignment of Fox News---------------------*


logit foxnews RvoteShare96

logit foxnews RvoteShare96 pop18
est store basic

logit foxnews2000 RvoteShare96 college2000 black2000 empl2000 income2000

logit foxnews2000 RvoteShare96 college2000 black2000 empl2000 income2000 urban2000 male2000 college2000 pop2000
est store demControls

logit foxnews2000 RvoteShare96 college2000 black2000 empl2000 income2000 urban2000 male2000 college2000 pop2000 nochan pct_sub
est store cableControls

outreg2 [basic demControls cableControls] using logit_1, tex(frag) label replace
