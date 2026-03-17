*1. Fixed effect regressions with time trends 
use "../data/sectors_pip", replace 
drop if year==2025 
recode year (1990/1994=1 "1990-1994") (1995/1999=2 "1995-1999") (2000/2004=3 "2000-2004") (2005/2009=4 "2005-2009") (2010/2014=5 "2010-2014") (2015/2019=6 "2015-2019") (2020/2024=7 "2020-2024"), gen(year_cat)

egen Nobs=sum(1), by(country_code)
gen wt=1/(Nobs-1)
count if sharetTourism==. & headcount<. 
encode country_code, gen(country_id)
foreach var of varlist sharetTourism sharetAgribusiness sharetAgricSE sharetHealth sharetInfraEnergy sharetManufac {
	dis "`var'"
	drop if `var'==. 
}

gen lnpop=log(population)
gen lngdp=log(gdp)
tab country_code if lngdp==. 

local sectors "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetTourism sharetManufac sharetOthernonag sharetRetailtradenonvehicle"
local Nsectors=8 

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Figures")

local options "degree(1) bwidth(0.5) lwidth(medthick)"

** descriptive graph: Emmployment shares vs. GDP level 
sort lngdp 



twoway ///     
    (lpoly sharetInfraEnergy lngdp, `options')      ///
    (lpoly sharetAgribusiness  lngdp, `options')       ///
	(lpoly sharetAgricSE  lngdp, `options')       ///
    (lpoly sharetHealth lngdp, `options')     ///
    (lpoly sharetTourism lngdp, `options')    ///
    (lpoly sharetManufac lngdp, `options')   ///
	(lpoly sharetOthernonag lngdp, `options')   ///
	(lpoly sharetRetailtradenonvehicle lngdp, `options')   ///
	(histogram lngdp, fraction color(gs12%50) gap(10)), ///
     legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
	xlabel(6.9 "1000" 8.5 "5000" 9.2 "10000" 10.1 "25000" 10.8 "50000") ///
    ytitle("Employment Share (%)") xtitle("GDP per capita") saving(gdp_employment, replace)

	
local options "degree(1) bwidth(0.05) lwidth(medthick)"
	
	
graph export "D:\david\3PR\output\emp_gdp.png", replace 	
putexcel A10 = image("D:\david\3PR\output\emp_gdp.png")
	
twoway ///     
    (lpoly sharetInfraEnergy headcount, `options')      ///
    (lpoly sharetAgribusiness headcount, `options')       ///
	(lpoly sharetAgricSE headcount, `options')       ///
    (lpoly sharetHealth headcount, `options')     ///
    (lpoly sharetTourism headcount, `options')    ///
    (lpoly sharetManufac headcount, `options')   ///
	(lpoly sharetOthernonag headcount, `options')   ///
	(lpoly sharetRetailtradenonvehicle headcount, `options') ///
	(histogram headcount, fraction color(gs12%50) gap(10)), ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
    ytitle("Employment Share (%)") xtitle("Headcount poverty rate") saving(poverty_employment, replace)	xscale(reverse)
	
	
graph export "D:\david\3PR\output\emp_pov.png", replace 	
putexcel A30 = image("D:\david\3PR\output\emp_pov.png")	
	
preserve 
collapse (mean) `sectors' 
graph pie `sectors', ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) plabel(_all percent, format(%4.1f) size(medlarge)) saving("pie_chart_employment_share", replace)
restore	
	
graph export "D:\david\3PR\output\emp_share.png", replace 	
putexcel A50 = image("D:\david\3PR\output\emp_share.png")		
	

su share* 
egen a= rowtotal(sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetTourism sharetManufac sharetOthernonag sharetRetailtradenonvehicle)
su a, d

fmlogit `sectors', eta(ib5.year_cat i.country_id lnpop)

estimates store fmlogit 
*matrix m1 = r(table)'
*matrix list m1 

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Trends")

local row=2
foreach sector of varlist `sectors' {
	estimates restore fmlogit 
	margins ,dydx(i.year_cat) predict(outcome(`sector')) post 
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



local row=`row'+1 
putexcel b`row'=`=e(N)'
unique country_code if e(sample)
local row=`row'+1 
putexcel b`row'=`=r(unique)'



putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("GDP")
regress lngdp  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)

ereturn display
matrix T = r(table)
local Nsectorsm1=`Nsectors'-1 

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
unique country_code if e(sample)
local row=`row'+1 
putexcel b`row'=`=r(unique)'


putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Poverty")
fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)
margins ,dydx(sharet*) post 

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
unique country_code if e(sample)
local row=`row'+1 
putexcel b`row'=`=r(unique)'

exit 

fracreg probit headcount lnpop sharef* i.country_id i.year_cat, vce(cluster country_id)
margins ,dydx(sharef*)

fracreg probit headcount lnpop sharem* i.country_id i.year_cat, vce(cluster country_id)
margins ,dydx(sharem*)
