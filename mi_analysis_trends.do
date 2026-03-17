clear 

use "../data/mi_data", replace 
local sectors "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetTourism sharetManufac sharetOthernonag sharetTradenonvehicle"

misstable summarize `sectors'
su `sectors'


*mi estimate, post cmdok dots: fmlogit `sectors', eta(ib5.year_cat i.country_id lnpop) 
*estimates store fmlogit
*estimates save "fmlogit", replace  
estimates use "fmlogit"

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Trends")

local sectors "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetTourism sharetManufac sharetOthernonag sharetTradenonvehicle"
local row=2
foreach sector of varlist `sectors' {
	dis "`sector'"
	estimates use "fmlogit"  
	* margins ,dydx(i.year_cat) predict(outcome(`sector')) post 
	mimrgns ,dydx(i.year_cat) predict(outcome(`sector')) post 
	ereturn display
	matrix T = r(table)
	matrix b=T[1,1...]

	putexcel b`row'=matrix(e(b))
	local col=66 
	foreach col_idx of numlist 1/4 {
		
		local p = T[4,`col_idx']
		if `p' < 0.05 {
			putexcel `=char(`col')'`row', bold
		}
		local col=`col'+1
	}
	local row=`row'+1 
}

