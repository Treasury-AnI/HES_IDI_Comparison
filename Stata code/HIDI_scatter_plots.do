clear all
set more off
version 14.0
local gtype emf
local doname HIDI_scatter_plots

cap log close
log using "${LOGS}/`doname' `c(current_date)'" , replace

use "${INTDATA}/comparison_full.dta", clear

order _all , alpha

local gtype emf

replace hes_per_hes_year_code = substr(hes_per_hes_year_code,-2,.)
replace hes_per_hes_year_code = "20" + hes_per_hes_year_code

destring  hes_per_hes_year_code , replace


label var hes_overall_new "HES overall income"
label var ird_overall_new "IRD overall income"
label var hes_wages "HES wages and salaries"
label var ird_wages "IRD wages and salaries"
label var hes_wages_and_self "HES wage and self-employment income"
label var ird_wages_and_self "IRD wage and self-employment income"
label var hes_pen "HES govt. pension income"
label var ird_pen "IRD govt. pension income"
label var ird_self "IRD self-employment income"
label var hes_self "HES self-employment income"
label var hes_rent "HES rental income"
label var ird_s03 "IRD rental income"


cap prog drop inc_scatter 
prog define inc_scatter 

	version 14.0
	
	syntax varlist (numeric min=2 max=2) , sub_samp(numlist >0 <=1 min=1 max=1) [extra_note(string asis) tisize(string) extra_if(string) max_value(numlist max=1) min_value(numlist max=1) step_size(numlist max =1) gname(string)]
	
	tokenize `varlist'
	local yvar  `1'
	local xvar  `2'
	di "yvar = `yvar' "
	di "xvar = `xvar' "
	
	local ytitle : variable label `yvar'
	local ytitle `ytitle' (thousands)
	
	local xtitle : variable label `xvar'
	local xtitle `xtitle' (thousands)
	if "`gname'" != "" local gname ", name(`gname')"
	if "`tisize'" == "" local tisize medsmall 
	if "`max_value'" == "" local max_value 120
	if "`step_size'" == "" local step_size 20
	if "`min_value'" == "" local min_value 0
	
	local ran_percent = `sub_samp'

	corr `yvar' `xvar'  if 1==1 `extra_if'
	local corr_un = round(`r(rho)' , 0.01) 
	local corr_un : di %3.2f = `corr_un'
	di `corr_un'

	corr `yvar' `xvar' if `yvar' > 1 & `xvar' > 1 `extra_if' 
	local corr_conditional = round(`r(rho)' , 0.01)
	local corr_conditional : di %3.2f = `corr_conditional'
	di `corr_conditional'

	tempvar xvar_jit
	tempvar yvar_jit

	gen `xvar_jit' = `xvar' + -150 + 300*runiform()
	gen `yvar_jit' = `yvar' + -150 + 300*runiform()

	replace `xvar_jit' = `xvar_jit'/1000
	replace `yvar_jit' = `yvar_jit'/1000


	twoway (scatter `yvar_jit' `xvar_jit' ///
				if `xvar' >= `=1000* `min_value' ' & ///
				`yvar' >= `=1000* `min_value' ' & ///
				`xvar' <= `= 1000* `max_value' ' & ///
				`yvar' <= `= 1000* `max_value' ' & runiform() < `ran_percent' `extra_if'  ///
				, xti("`xtitle'" , size(`tisize')) ///
				yti("`ytitle'" , size(`tisize')) ///
				yscale(range(`min_value' `max_value') noextend) ///
				ylabel(`min_value'(`step_size')`max_value' , labsize(small)) ///
				 ///
				xlabel(`min_value'(`step_size')`max_value' , labsize(small)) ///
				xscale(range(`min_value' `max_value') noextend)  ///
				mcolor(ebblue) ///
				msize(small) ///
				msymbol(Oh) ///
				legend(off) ///
				note("`extra_note'The correlation coefficient is `corr_un'." ///
				"The correlation, conditional on positive income in both data sets, is `corr_conditional'. " ///
						"Data have been confidentialised: outliers have been removed, the underyling data jittered," ///
						"and only a `=`ran_percent'*100 '% random sample shown.") ///
						) ///
			(line `xvar_jit' `xvar_jit' if `xvar_jit' > `min_value' & `xvar_jit' < `max_value', lcolor(ebblue)  ) `gname' 

end 

inc_scatter hes_overall_new ird_overall_new , sub_samp(0.05) extra_note(Only includes income from comparable sources. ) gname(overall)
graph export "${RESULTS}/overall income scatter.`gtype'" , replace

inc_scatter hes_wages ird_wages , sub_samp(0.05) gname(wages)
graph export "${RESULTS}/wages scatter.`gtype'" , replace

inc_scatter hes_wages_and_self ird_wages_and_self , sub_samp(0.05) tisize("small") gname(wages_self)
graph export "${RESULTS}/wages_and_self_scatter.`gtype'" , replace

inc_scatter hes_pen ird_pen , sub_samp(0.2) extra_if("& hes_per_hes_year_code == 2015") extra_note(Only includes the HES 14/15 sample. ) gname(pensions) max_value(25) step_size(5)
graph export "${RESULTS}/pensions scatter.`gtype'" , replace

inc_scatter hes_self ird_self , sub_samp(0.05) gname(self) min_value(-40)
graph export "${RESULTS}/self scatter.`gtype'" , replace

inc_scatter hes_rent ird_s03 , sub_samp(0.05) gname(rent) 
graph export "${RESULTS}/rent scatter.`gtype'" , replace
