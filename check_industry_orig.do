 cd "D:\david\3PR\programs"
 * List all files matching a pattern
local files: dir "D:\david\3PR\data\GMD\country" files "*.dta"
local n : list sizeof files 
dis "`n' surveys total"


foreach f of local files {
     qui des using D:\david\3PR\data\GMD\country/`f', varlist 
	 local vars `r(varlist)'
	  local found 0
		foreach v of local vars {
			if "`v'" == "industry_orig" {
				local found 1
			}
		}
    
    if `found' {
        local matched "`matched' `f'"
    }
} 

local n : list sizeof matched
dis "`n' surveys with industry_orig" 
dis "`matched'"
local matched2 "`matched'"
foreach f of local matched {
	qui use "D:\david\3PR\data\GMD\country/`f'", replace 
    quietly count if !missing(industry_orig)
	if r(N)==0 {
		local matched2 : list matched2 - f
	}
} 

local n : list sizeof matched2
dis "`n' surveys with non-missing industry_orig" 


dis "`matched2'"
local matched3 "`matched2'"


foreach f of local matched2 {
	qui use "D:\david\3PR\data\GMD\country/`f'", replace 
	qui unique industry_orig 
	if r(unique)<50 {
		local matched3 : list matched3 - f
	}
}

local n : list sizeof matched3
dis "`n' surveys with non-missing industry_orig with more than 50 categories" 
global matched "`matched3'"

*/ 

local n : word count $matched
clear
set obs `n'
gen survey = ""

forvalues i = 1/`n' {
    local item : word `i' of $matched 
    replace survey = "`item'" in `i'
}
list survey, clean noobs 
xx



** extract 2 digit code when possible 
clear 
local i=1 
foreach file of global matched {
	qui use "D:\david\3PR\data\GMD\country/`file'", replace 
	local vartype : type industry_orig 
	dis "`industy_orig'"
	if `i'==10 {
		dis "`vartype'"
		continue, break 
	}
	if substr("`vartype'",1,3)=="str" {
		gen category =  substr(industry_orig, 1, strpos(industry_orig,"-") - 1)
		replace category=industry_orig if strpos(industry_orig,"-")==0 
		replace category="0"+category if real(category)<10000  & real(category)>=1000 
		* replace category="0"+category if real(category)<10 
		gen ind_2d=substr(category,1,2)
	}
	
	
	
	keep countrycode hhid* pid* year industry_orig ind_2d 
	
	local ++i 
	
	
	
	save "..\data/GMD\processed/`file'", replace 
	
	
	
	
}

