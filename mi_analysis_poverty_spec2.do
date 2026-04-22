
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


mi estimate, post cmdok dots: regress lnheadcount Z_* lnemp_pop i.country_id i.year_cat, vce(cluster country_id)

estimates save "poverty_spec2", replace  
estimates use "poverty_spec2"

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Poverty_spec2")

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
regress lnheadcount Z_* lnemp_pop i.country_id i.year_cat, vce(cluster country_id)

unique country_code if e(sample)
local row=`row'+1 
putexcel b`row'=`=r(unique)'

exit 