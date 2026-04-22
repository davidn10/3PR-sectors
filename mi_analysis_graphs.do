clear 

putexcel set "D:\david\3PR\output\results_macro.xlsx", modify sheet("Figures")
use "../data/sectors_pip", replace 
unique country_code 
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

keep if sharetAgribusiness<. & sharetHealth<. & sharetTrade<. 
unique country_code 

drop sharetNoTourSplit sharetNontourism
su sharet* 


gen tourism_plus_other = max(sharetTourism,0) + sharetOthernonag
gen tourism_within = sharetTourism / tourism_plus_other
gen male_within_Tourism=employmTourism/employtTourism 
gen male_within_Othernonag=employmOthernonag/employtOthernonag if sharetTourism<. 


local sectors "InfraEnergy Agribusiness AgricSE Health Tourism Manufac Othernonag Trade"
foreach sector in `sectors' {
	gen lnempt`sector'=log(employt`sector')
	replace lnempt`sector'=ln(0.001) if employt`sector'==0
}
gen lnpopulation=log(population)
gen lnwap=log(wap)


mi set wide
mi register imputed tourism_within
mi register imputed male_within_Tourism male_within_Othernonag 
mi register passive sharemTourism sharefTourism sharemOthernonag sharefOthernonag 

mi register passive sharetTourism sharetOthernonag lnemptTourism lnemptOthernonag 
mi register regular headcount lngdp poverty_gap lnpop `sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetManufac sharetOthernonag sharetTrade'




mi impute chained /// 
    (truncreg, ll(0) ul(1)) tourism_within ///
	(truncreg, ll(0) ul(1)) male_within_Tourism /// 
	(truncreg, ll(0) ul(1)) male_within_Othernonag ///
	= headcount poverty_gap lngdp lnpop lnwap sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth sharetManufac ///
    i.region_id i.year, ///
    add(100) rseed(12345)

mi passive: replace sharetTourism = tourism_within * tourism_plus_other	
mi passive: replace sharetOthernonag = (1 - tourism_within) * tourism_plus_other
mi passive: replace sharetOthernonag = 1 - (sharetTourism + sharetInfraEnergy ///
    + sharetAgribusiness + sharetAgricSE + sharetHealth ///
    + sharetManufac + sharetTrade)

gen share_emp_f=totemployf/totemployt	
mi passive: replace sharemTourism = male_within_Tourism * sharetTourism / (1-share_emp_f) 
mi passive: replace sharefTourism = (1-male_within_Tourism) * sharetTourism / share_emp_f 

mi passive: replace sharemOthernonag = male_within_Othernonag * sharetOthernonag / (1-share_emp_f) 
mi passive: replace sharefOthernonag = (1-male_within_Othernonag) * sharetOthernonag / share_emp_f 

mi passive: replace lnemptTourism=log(sharetTourism*totemployt)
mi passive: replace lnemptOthernonag=log(sharetOthernonag*totemployt)

foreach gender in t m f {	
	egen mean_share`gender'Tourism = rowmean(_*_share`gender'Tourism)
	egen mean_share`gender'Othernonag=rowmean(_*_share`gender'Othernonag)
} 
	
		
local options "degree(1) bwidth(0.5) lwidth(medthick)"
local color1 "color(ebblue)"
local color2 "color(forest_green)"	
local color3 "color(lime*0.3)"
local color4 "color(cranberry)"
local color5 "color(orange)"
local color6 "color(purple)"
local color7 "color(cranberry*0.2) "
local color8 "color(ebblue*0.2)"
	
su mean* 	

lpoly sharetAgricSE lngdp, generate(sharetAgricSEhat) nograph degree(1) bwidth(0.5) at(lngdp)		
replace sharetAgricSEhat=. if sharetAgricSEhat>0.6 
/*	
twoway ///     
    (lpoly sharetInfraEnergy lngdp, `options' `color1')      ///
    (lpoly sharetAgribusiness  lngdp, `options' `color2')       ///
	(lpoly sharetAgricSE  lngdp, `options' `color3' lpattern(dash))       ///
    (lpoly sharetHealth lngdp, `options' `color4')     ///
    (lpoly mean_sharetTourism lngdp, `options' `color5')    ///
    (lpoly sharetManufac lngdp, `options' `color6')   ///
	(lpoly mean_sharetOthernonag lngdp, `options' `color7' lpattern(dash))   ///
	(lpoly sharetTrade lngdp, `options' `color8' lpattern(dash))   ///
	(histogram lngdp, fraction color(gs12%50) gap(10)), ///
     legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
	xlabel(6.9 "1000" 8.5 "5000" 9.2 "10000" 10.1 "25000" 10.8 "50000") ///
    ytitle("Employment Share (%)") xtitle("GDP per capita") ylabel(0(0.)0.6) saving(gdp_employment, replace)
*/ 

twoway ///     
    (lpoly sharetInfraEnergy lngdp, `options' `color1')      ///
    (lpoly sharetAgribusiness  lngdp, `options' `color2')       ///
	(line sharetAgricSEhat  lngdp, sort  `color3' lwidth(medthick) lpattern(dash))       ///
    (lpoly sharetHealth lngdp, `options' `color4')     ///
    (lpoly mean_sharetTourism lngdp, `options' `color5')    ///
    (lpoly sharetManufac lngdp, `options' `color6')   ///
	(lpoly mean_sharetOthernonag lngdp, `options' `color7' lpattern(dash))   ///
	(lpoly sharetTrade lngdp, `options' `color8' lpattern(dash))   ///
	(histogram lngdp, fraction color(gs12%50) gap(10)), ///
     legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
	xlabel(6.9 "1000" 8.5 "5000" 9.2 "10000" 10.1 "25000" 10.8 "50000") ///
    ytitle("Employment Share (%)") xtitle("GDP per capita") ylabel(0(0.1)0.6) saving(gdp_employment, replace)	
	


graph export "D:\david\3PR\output\emp_gdp.png", replace 	
putexcel A10 = image("D:\david\3PR\output\emp_gdp.png")	


local options "degree(1) bwidth(0.1) lwidth(medthick)"
lpoly sharetAgricSE headcount, generate(sharetAgricSEhat2) nograph degree(1) bwidth(0.1)	at(headcount)
replace sharetAgricSEhat2=. if sharetAgricSEhat2>0.6 

/*
twoway ///     
    (lpoly sharetInfraEnergy headcount, `options' `color1')      ///
    (lpoly sharetAgribusiness headcount, `options' `color2')       ///
	(lpoly sharetAgricSE headcount, `options' `color3' lpattern(dash))       ///
    (lpoly sharetHealth headcount, `options' `color4')     ///
    (lpoly mean_sharetTourism headcount, `options' `color5')    ///
    (lpoly sharetManufac headcount, `options' `color6')   ///
	(lpoly mean_sharetOthernonag headcount, `options' `color7' lpattern(dash))   ///
	(lpoly sharetTrade headcount, `options' `color8' lpattern(dash)) ///
	(histogram headcount, fraction color(gs12%50) gap(10)), ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
    ytitle("Employment Share (%)") xtitle("Headcount poverty rate") saving(poverty_employment, replace)	xscale(reverse)
*/ 

twoway ///     
    (lpoly sharetInfraEnergy headcount, `options' `color1')      ///
    (lpoly sharetAgribusiness headcount, `options' `color2')       ///
	(line sharetAgricSEhat2 headcount,  sort `color3' lwidth(medthick) lpattern(dash))       ///
    (lpoly sharetHealth headcount, `options' `color4')     ///
    (lpoly mean_sharetTourism headcount, `options' `color5')    ///
    (lpoly sharetManufac headcount, `options' `color6')   ///
	(lpoly mean_sharetOthernonag headcount, `options' `color7' lpattern(dash))   ///
	(lpoly sharetTrade headcount, `options' `color8' lpattern(dash)) ///
	(histogram headcount, fraction color(gs12%50) gap(10)), ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) ///
    ytitle("Employment Share (%)") xtitle("Headcount poverty rate") ylabel(0(0.1)0.6)  saving(poverty_employment, replace)	xscale(reverse)


	
graph export "D:\david\3PR\output\emp_pov.png", replace 	
putexcel A30 = image("D:\david\3PR\output\emp_pov.png")	


preserve 
collapse (mean) sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth  mean_sharetTourism sharetManufac mean_sharetOthernonag sharetTrade
local sectors_imptour "sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth mean_sharetTourism sharetManufac mean_sharetOthernonag sharetTrade"
graph pie `sectors_imptour', ///
    legend(order(1 "Infrastructure" 2 "Agribusiness" 3 "SE Agric" 4 "Health" 5 "Tourism" 6 "Manufacturing" 7 "Other non-ag" 8 "Retail Trade")) plabel(_all percent, format(%4.1f) size(medlarge)) ///
    pie(1, explode `color1')       ///
    pie(2, explode `color2')       ///
    pie(3, `color3')              ///
    pie(4, explode `color4')    ///
    pie(5, explode `color5')          ///
    pie(6, explode `color6')          ///
    pie(7, `color7')           ///
    pie(8, `color8')    ///	
	saving("pie_chart_employment_share", replace)
restore

graph export "D:\david\3PR\output\emp_share.png", replace 	
putexcel A50 = image("D:\david\3PR\output\emp_share.png")

 
 save "../data/mi_data", replace 
