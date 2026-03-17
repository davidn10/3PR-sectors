clear 

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("GDP")
use "../data/sectors_pip", replace 
drop if year==2025 
recode year (1990/1994=1 "1990-1994") (1995/1999=2 "1995-1999") (2000/2004=3 "2000-2004") (2005/2009=4 "2005-2009") (2010/2014=5 "2010-2014") (2015/2019=6 "2015-2019") (2020/2024=7 "2020-2024"), gen(year_cat)

egen Nobs=sum(1), by(country_code)
gen wt=1/(Nobs-1)
count if sharetTourism==. & headcount<. 
encode country_code, gen(country_id)
encode region_code, gen(region_id)
gen lnpop=log(population)
gen lngdp=log(gdp)
keep if lngdp<. 

keep if sharetAgribusiness<. & sharetHealth<. & sharetTradenonvehicle<. 
drop sharetNoTourSplit sharetNontourism
su sharet* 


gen tourism_plus_other = max(sharetTourism,0) + sharetOthernonag
gen tourism_within = sharetTourism / tourism_plus_other
gen male_within_Tourism=employmTourism/employtTourism 
gen male_within_Othernonag=employmOthernonag/employtOthernonag if sharetTourism<. 

mi set wide
mi register imputed tourism_within
mi register imputed male_within_Tourism male_within_Othernonag 
mi register passive sharemTourism sharefTourism sharemOthernonag sharefOthernonag 

mi register passive sharetTourism sharetOthernonag
mi register regular headcount lngdp poverty_gap lnpop `sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetManufac sharetOthernonag sharetTradenonvehicle'




local sectors "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetTourism sharetManufac sharetOthernonag sharetTradenonvehicle"
local sectorsnotourism "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetManufac sharetOthernonag sharetTradenonvehicle"


mi impute chained /// 
    (truncreg, ll(0) ul(1)) tourism_within ///
	(truncreg, ll(0) ul(1)) male_within_Tourism /// 
	(truncreg, ll(0) ul(1)) male_within_Othernonag ///
	= headcount poverty_gap lngdp lnpop ///
    i.region_id i.year, ///
    add(100) rseed(12345)

mi passive: replace sharetTourism = tourism_within * tourism_plus_other	
mi passive: replace sharetOthernonag = (1 - tourism_within) * tourism_plus_other
mi passive: replace sharetOthernonag = 1 - (sharetTourism + sharetInfraEnergy ///
    + sharetAgribusiness + sharetAgricSE + sharetHealth ///
    + sharetManufac + sharetTradenonvehicle)

gen share_emp_f=totemployf/totemployt	
mi passive: replace sharemTourism = male_within_Tourism * sharetTourism / (1-share_emp_f) 
mi passive: replace sharefTourism = (1-male_within_Tourism) * sharetTourism / share_emp_f 

mi passive: replace sharemOthernonag = male_within_Othernonag * sharetOthernonag / (1-share_emp_f) 
mi passive: replace sharefOthernonag = (1-male_within_Othernonag) * sharetOthernonag / share_emp_f 






	
foreach gender in t m f {	
	egen mean_share`gender'Tourism = rowmean(_*_share`gender'Tourism)
	egen mean_share`gender'Othernonag=rowmean(_*_share`gender'Othernonag)
} 
	
		
local options "degree(1) bwidth(0.5) lwidth(medthick)"
	
		
	
twoway ///     
    (lpoly sharetInfraEnergy lngdp, `options')      ///
    (lpoly sharetAgribusiness  lngdp, `options')       ///
	(lpoly sharetAgricSE  lngdp, `options')       ///
    (lpoly sharetHealth lngdp, `options')     ///
    (lpoly mean_sharetTourism lngdp, `options')    ///
    (lpoly sharetManufac lngdp, `options')   ///
	(lpoly mean_sharetOthernonag lngdp, `options')   ///
	(lpoly sharetTradenonvehicle lngdp, `options')   ///
	(histogram lngdp, fraction color(gs12%50) gap(10)), ///
     legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
	xlabel(6.9 "1000" 8.5 "5000" 9.2 "10000" 10.1 "25000" 10.8 "50000") ///
    ytitle("Employment Share (%)") xtitle("GDP per capita") saving(gdp_employment, replace)

	
	
	

graph export "D:\david\3PR\output\emp_gdp.png", replace 	
putexcel A10 = image("D:\david\3PR\output\emp_gdp.png")	

twoway ///     
    (lpoly sharetInfraEnergy headcount, `options')      ///
    (lpoly sharetAgribusiness headcount, `options')       ///
	(lpoly sharetAgricSE headcount, `options')       ///
    (lpoly sharetHealth headcount, `options')     ///
    (lpoly mean_sharetTourism headcount, `options')    ///
    (lpoly sharetManufac headcount, `options')   ///
	(lpoly mean_sharetOthernonag headcount, `options')   ///
	(lpoly sharetTradenonvehicle headcount, `options') ///
	(histogram headcount, fraction color(gs12%50) gap(10)), ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
    ytitle("Employment Share (%)") xtitle("Headcount poverty rate") saving(poverty_employment, replace)	xscale(reverse)

graph export "D:\david\3PR\output\emp_pov.png", replace 	
putexcel A30 = image("D:\david\3PR\output\emp_pov.png")	


preserve 
collapse (mean) `sectorsnotourism' mean_sharetTourism mean_sharetOthernonag
local sectors_imptour "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth mean_sharetTourism sharetManufac mean_sharetOthernonag sharetTradenonvehicle"
graph pie `sectors_imptour', ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) plabel(_all percent, format(%4.1f) size(medlarge)) saving("pie_chart_employment_share", replace)
restore

graph export "D:\david\3PR\output\emp_share.png", replace 	
putexcel A50 = image("D:\david\3PR\output\emp_share.png")

 
 save "../data/mi_data", replace 
