use "D:\david\3PR\data\GMD\processed\ago_2018.dta", replace 

bys ind_2d: keep if _n==1 
list ind_2d industry_orig, clean noobs 