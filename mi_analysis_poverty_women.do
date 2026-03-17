clear 

use "../data/mi_data", replace 
local sectors "sharefInfraEnergy sharefAgribusiness sharefAgricSE sharefHealth sharefTourism sharefManufac sharefOthernonag sharefTradenonvehicle"

local Nsectorsm1=7

** do headcount estimation 
mi estimate, post cmdok dots: fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)
estimates save "poverty", replace  
estimates use "poverty"

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Poverty_women")

mimrgns ,dydx(sharef*) post predict(cm)
estimates save "mimrgns", replace 
estimates use "mimrgns"

ereturn display
matrix T = r(table)
matrix B=T[1,1..`Nsectorsm1']
putexcel B2 = matrix(B')

local row=2 
foreach col_idx of numlist 1/`Nsectorsm1' {
local p = T[4,`col_idx']
	if `p' < 0.05 {
        putexcel B`row', bold
    }
	local row = `row' + 1
}

local row=`row'+2 
putexcel b`row'=`=e(N)'

preserve 
mi extract 1, clear
fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
putexcel b12=`=r(unique)'
restore 

 
** do poverty gap estimation 
mi estimate, post cmdok dots: fracreg probit poverty_gap headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)
estimates save "poverty_gap", replace  
estimates use "poverty_gap"

mimrgns ,dydx(sharef*) post predict(cm)
estimates save "mimrgns_gap", replace 
estimates use "mimrgns_gap"

ereturn display
matrix T = r(table)
matrix B=T[1,1..`Nsectorsm1']
putexcel C2 = matrix(B')

local row=2 
foreach col_idx of numlist 1/`Nsectorsm1' {
local p = T[4,`col_idx']
	if `p' < 0.05 {
        putexcel C`row', bold
    }
	local row = `row' + 1
}

local row=`row'+2 
putexcel C`row'=`=e(N)'

exit  
preserve 
mi extract 1, clear
fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
putexcel c12=`=r(unique)'
restore 
 
 

** output unweighted mean shares for each sector 
mean sharefInfraEnergy sharefAgribusiness sharefAgricSE sharefHealth mean_sharefTourism sharefManufac mean_sharefOthernonag sharefTradenonvehicle 
matrix B=e(b)
putexcel d2=matrix(B')



