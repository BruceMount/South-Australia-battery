//This is the main code of the analysis of the paper "SA got 74% of electricity from the wind and sun and the lights stayed on". Many different analyses are done here as set out below.

 
//import original data and set it up
clear all

set maxvar 10000

 

import delimited "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Original data files /231003 operating demand  residual demand interconnector gas vre battery.csv", encoding(ISO-8859-1)
rename ïsettlementdate settlementdate

// Split out the year, month, day, hour, minute
gen Year = substr(settlementdate, 9,2)
gen Month = substr(settlementdate, 4,2)
gen Day = substr(settlementdate,1,2)
gen Hour = substr(settlementdate, 12,2)
gen Minute = substr(settlementdate,15,2)

generate double eventtime=clock(settlementdate, "DM20Yhm") // create numeric value for time

gen id = _n
gen num5mins = _N


// annual spot market revenue calculations
gen rev= saprice*saoperatingdemand/12000000
gen annualrev = sum(rev)


save "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace


// collapse for year's data and export results to excel sheet. The idea here is to see production by fuel type and prices and demand and residual demand by hour of day
clear all
use "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta"
collapse saprice saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging diesel, by(Hour)

clear all
use "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta"
collapse (median) saprice saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging diesel, by(Hour)

clear all
use "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta"
collapse (p5) saprice saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging diesel, by(Hour)

clear all
use "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta"
collapse (p95) saprice saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging diesel, by(Hour) 

clear all
use "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta"
collapse (min) saprice saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging diesel, by(Hour)

clear all
use "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta"
collapse (max) saprice saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging diesel, by(Hour)

// collapse for winter data. The idea here to see how production looks in the winter 

gen Winter = .
replace  Winter = 1 if nMonth > 5 & nMonth < 9   // create a winter variable
keep if Winter == 1
collapse (median)saoperatingdemand saresidualdemand sameteredflow sagasgeneration savregeneration sabatterygeneration sabatterycharging, by(Hour) 


// calculation of delta RD, OD, VRE and delta generation when deltard is greater than a value. The idea here is to understand how RD is being met when it is high 
// remember to reload the data

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if deltard<300 // the cut-off level to view the 5 minute change in residual demand
summarize deltagas deltadiesel deltabatterygen deltabatterycharge deltainterconnector,detail


/////  running total of RESIDUAL DEMAND, DISPATCH GEN AND OPERATING DEMAND

/// RESIDUAL DEMAND: calculating monthly (12), weekly (2052) , daily (288), 12 hourly (144), 8 hourly (96), 4 hourly (48) 2 hourly (24) 1 hourly (12) RD to work out net discharge. The idea is to work out the maximum discharge over differing periods of time This creates new columns
clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
//gen vrefactor = 1 //expand the VRE by a factor
gen rtsfactor = 1
gen lssfactor = 1
gen windfactor = 1

//gen modelrd = saoperatingdemand - vrefactor*savregeneration //how much residual demand is left after scaling VRE up pro-rate to now 
gen modelrd = saoperatingdemand - (rtsfactor-1)*sartsgeneration - lssfactor*salssgeneration - windfactor*sawindgeneration
gen runningsumrd= sum(modelrd)/12000 // the GWh (by dividing by 12 5 minutes values and 1000 to get to GWh) running total of RD - this is a cumulative total calculation. If used in storage calculation it implicitly assumes that the surpluses are stored

forvalue m = 0(2052)105121 	{
	gen m`m' = runningsumrd[`m']-runningsumrd[`m'-2052]
							}							
//clean up the file to make it usable	
keep  m* id
drop modelrd 	
drop if id>1 // get rid surplus rows
xpose, clear varname //columns into rows
gen id = _n	
rename v1 discharge
sum discharge

gen cumdischarge = sum(discharge) // add up the discharge over the period
sum cumdischarge


twoway (bar discharge id),ytitle(`"GWh"') xtitle(`"Year to 31 August 2023"')  title(`"Net Load (GWh) in sequential 7 day blocks "') xtitle(`"Year to 31 August 2023"') xlabel(#16) legend(off) // whats happening one 8 hours after the next
//histogram discharge, bin(20) frequency xlabel(#10) title(`"Net discharge (MWh) in X hour blocks"') legend(off) 
//twoway (line cumdischarge id), ytitle(`"Cumulative Net Stored Residual Demand (MWh)"') xtitle(`"Year from 1 September 2022 in X hour sequential increments"') xlabel(#16) legend(off)


/// DISPATCH GENERATION:  calculating monthly (8760), weekly (2052) , daily (288), 12 hourly (144), 8 hourly (96), 4 hourly (48) 2 hourly (24) 1 hourly (12) to work out DISPATCH GENERATION. 
clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
//gen vrefactor = 1 //expand the VRE by a factor
gen rtsfactor = 1.6
gen lssfactor = 1.6
gen windfactor = 1.6

//gen modelrd = saoperatingdemand - vrefactor*savregeneration //how much residual demand is left after scaling VRE up pro-rate to now 
gen modelrd = saoperatingdemand - (rtsfactor-1)*sartsgeneration - lssfactor*salssgeneration - windfactor*sawindgeneration
gen positive_modelrd = modelrd if modelrd>0
gen runningsum_positiverd = sum(positive_modelrd)/12000

forvalue m = 0(12)105121 	{
	gen m`m' = runningsum_positiverd[`m']-runningsum_positiverd[`m'-12]
							}							
//clean up the file to make it usable	
keep  m* id
drop modelrd 
drop if id>1 // get rid surplus rows

xpose, clear varname //columns into rows
gen id = _n	
rename v1 dispatchgen
sum dispatchgen

gen cumdispatchgen = sum(dispatchgen) // add up the dispatchable generation over the period
sum cumdispatchgen	

twoway (bar dispatchgen id), ytitle(`"GWh"') xtitle(`"Year from 1 September 2022"') title(`"Dispatchable generation requirement (GWh) in sequential hourly blocks"', size(medium))
histogram dispatchgen, bin(20) frequency xlabel(#10) title(`"Disptachable generation in X hour blocks"') legend(off) 
twoway (line cumdispatchgen id), ytitle(`"Cumulative dispatchable generation (MWh)"') xtitle(`"Year from 1 September 2022 in X hour sequential increments"') xlabel(#16) legend(off)


/// OPERATING DEMAND: calculating monthly (8760), weekly (2052) , daily (288), 12 hourly (144), 8 hourly (96), 4 hourly (48) 2 hourly (24) 1 hourly (12) Operating Demand 
clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace



gen rtsfactor = 1.6

gen modelod = saoperatingdemand - (rtsfactor-1)*sartsgeneration 
gen runningsumod= sum(modelod)/12000 // the GWh (by dividing 5 minutes values) running total of RD - this is a cumulative total calculation. If used in storage calculation it implicitly assumes that the surpluses are stored
sum runningsumod

forvalue m = 0(12)105121 	{
	gen m`m' = runningsumod[`m']-runningsumod[`m'-12]
							}							
//clean up the file to make it usable	
keep  m* id
drop modelod
drop if id>1 // get rid surplus rows

xpose, clear varname //columns into rows
gen id = _n	
rename v1 operatingdemand
sum operatingdemand

// gen cum_od = sum(operatingdemand) // add up the dispatchable generation over the period
// sum cum_od	

twoway (bar operatingdemand id), ytitle(`"GWh"') xtitle(`"Year from 1 September 2022"') title(`"Operating Demand(GWh) in sequential hourly blocks"', size(medium))	


//// BATTERY DISPATCH CHARTS

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace


drop if id>8760


twoway (bar bat5_vre id), ytitle(`"GWh"') xtitle(`"Hourly dispatch, year from 1 September 2022"') title(`"5 GWh storage dispatch"', size(medium))	

twoway (bar bat5_160vre id), ytitle(`"GWh"') xtitle(`"Hourly dispatch, year from 1 September 2022"') title(`"160% 2023VRE, 5 GWh storage"', size(medium))	

twoway (bar bat10_160vre id), ytitle(`"GWh"') xtitle(`"Hourly dispatch, year from 1 September 2022"') title(`"160% 2023VRE, 10 GWh storage"', size(medium))	

twoway (bar bat20_160vre id), ytitle(`"GWh"') xtitle(`"Hourly dispatch, year from 1 September 2022"') title(`"160% 2023VRE, 20 GWh storage"', size(medium))	

twoway (bar bat20_160vre id), ytitle(`"GWh"') xtitle(`"Hourly dispatch, year from 1 September 2022"') title(`"160% 2023VRE, 200 GWh storage "', size(medium))


////// DURATION CURVES OF RD, OD 

clear all
import excel "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Original data files /240111 duration curve input data.xlsx", sheet("Sheet1") firstrow clear

// OPERATING DEMAND DURARTION CURVE
twoway (line od12 od23  id), ytitle(`"GW"') xtitle(`"Number of hours for which OPERATING DEMAND is greater than y-axis value"') title(`"DURATION CURVE in 2012 and 2023"', size(medium))

// RESIDUAL DEMAND DURATION CURVE
twoway (line NL2012 NL2023 NL2023_160 NL2023_200 id), ytitle(`"GW"') xtitle(`"Number of hours for which Net Load is greater than y-axis value"') 	

// RESIDUAL DEMAND WITH 5 GWh STORAGE DURATION CURVE AND 2023, 160% OF 2023VRE AND 200% OF 2023VRE 
twoway (line rd23_5gwh rd23_160_5gwh rd23_200_5gwh id), ytitle(`"GW"') xtitle(`"Number of hours for which RESIDUAL DEMAND is greater than y-axis value"') title(`"DURATION CURVE with 5 GWh storage: 2023, 160% 2023VRE, 200% 2023VRE"', size(small))	

// NET LOAD WITH 0, 5,20,200 GWH AND 160% OF 2023VRE
twoway (line NL2023_160 NL2023_160_5gwh NL2023_160_20gwh NL2023_160_200gwh id), ytitle(`"GW"') xtitle(`"Number of hours for which Net Load is greater than y-axis value"') 

////// count number of days RD>0 by month

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23 = .
replace count_rd23 = 1 if rd23>0
collapse (sum) total=count_rd23,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23_1gwh = .
replace count_rd23_1gwh = 1 if rd23_1gwh>0
collapse (sum) total=count_rd23_1gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23_160 = .
replace count_rd23_160 = 1 if rd23_160>0
collapse (sum) total=count_rd23_160,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23_160_1gwh = .
replace count_rd23_160_1gwh = 1 if rd23_160_1gwh>0
collapse (sum) total=count_rd23_160_1gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23_160_5gwh = .
replace count_rd23_160_5gwh = 1 if rd23_160_5gwh>0
collapse (sum) total=count_rd23_160_5gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23_160_20gwh = .
replace count_rd23_160_20gwh = 1 if rd23_160_20gwh>0
collapse (sum) total=count_rd23_160_20gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen count_rd23_160_200gwh = .
replace count_rd23_160_200gwh = 1 if rd23_160_200gwh>0
collapse (sum) total=count_rd23_160_200gwh,  by(month_rd)

//// volume (GWh) of negative (spilled) RD by month

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23 = .
replace negative_rd23 = rd23 if rd23<0
collapse (sum) total=negative_rd23,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23_1gwh = .
replace negative_rd23_1gwh = rd23_1gwh if rd23<0
collapse (sum) total=negative_rd23_1gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23_160 = .
replace negative_rd23_160 = rd23_160 if rd23_160<0
collapse (sum) total=negative_rd23_160,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23_160_5gwh = .
replace negative_rd23_160_5gwh = rd23_160_5gwh if rd23_160_5gwh<0
collapse (sum) total=negative_rd23_160_5gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23_160_1gwh = .
replace negative_rd23_160_1gwh = rd23_160_1gwh if rd23_160_1gwh<0
collapse (sum) total=negative_rd23_160_1gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23_160_20gwh = .
replace negative_rd23_160_20gwh = rd23_160_20gwh if rd23_160_20gwh<0
collapse (sum) total=negative_rd23_160_20gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_rd23_160_200gwh = .
replace negative_rd23_160_200gwh = rd23_160_200gwh if rd23_160_200gwh<0
collapse (sum) total=negative_rd23_160_200gwh,  by(month_rd)

//// volume (GWh) of positive RD by month

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23 = .
replace positive_rd23 = rd23 if rd23>0
collapse (sum) total=positive_rd23,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23_1gwh = .
replace positive_rd23_1gwh = rd23_1gwh if rd23>0
collapse (sum) total=positive_rd23_1gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23_160 = .
replace positive_rd23_160 = rd23_160 if rd23_160>0
collapse (sum) total=positive_rd23_160,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23_160_1gwh = .
replace positive_rd23_160_1gwh = rd23_160_1gwh if rd23_160_1gwh>0
collapse (sum) total=positive_rd23_160_1gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23_160_5gwh = .
replace positive_rd23_160_5gwh = rd23_160_5gwh if rd23_160_5gwh>0
collapse (sum) total=positive_rd23_160_5gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23_160_20gwh = .
replace positive_rd23_160_20gwh = rd23_160_20gwh if rd23_160_20gwh>0
collapse (sum) total=positive_rd23_160_20gwh,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_rd23_160_200gwh = .
replace positive_rd23_160_200gwh = rd23_160_200gwh if rd23_160_200gwh>0
collapse (sum) total=positive_rd23_160_200gwh,  by(month_rd)

//// volume (GWh) of battery discharge  by month

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_bat5_160vre = .
replace negative_bat5_160vre = bat5_160vre if bat5_160vre<0
collapse (sum) total=negative_bat5_160vre,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_bat20_160vre = .
replace negative_bat20_160vre = bat20_160vre if bat20_160vre<0
collapse (sum) total=negative_bat20_160vre,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen negative_bat200_160vre = .
replace negative_bat200_160vre = bat200_160vre if bat200_160vre<0
collapse (sum) total=negative_bat200_160vre,  by(month_rd)


//// volume (GWh) of battery charge  by month

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_bat5_160vre = .
replace positive_bat5_160vre = bat5_160vre if bat5_160vre>0
collapse (sum) total=positive_bat5_160vre,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_bat20_160vre = .
replace positive_bat20_160vre = bat20_160vre if bat20_160vre>0
collapse (sum) total=positive_bat20_160vre,  by(month_rd)

clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
drop if id>8760
gen positive_bat200_160vre = .
replace positive_bat200_160vre = bat200_160vre if bat200_160vre>0
collapse (sum) total=positive_bat200_160vre,  by(month_rd)




//// UTILITIES

///creating 2012 OD and RD hourly data

//OD
clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
gen runningsumod12= sum(od_2012)/12000 // the GWh (by dividing 5 minutes values) running total of RD - this is a cumulative total calculation. If used in storage calculation it implicitly assumes that the surpluses are stored
forvalue m = 0(12)105121 	{
	gen m`m' = runningsumod12[`m']-runningsumod12[`m'-12]
							}							
//clean up the file to make it usable	
keep  m* id
drop if id>1 // get rid surplus rows

xpose, clear varname //columns into rows
gen id = _n	
rename v1 sa_od12
sum sa_od12

//RD
clear all
use  "/Users/e5110130/Library/CloudStorage/GoogleDrive-bruce.mountain@cmeaustralia.com.au/Shared drives/VEPC/Stata/BM stata tools/Generation price demand analysis tool /Dta files/231003 operating demand  residual demand interconnector gas vre battery.dta", replace
gen runningsumrd12= sum(rd_2012)/12000 // the GWh (by dividing 5 minutes values) running total of RD - this is a cumulative total calculation. If used in storage calculation it implicitly assumes that the surpluses are stored
forvalue m = 0(12)105121 	{
	gen m`m' = runningsumrd12[`m']-runningsumrd12[`m'-12]
							}							
//clean up the file to make it usable	
keep  m* id
drop if id>1 // get rid surplus rows

xpose, clear varname //columns into rows
gen id = _n	
rename v1 sa_rd12
sum sa_rd12


//// annual spot market revenue calculations

drop rev annualrev

gen rev= saprice*saoperatingdemand/12000000
gen annualrev = sum(rev)
sum annualrev







////// Some graphics

gen nMonth = real(Month)
gen nHour = real(Hour)



egen mean_saoperatingdemand = mean(saoperatingdemand), by(nHour)
egen mean_saresidualdemand = mean(saresidualdemand), by(nHour)
					}
summarize mean_saoperatingdemand
					
					
gen high = .
gen low = .

forvalues i = 0/23 {
          ci mean saoperatingdemand if nHour == `i',level(99.99)
           replace high = r(ub) if nHour == `i'
           replace low = r(lb) if nHour == `i'
					}					

forvalues j = 0/23 {
          ci mean saresidualdemand if nHour == `j',level(99.99)
           replace high = r(ub) if nHour == `j'
           replace low = r(lb) if nHour == `j'
					}						
									
sort nHour

graph twoway (rcap low high nHour) (connected mean_saoperatingdemand nHour, msize(tiny) lwidth(thin) title("Operating Demand") ytitle("MW") xtitle("Hour of day") xlab(0(1)23) graphregion(color(white)) bgcolor(white) color(navy))					
					
					
graph twoway (rcap low high nHour) (connected mean_saresidualdemand mean_saoperatingdemand nHour, msize(tiny) lwidth(thin) title("Operating Demand") ytitle("MW") xtitle("Hour of day") xlab(0(1)23) graphregion(color(white)) bgcolor(white) color(navy))							


	
