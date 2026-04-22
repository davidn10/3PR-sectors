
cd "D:\david\3PR\programs" 

use "../data/mi_data", replace 
local sectors "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetTourism sharetManufac sharetOthernonag sharetTrade"

gen emp_pop=totemployt/population 
gen lnemp_pop=log(emp_pop) 
local Nsectorsm1=7

gen lnheadcount=log(headcount) 

foreach sector in sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetManufac   { //sharetRetailtradenonvehicle
	gen Z_`sector'=log(`sector')
}

mi passive: gen Z_sharetTourism = log(sharetTourism)
mi passive: gen Z_sharetOthernonag = log(sharetOthernonag)


bys country_id (year): gen appearance=_n 
bys country_id (year): gen Nappearances=_N 
mi tsset country_id appearance 


gen gap=year-l.year 

foreach sector in sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetManufac { //sharetRetailtradenonvehicle
	gen dZ_`sector'=(Z_`sector'-l.Z_`sector')/gap 
}

gen dlnheadcount=(lnheadcount-l.lnheadcount)/gap 
gen dlnemp_pop=(lnemp_pop-l.lnemp_pop)/gap 

mi passive: gen dZ_shareTourism=(Z_sharetTourism-l.Z_sharetTourism)/gap 
mi passive: gen dZ_sharetOthernonag=(Z_sharetOthernonag-l.Z_sharetOthernonag)/gap 



mi estimate, post dots: regress dlnheadcount dZ_* dlnemp_pop i.country_id i.year_cat, vce(cluster country_id)
estimates save "poverty_spec3", replace  

* Extract sample indicator to replicate sample in levels regression 
save "mydata_mi.dta", replace
mi extract 1
regress dlnheadcount dZ_* dlnemp_pop i.country_id i.year_cat, vce(cluster country_id)
gen insample = e(sample)
tempfile samp
keep insample country_id year  // whatever your ID variable is
save `samp'
use "mydata_mi.dta", replace
merge m:1 country_id year using `samp', nogen
mi register regular insample
mi update





keep if insample==1 
mi estimate, post dots: regress lnheadcount Z_* lnemp_pop i.country_id i.year_cat if insample==1, vce(cluster country_id)
estimates save "poverty_spec3b", replace  

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Poverty_spec3")


estimates use "poverty_spec3"


ereturn display
matrix T = r(table)
matrix B=T[1,1..7]
putexcel B2 = matrix(B')
matrix B=T[1,8]
matrix list B 
putexcel B10 = matrix(B')


foreach col_idx of numlist 1/8 {
	local row = `col_idx'+1
	if `col_idx'==8 {
		local row=10
	}
local p = T[4,`col_idx']
	if `p' < 0.05 {
        putexcel B`row', bold
    }
}

local row=`row'+2 
putexcel b`row'=`=e(N)'

mi extract 1, clear
regress dlnheadcount dZ_* dlnemp_pop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
local row=`row'+1 
putexcel b`row'=`=r(unique)'


estimates use "poverty_spec3b"


ereturn display
matrix T = r(table)
matrix B=T[1,1..7]
putexcel C2 = matrix(B')
matrix B=T[1,8]
matrix list B 
putexcel C10 = matrix(B')


foreach col_idx of numlist 1/8 {
	local row = `col_idx'+1
	if `col_idx'==8 {
		local row=10
	}
local p = T[4,`col_idx']
	if `p' < 0.05 {
        putexcel C`row', bold
    }
}

local row=`row'+2 
putexcel C`row'=`=e(N)'

regress lnheadcount Z_* lnemp_pop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
local row=`row'+1 
putexcel C`row'=`=r(unique)'




exit 