**Kensington parkrun analysis
clear
set more off

use "D:\My Documents\Gorman Home\parkrun\parkrunresults-newformat.dta"

keep eventnum eventyear eventdate pos name time athletenum agecat agegrade gender genderpos club notes runs event

*standardize gender
replace gender="M" if gender=="Male"
replace gender="F" if gender=="Female"

*
destring runs, replace force
destring genderpos, replace force

append using "D:\My Documents\Gorman Home\parkrun\parkrunresults-oldformat.dta"
drop if name==""

*set the max number of events for parkrun in the DC area as scalar z
distinct eventnum
*scalar z=r(ndistinct)
scalar z= 300
replace event="Fletcher's Cove" if event=="Fletcher's Cover"
gen Junior=substr(agecat,1,1)

duplicates drop event eventnum pos, force



*show who is at DMV 4 and 5 tourism
sort name
by name: egen maxparkruns=max(runs)
save "D:\My Documents\Gorman Home\parkrun\temp.dta",replace


sort name event eventnum
by name event: keep if _n==1
drop if event=="Leakin Park"
by name: gen totaldc=_N
tab totaldc
sort name eventdate
by name: keep if _n==1

log using "D:\My Documents\Gorman Home\parkrun\parkrun post-analysis.smcl",replace
dis "PARKRUN ANALYSIS"

gen year=eventyear
replace year=2021 if eventyear==21
replace year=2022 if eventyear==22
replace year=2023 if eventyear==23

sort year
list name event year eventdate if totaldc==6
list name if totaldc==5

log off

use "D:\My Documents\Gorman Home\parkrun\temp.dta",clear


*REMOVE the asterisk before the parkrun you want to analyze
*keep if event=="College Park"
keep if event=="Kensington"
*keep if event=="Anacostia"
*keep if event=="Fletcher's Cove"
*keep if event=="Roosevelt Island"
*keep if event=="Baltimore and Annapolis"

duplicates drop event eventnum pos, force


**Generate Median and quartile time

**determine time

gen str8 stime = time
gen L=length(stime)
gen ztime="0"+stime if L==7
replace stime=ztime if L==7
drop ztime L
*reads first two digits as number
gen shours=substr(stime,2,1) 
gen hours = real(shours)
gen sminutes = substr(stime, 4, 2) 
*takes digits 4 and 5
gen minutes = real(sminutes)
gen sseconds = substr(stime, 7, 2)
gen seconds = real(sseconds)
gen totsecs = 3600*hours + 60*minutes + seconds

** generate stats
sum totsecs, detail
dis r(p50)
gen MedianMin=floor(r(p50)/60)
gen MedianSec=((r(p50)/60)-MedianMin)*60

gen Q1Min=floor(r(p25)/60)
gen Q1Sec=((r(p25)/60)-Q1Min)*60

gen Q3Min=floor(r(p75)/60)
gen Q3Sec=((r(p75)/60)-Q3Min)*60

gen Over40=0
replace Over40=1 if totsecs > 2400


log on
**Median Finisher Time
tostring Median* Q1* Q3*, replace

dis Q1Min + ":" + Q1Sec
dis MedianMin + ":" + MedianSec
dis Q3Min + ":" + Q3Sec

tab Over40

set more off


*unique names and total participants at this event


distinct name
distinct eventnum


scalar totalevents=r(ndistinct)

*show how many runs at this event by runner
sort name
by name: gen KensingtonRuns=_N
by name: egen maxruns=max(runs)
gen KensingtonPct=KensingtonRuns/maxruns
gen MostRecentEvent=eventdate if maxruns==runs
sort name eventnum
by name: replace MostRecentEvent=MostRecentEvent[_N]

save "D:\My Documents\Gorman Home\parkrun\temp.dta",replace


log off
*number of PBs
sort name event
gen PB=0
replace PB=1 if notes=="New PB!" | notes=="First Timer!"
keep if PB==1
by name: egen totalPBs=sum(PB)
*by name: keep if _n==1
gen PBratio=totalPBs/KensingtonRuns
sort totalPBs
*list name totalPBs PBratio
sort PBratio
set more off
*list name PBratio totalPBs if KensingtonRuns>9



*upcoming milestones
set more off



*stat of first name letters
gen FirstInitial=substr(name,1,1)
distinct FirstInitial
log on
tab FirstInitial
log off
*highest event Kensington PB
sort name eventnum
gen PBEventHigh=0

by name: replace PBEventHigh=_n if note=="New PB!"
by name: egen newPBEventHigh=max(PBEventHigh)
drop PBEventHigh
ren newPBEventHigh PBEventHigh
log on

*look for groundhog event
use "D:\My Documents\Gorman Home\parkrun\temp.dta",clear


log off
sort name eventnum
by name: gen groundhog=1 if time[_n]==time[_n-1] & name!="Unknown"
log on
list name eventnum time if groundhog==1

*gender and age breakdown
tab gender
tab agecat
tab Junior




*how many new name and how many new to Kensington names
log off
set more off
gen parkrunFirstTimer=0
replace parkrunFirstTimer=1 if note=="First Timer!"

log on
tab parkrunFirstTimer
log off
sort eventnum
gen FemalePct=0
gen Females=0


set more off

*generate percentage of women
set more off
local i=1
while `i'<(z) {
	count if gender=="F" & eventnum==`i'
	replace Females=r(N) if eventnum==`i'
	dis `i'
	pause on
	distinct name if eventnum==`i'
	replace FemalePct=Females/r(ndistinct) if eventnum==`i'
	local i=`i'+1
}

set more off
*generate percentage of >40 min
sort eventnum
gen FortyPct=0
gen FortyPlus=0
set more off
local i=1
while `i'<(z) {
	count if totsec>=2400 & eventnum==`i'
	replace FortyPlus=r(N) if eventnum==`i'
	dis `i'
	pause on
	distinct name if eventnum==`i'
	replace FortyPct=FortyPlus/r(ndistinct) if eventnum==`i'
	local i=`i'+1
}







by eventnum: egen parkrunFirstTimers=sum(parkrunFirstTimer)
sort eventnum
by eventnum: gen totalnames=_N

log on
*Milestones Upcoming
log off

*save temp file
set more off
gen pindex=0
save "D:\My Documents\Gorman Home\parkrun\temp.dta",replace

log on
**for PBs, show dropped secs
log off
sort name eventnum
keep if notes=="First Timer!" | notes=="New PB!"
by name: gen DeltaPB=totsec[_n]-totsecs[_n-1] if _n!=1
by name: drop if _N==1
sort eventnum
egen LatestEvent=max(eventnum)
keep if eventnum==LatestEvent
log on
list eventnum name time DeltaPB eventnum
log off

**List first timers
use "D:\My Documents\Gorman Home\parkrun\temp.dta",clear
sort eventnum
egen LatestEvent=max(eventnum)
keep if eventnum==LatestEvent
keep if notes=="First Timer!"
log on
list eventnum name time runs notes 
log off

**back to main analysis


use "D:\My Documents\Gorman Home\parkrun\temp.dta",clear
sort name
by name: keep if _n==1
log on
*Each unique runner, total Kensington runs, total runs, and  % at Kensington
*list name KensingtonRuns maxruns KensingtonPct MostRecentEvent

*Upcoming Junior 10-milestone
list name maxparkruns maxruns KensingtonPct MostRecentEvent if Junior=="J" & maxparkruns >7 & maxparkruns<10
*Upcoming 25 unofficial milestones
list name maxparkruns maxruns KensingtonPct MostRecentEvent if maxparkruns >22 & maxparkruns<25 & KensingtonPct>0.25
*Upcoming 50-milestone
list name maxparkruns maxruns KensingtonPct MostRecentEvent if maxparkruns >44 & maxparkruns<50 & KensingtonPct>0.10
*Upcoming 100-milestone
list name maxparkruns maxruns KensingtonPct MostRecentEvent if maxparkruns >95 & maxparkruns<100 & KensingtonPct>0.2
*Upcoming 250-milestone
list name maxparkruns maxruns KensingtonPct MostRecentEvent if maxparkruns >245 & maxparkruns<250 & KensingtonPct>0.2




log off



************
use "D:\My Documents\Gorman Home\parkrun\temp.dta", clear
sort eventnum
by eventnum: keep if _n==1
gen FirstPct=parkrunFirstTimers/totalnames
keep event eventnum eventdate *FirstTimers totalname FirstPct FemalePct FortyPct

*graph stats
sort event eventnum

gen participants=totalnames
gen FirstTimers=parkrunFirstTimers
gen PctOver40min=FortyPct
gen PctFemale=FemalePct

twoway (connected participants eventnum, sort) (connected FirstTimers eventnum, sort) (connected PctOver40min eventnum, sort yaxis(2)) (connected PctFemale eventnum, sort yaxis(2)), ylabel(, angle(horizontal)) yscale(range(0 1) axis(2)) title(Kensington parkrun) subtitle(Participants - First-Timers - % Over-40-min - % Female)
graph export "D:\My Documents\Gorman Home\parkrun\participation.tif", as(tif) replace

twoway  (connected PctOver40min eventnum, sort), title(Kensington parkrun) subtitle(Participants % Over-40-min)
graph export "D:\My Documents\Gorman Home\parkrun\Over40graph.png", as(tif) replace


 **generate p-index


 set more off

 log on
 *show the 5+ and 10+ clubs

 foreach num of numlist 5/10 {
	use "D:\My Documents\Gorman Home\parkrun\temp.dta", clear
	gen a=0
	set more off
	drop if name=="Unknown"
	sort name
	by name: egen marker=count(pos)
	sort name marker
	by name: keep if _n==1
	*tab marker
 	
	replace marker=`num' if marker > `num'
	*tab marker
	drop if marker<`num'
	replace pindex=`num'
	sort KensingtonRuns
	replace a=_N
	*tostring a, replace
	dis a
	dis " have run"
	dis pindex
	dis " times"
	list name KensingtonRuns MostRecentEvent if KensingtonRuns==pindex
	*dis a + " parkrunners have run " + `num' + " times"
}
 
 set more off
 foreach num of numlist 20/150 {
	use "D:\My Documents\Gorman Home\parkrun\temp.dta", clear
	gen a=0
	set more off
	drop if name=="Unknown"
	sort name
	by name: egen marker=count(pos)
	sort name marker
	by name: keep if _n==1
	*tab marker
 	
	replace marker=`num' if marker > `num'
	*tab marker
	drop if marker<`num'
	replace pindex=`num'
	sort KensingtonRuns
	replace a=_N
	*tostring a, replace
	dis a
	dis " have run"
	dis pindex
	dis " times"
	list name KensingtonRuns MostRecentEvent if KensingtonRuns==pindex
	*dis a + " parkrunners have run " + `num' + " times"
}




 
 
set more off

 use "D:\My Documents\Gorman Home\parkrun\temp.dta", clear

 tabstat KensingtonRuns, statistics(p5 p10 p25 p50 p75 p95)
 
 sort eventnum pos
 by eventnum: egen Finishers=max(pos)
 by eventnum: keep if _n==1
 gsort -Finishers
 list eventdate Finishers eventnum 
 
 histogram Finishers, discrete width(1) xlabel(0(10)170) title(Distribution of Kp Total Finishers)
graph export "D:\My Documents\Gorman Home\parkrun\finisher histogram.tif", as(tif) replace
 
gen FinisherGroup=0
replace FinisherGroup=1 if Finishers>9 & Finishers<20
replace FinisherGroup=2 if Finishers>19 & Finishers<30
replace FinisherGroup=3 if Finishers>29 & Finishers<40
replace FinisherGroup=4 if Finishers>39 & Finishers<50
replace FinisherGroup=5 if Finishers>49 & Finishers<60
replace FinisherGroup=6 if Finishers>59 & Finishers<70
replace FinisherGroup=7 if Finishers>69 & Finishers<80
replace FinisherGroup=8 if Finishers>79 & Finishers<90
replace FinisherGroup=9 if Finishers>89 & Finishers<100
replace FinisherGroup=10 if Finishers>99 & Finishers<110
replace FinisherGroup=11 if Finishers>109 & Finishers<120
replace FinisherGroup=12 if Finishers>119 & Finishers<130
replace FinisherGroup=13 if Finishers>129 & Finishers<140
replace FinisherGroup=14 if Finishers>139 & Finishers<150
replace FinisherGroup=15 if Finishers>149 & Finishers<160
replace FinisherGroup=16 if Finishers>159 & Finishers<170
replace FinisherGroup=17 if Finishers>169 & Finishers<180
replace FinisherGroup=18 if Finishers>179 & Finishers<190
replace FinisherGroup=19 if Finishers>189 & Finishers<200
replace FinisherGroup=20 if Finishers>199 & Finishers<210
replace FinisherGroup=21 if Finishers>209 & Finishers<220
replace FinisherGroup=22 if Finishers>219 & Finishers<230
replace FinisherGroup=23 if Finishers>229 & Finishers<240
replace FinisherGroup=24 if Finishers>239 & Finishers<250
replace FinisherGroup=25 if Finishers>249 & Finishers<260


tab FinisherGroup
tabstat Finishers, statistics(q)

replace eventyear=2021 if eventyear==21
replace eventyear=2022 if eventyear==22
replace eventyear=2023 if eventyear==23

sort eventyear

graph box Finishers, over(eventyear)


keep if eventyear==2023
*2023 attendance stats
tabstat Finishers, statistics(q)



 
log close




