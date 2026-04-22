clear 

use "../data/mi_data", replace 
local sectors "lnemptInfraEnergy lnemptAgribusiness lnemptAgricSE lnemptHealth lnemptTourism lnemptManufac lnemptOthernonag lnemptTrade"
local name_lnemptInfraEnergy "Infrastructure"
local name_lnemptAgribusiness "Agribusiness"
local name_lnemptAgricSE "Self-employed Agriculture"
local name_lnemptHealth "Health"
local name_lnemptTourism "Tourism"
local name_lnemptManufac "Manufacturing"
local name_lnemptOthernonag "Other non-ag"
local name_lnemptTrade "Retail trade"

local Nsectorsm1=7
local Nsectors=8 

* --- Regression with proper factor-variable interactions ---
local sectors "lnemptInfraEnergy lnemptAgribusiness lnemptAgricSE lnemptHealth lnemptTourism lnemptManufac lnemptOthernonag lnemptTrade"

egen avg_pov = mean(headcount), by(country_code)

* Build interaction list using factor notation
local sectors_fv ""
foreach s of local sectors {
    local sectors_fv "`sectors_fv' c.`s'##c.avg_pov"
}

/*
mi estimate, post cmdok dots: ///
    fracreg probit headcount `sectors_fv' lnpopulation i.country_id i.year_cat, ///
    vce(cluster country_id)
estimates save "poverty_interaction", replace 
*/ 
estimates use "poverty_interaction"

* --- Loop: one marginsplot per sector ---
* Pick a sensible range for avg_pov based on your data
summarize avg_pov, meanonly
local povmin = r(min)
local povmax = r(max)

/*
foreach s of local sectors {
	dis "`s'"
	estimates use "poverty_interaction"
    mimrgns, dydx(`s') at(avg_pov=(`povmin'(0.1)`povmax')) ///
        predict(cm) cmdmargins post 
	estimates save "mim_`s'", replace 	
    marginsplot, ///
        recast(line) recastci(rarea) ///
        ciopts(color(%30)) ///
        yline(0, lcolor(black) lpattern(dash)) ///
        title("`name_`s''") ///
		xtitle("") ///
		ytitle("") ///
		xlabel(0(0.1)0.8) ///
		xscale(reverse) /// 
        name(me_`s', replace)
    
	graph save "me_`s'", replace 
    graph export "me_`s'.png", replace
}
*/ 
*
foreach s of local sectors {
graph use "me_`s'"
}

* Combine all 8 into one figure
graph combine me_lnemptInfraEnergy me_lnemptAgribusiness me_lnemptAgricSE ///
    me_lnemptHealth me_lnemptTourism me_lnemptManufac ///
    me_lnemptOthernonag me_lnemptTrade, ///
    cols(2) ysize(11) xsize(8.5) ///
	b1title("Average poverty headcount") ///
	l1title("Estimated semi-elasticity of headcount poverty wrt employment") ///
	xcommon ycommon 

graph export "me_combined.png", replace

putexcel F2 = image("me_combined.png")
*/ 

local row=3
foreach s of local sectors {
	estimates use "mim_`s'"
	ereturn display 
	matrix T=r(table)
	matrix list T 
	matrix B=T[1,1...]
	matrix list B
	mata: st_matrix("B", st_matrix("B")[., cols(st_matrix("B"))..1])
	matrix list B 
	matrix B=B'
	putexcel B`row'=matrix(B)
	foreach col_idx of numlist `Nsectors'/1 {
		local p = T[4,`col_idx']
		if `p' < 0.05 {
			putexcel B`row', bold
		}
		local row = `row' + 1
	}	
	local row=`row'+2
}




local row=`row'+2 
putexcel b`row'=`=e(N)'
local row=`row'+1

preserve 
mi extract 1, clear
fracreg probit headcount  `sectors' lnpop i.country_id i.year_cat, vce(cluster country_id)
unique country_code if e(sample)
putexcel b`row'=`=r(unique)'
restore 



** do poverty gap estimation — use factor-variable interactions
/*
mi estimate, post cmdok dots: ///
    fracreg probit poverty_gap `sectors_fv' lnpopulation i.country_id i.year_cat, ///
    vce(cluster country_id)
estimates save "poverty_gap", replace
*/ 
estimates use "poverty_gap"
/*
* --- Loop: one marginsplot per sector for poverty gap ---
foreach s of local sectors {
    dis "`s'"
	estimates use "poverty_gap"
    mimrgns, dydx(`s') at(avg_pov=(`povmin'(0.1)`povmax')) ///
        predict(cm) cmdmargins post 
    estimates save "mim_gap_`s'", replace 
    marginsplot, ///
        recast(line) recastci(rarea) ///
        ciopts(color(%30)) ///
        yline(0, lcolor(black) lpattern(dash)) ///
        title("`name_`s''") ///
        xtitle("") ///
        ytitle("") ///
        xlabel(0(0.1)0.8) ///
        xscale(reverse) ///
        name(me_gap_`s', replace)
    
	graph save me_gap_`s', replace 
    graph export "me_gap_`s'.png", replace
}
*/ 
foreach s of local sectors {
graph use "me_gap_`s'"
}

* Combine all 8 into one figure
graph combine me_gap_lnemptInfraEnergy me_gap_lnemptAgribusiness me_gap_lnemptAgricSE ///
    me_gap_lnemptHealth me_gap_lnemptTourism me_gap_lnemptManufac ///
    me_gap_lnemptOthernonag me_gap_lnemptTrade, ///
    cols(2) ysize(11) xsize(8.5) ///
    b1title("Average poverty headcount") ///
    l1title("Estimated semi-elasticity of poverty gap wrt employment") ///
    xcommon ycommon

graph export "me_gap_combined.png", replace width(2000)

putexcel F40 = image("me_gap_combined.png")

local row=3
foreach s of local sectors {
	estimates use "mim_gap_`s'"
	ereturn display 
	matrix T=r(table)
	matrix list T 
	matrix B=T[1,1...]
	matrix list B
	mata: st_matrix("B", st_matrix("B")[., cols(st_matrix("B"))..1])
	matrix list B 
	matrix B=B'
	putexcel C`row'=matrix(B)
	foreach col_idx of numlist `Nsectors'/1 {
		local p = T[4,`col_idx']
		if `p' < 0.05 {
			putexcel C`row', bold
		}
		local row = `row' + 1
	}	
	local row=`row'+2
}

 
putexcel c`row'=`=e(N)'
 
 
 
preserve 
mi extract 1, clear
fracreg probit headcount  `sectors' i.country_id i.year_cat, vce(cluster country_id)
local row=`row'+1
unique country_code if e(sample)
putexcel c`row'=`=r(unique)'
restore 
 
 
/*
** output unweighted mean shares for each sector 
mean sharetInfraEnergy sharetAgribusiness sharetAgricSE sharetHealth mean_sharetTourism sharetManufac mean_sharetOthernonag sharetTrade 
matrix B=e(b)
putexcel d2=matrix(B')
*/ 


