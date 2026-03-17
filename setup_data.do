cd "D:\david\3PR\programs"
/*
Can you (or we ask Aneysha) create a PIP/ILOSTAT combined data set with:
Country 
Year
Poverty rate 
Total employed (N) or employment rate (if easy to get working age pop N)
Share of employed in sector 1
Share of employed in sector 2
Share of employed in sector 3
Share of employed in sector 4
Share of employed in sector 5
Total pop (in case we weight by pop)
Country income classification (as of 2024)
*/ 

*1. Start by loading in pip 
/*
clear 
pip cl, coverage("national") povline(3.2) fillgaps  
duplicates tag country_code year, gen(dups)
drop if dups==1 & welfare_type==1 // keep income when both income and consumption reported 
unique country_code year 

save "..\data\pip", replace 
**/ 

/*
clear 
import excel "../data/CLASS_2025_10_07", firstrow 
rename Code country_code 
rename Incomegroup incomegroup_fy26 
keep country_code incomegroup 
drop if country_code=="" 
save "../data/incomegroup", replace 
*/ 

clear
*import delimited using "../data/combined_data_all"
*save "../data/combined_data_all", replace 
use "../data/combined_data_revised", replace 
gen sex="t" 
append using "../data/combined_data_revisedF"
replace sex="f" if sex=="" 
append using "../data/combined_data_revisedM"
replace sex="m" if sex=="" 



rename ccode country_code  
* rename time year 
sort country year sector 

reshape wide employ share, i(country_code year sector) j(sex) string 

tab sector 
rename sector sector_orig 
recode sector_orig (34/46 53/99=9 "Other non-ag"), generate(sector)
tab sector 

collapse (rawsum) employ* share*, by(country_code year sector)

unique country_code year sector 


decode sector, gen(sector_label)
replace sector_label = subinstr(sector_label, " ", "", .)
replace sector_label = subinstr(sector_label, "-", "", .)
replace sector_label = subinstr(sector_label, ",", "", .)


drop sector 

reshape wide emp* share*, i(country_code year) j(sector) string 


count 
unique country_code 

merge n:1 country_code year using "../data/pip", keep(1 3)
list country_code year if _m==1 
keep if _m==3 // drops argentina because PIP is urban only and some pacific islands not in PIP. 
drop _m 
count 
unique country_code 

merge n:1 country_code using "../data/incomegroup"


keep country_code year emp* headcount poverty_gap population gdp incomegroup region_code  



drop if year==. 
rename employ?InfraEenergy employ?InfraEnergy

foreach gender in t m f {

egen totemploy`gender'=rsum(employ`gender'Agribusiness employ`gender'AgricSE employ`gender'Health employ`gender'InfraEnergy employ`gender'Manufac employ`gender'Othernonag employ`gender'Tradenonvehicle employ`gender'Tourism)

foreach sector in Agribusiness AgricSE Health InfraEnergy Manufac NoTourSplit Nontourism Othernonag Tradenonvehicle Tourism {
	gen share`gender'`sector'=employ`gender'`sector'/totemploy`gender'
}

} 


save "../data/sectors_pip", replace 

