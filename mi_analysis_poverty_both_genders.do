clear 

use "../data/mi_data", replace 
* both genders first 
local sectors "sharefInfraEnergy sharefAgribusiness sharefAgricSE sharefHealth sharefTourism sharefManufac sharefOthernonag"
local sectors "`sectors' sharemInfraEnergy sharemAgribusiness sharemAgricSE sharemHealth sharemTourism sharemManufac sharemOthernonag"
local Nsectors=14 


** do headcount estimation 
mi estimate, post cmdok dots: fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)
estimates save "poverty_both_genders", replace  
estimates use "poverty_both_genders"

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Poverty_both_genders")

mimrgns ,dydx(sharef* sharem*) post predict(cm)
estimates save "mimrgns_both_genders", replace 
estimates use "mimrgns_both_genders"

ereturn display
matrix T = r(table)
matrix B=T[1,1..`Nsectors']
putexcel C2 = matrix(B')

local row=2 
foreach col_idx of numlist 1/`Nsectors' {
local p = T[4,`col_idx']
	if `p' < 0.05 {
        putexcel C`row', bold
    }
	local row = `row' + 1
}

local row=`row'+2 
putexcel C`row'=`=e(N)'

preserve 
mi extract 1, clear
fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
local row=`row'+1 
putexcel C`row'=`=r(unique)'
restore 

** do poverty gap estimation 
mi estimate, post cmdok dots: fracreg probit poverty_gap headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)
estimates save "poverty_gap", replace  
estimates use "poverty_gap"

mimrgns ,dydx(sharef* sharem*) post predict(cm)
estimates save "mimrgns_gap", replace 
estimates use "mimrgns_gap"

ereturn display
matrix T = r(table)
matrix B=T[1,1..`Nsectors']
putexcel D2 = matrix(B')

local row=2 
foreach col_idx of numlist 1/`Nsectors' {
local p = T[4,`col_idx']
	if `p' < 0.05 {
        putexcel D`row', bold
    }
	local row = `row' + 1
}

local row=`row'+2 
putexcel D`row'=`=e(N)'
local row=`row'+1 
  
preserve 
mi extract 1, clear
fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
putexcel D`row'=`=r(unique)'
restore 
 
exit  

** output unweighted mean shares for each sector 
mean sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth mean_sharetTourism sharetManufac mean_sharetOthernonag sharetTradenonvehicle 
matrix B=e(b)
putexcel d2=matrix(B')



