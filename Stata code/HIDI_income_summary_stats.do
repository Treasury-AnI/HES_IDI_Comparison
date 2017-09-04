clear all
set more off
version 14.0

local doname HIDI_income_summary_stats

cap log close
log using "${LOGS}/`doname' `c(current_date)'" , replace

use "${INTDATA}/comparison_full.dta", clear

order _all , alpha

compress


replace hes_per_hes_year_code = substr(hes_per_hes_year_code,-2,.)
replace hes_per_hes_year_code = "20" + hes_per_hes_year_code

destring  hes_per_hes_year_code , gen(year)

preserve

keep if ird_linked == 1
regress ird_overall_new i.year , nocons
margins i.year
marginsplot
regress hes_overall_new i.year , nocons
margins i.year
marginsplot

label var ird_overall_new "IRD income"
label var hes_overall_new "HES income"

collapse 	(mean) mean_ird = ird_overall_new  mean_hes=hes_overall_new ///
					mean_ird_wage = ird_wages mean_hes_wage=hes_wages ///
					mean_ird_self = ird_self mean_hes_self= hes_self ///
			(median) median_ird=ird_overall_new median_hes=hes_overall_new ///
						median_ird_wage = ird_wages median_hes_wage=hes_wages ///
			(count) count_ird = ird_overall_new  count_hes = hes_overall_new , by(year)

replace mean_ird = round(mean_ird, 1) 
replace mean_hes = round(mean_hes , 1)
replace median_ird = round(median_ird, 1)
replace median_hes = round(median_hes, 1)
replace mean_ird_wage = round(mean_ird_wage, 1)
replace mean_hes_wage = round(mean_hes_wage, 1)
replace median_ird_wage = round(median_ird_wage, 1)
replace median_hes_wage = round(median_hes_wage, 1)
replace mean_ird_self = round(mean_ird_self, 1)
replace mean_hes_self = round(mean_hes_self, 1)

export excel using "${RESULTS}/aggregate_comps.xlsx", firstrow(variables) replace sheet("all inc zero")


set scheme s1color

twoway (connected mean_ird year) (connected mean_hes year) ///
	, ytitle("Mean income") ///
	 xtitle("Year") ///
	ti("Mean income by source over year") 
	
restore

preserve

keep if ird_linked == 1
keep if abs(ird_overall_new) > 1 & abs(hes_overall_new) > 1

regress ird_overall_new i.year , nocons
margins i.year
marginsplot
regress hes_overall_new i.year , nocons
margins i.year
marginsplot

label var ird_overall_new "IRD income"
label var hes_overall_new "HES income"

collapse 	(mean) mean_ird_cond = ird_overall_new  mean_hes_cond=hes_overall_new ///
			(median) median_ird_cond=ird_overall_new median_hes_cond=hes_overall_new ///
			(count) count_ird_cond = ird_overall_new  count_hes = hes_overall_new , by(year)

replace mean_ird_cond = round(mean_ird_cond, 1) 
replace mean_hes_cond = round(mean_hes_cond , 1)
replace median_ird_cond = round(median_ird_cond , 1)
replace median_hes_cond = round(median_hes_cond , 1)

export excel using "${RESULTS}/aggregate_comps.xlsx", firstrow(variables) sheet("conditional_overall_income") sheetreplace


set scheme s1color

twoway (connected mean_ird year) (connected mean_hes year) ///
	, ytitle("Mean income") ///
	 xtitle("Year") ///
	ti("Mean income by source over year") 
	
restore

preserve

gen ln_hes_overall_new = ln(hes_overall_new) 
gen ln_ird_overall_new = ln(ird_overall_new)
gen ln_diff_overall_new = ln_hes_overall_new - ln_ird_overall_new 
gen abs_ln_diff = abs(ln_hes_overall_new - ln_ird_overall_new)

gen pct_diff_hes_den = 100*(hes_overall_new - ird_overall_new)/(hes_overall_new)
gen pct_diff_ird_den = 100*(hes_overall_new - ird_overall_new)/(ird_overall_new)

inspect year
local unique_N = `r(N_unique)'
di "** `unique_N'"
tabstat ln_hes_overall_new ln_ird_overall_new ln_diff_overall abs_ln_diff pct_diff_ird_den pct_diff_hes_den if ird_linked == 1 & hes_overall_new > 1 &ird_overall_new > 1 , statistics(mean sd count) by(hes_per_hes_year) save
mat list r(StatTotal)
forvalues i=1/`unique_N' {
	di "`i'"
	mat A = r(Stat`i')
	di"**"
	
	mat rownames  A = "`r(name`i')'"
	mat list A
	
	if `i' == 1 mat B = A
	else mat B = (B \ A)
}
mat B = (B \ r(StatTotal)) 
mat list B
putexcel L1=matrix(B, names) using "${RESULTS}/aggregate_comps.xlsx", sheet("conditional_overall_income") modify


restore 

preserve

keep if ird_linked == 1
keep if abs(ird_wages) > 1 & abs(hes_wages) > 1

regress ird_overall_new i.year , nocons
margins i.year
marginsplot
regress hes_overall_new i.year , nocons
margins i.year
marginsplot

label var ird_overall_new "IRD income"
label var hes_overall_new "HES income"

collapse 	(mean) mean_ird_wages_cond = ird_wages  mean_hes_wages_cond=hes_wages ///
			(median) median_ird_wages_cond=ird_wages median_hes_wages_cond=hes_wages ///
			(count) count_ird_cond = ird_wages  count_hes = hes_wages , by(year)

replace mean_ird_wages_cond = round(mean_ird_wages_cond, 1) 
replace mean_hes_wages_cond = round(mean_hes_wages_cond , 1)
replace median_ird_wages_cond = round(median_ird_wages_cond , 1)
replace median_hes_wages_cond = round(median_hes_wages_cond , 1)

export excel using "${RESULTS}/aggregate_comps.xlsx", firstrow(variables) sheet("conditional_wages") sheetreplace


set scheme s1color

twoway (connected mean_ird year) (connected mean_hes year) ///
	, ytitle("Mean income") ///
	 xtitle("Year") ///
	ti("Mean income by source over year") 
	
restore

foreach var in ird_w_s ird_self {
	tempvar pc_`var'
	gen `pc_`var'' = `var'/sumird
	di "`var' ** `pc_`var''"
	su `pc_`var'' , detail 

}

local allird ird_wages ird_ben ird_c00 ird_c01 ird_c02 ird_clm ird_p00 ird_p01 ird_p02 ird_pen ird_ppl ird_s00 ird_s01 ird_s02 ird_s03 ird_stu

foreach var in `allird' {
	su `var'
}

egen test = rowtotal(`allird')

local allird `allird' sumird ird_overall_new

cap prog drop custom_sumtable 
prog define custom_sumtable 

	version 14.0
	
	syntax varlist (numeric) 
	
	local numvars : word count `varlist'
	matrix A= J(`numvars'*2,4,.) 
		
	local i = 1

	 foreach var in `varlist' {
		tempvar `var'_ind
		gen ``var'_ind' = 0
		replace ``var'_ind' = 1 if abs(`var') > 1 & `var' < .
		replace ``var'_ind' = . if ird_linked == 0
		
		quietly: sum `var' if ird_linked == 1 , detail
		matrix A[`i',1] = round(r(mean),1)
		matrix A[`i' + 1,1] = round(r(sd),1)
		
		quietly: sum ``var'_ind' if ird_linked == 1 , detail
		matrix A[`i',2] = round(r(mean), .001)
				
		quietly: sum `var' if ird_linked == 1
		matrix A[`i',4] =  r(N)
		
		quietly: sum `var' if ird_linked == 1 & abs(`var') > 1
		matrix A[`i',3] =  round(r(mean),1)
		
		local i = `i' + 2
	}
		

	mat colnames A = "Means/SEs" "Proportion with absval > 1" "Conditional mean" "N"
	local rownames

	foreach name in `varlist' {
		local rownames "`rownames' `name' SD"
	}
		
	di "`rownames'"
	mat rownames A = `rownames'
	mat list A
 
end


custom_sumtable `allird'

putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/`round'/aggregate_comps.xlsx", sheet("ird_summary_stats")modify

local key_hes_vars sumhes hes_overall_new  hes_wages hes_self hes_wages_and_self hes_pensions hes_ppl hes_stu hes_rent
custom_sumtable `key_hes_vars'

putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/`round'/aggregate_comps.xlsx", sheet("hes_summary_stats")modify

local varlist hes_overall_new ird_overall_new hes_wages ird_wages hes_self ird_self hes_wages_and_self ird_wages_and_self 
foreach var in `varlist' {
	gen `var'_ind = 0
	replace `var'_ind = 1 if abs(`var') > 1 & `var' < .
	replace `var'_ind = . if ird_linked == 0
}

tab hes_overall_new_ind ird_overall_new_ind , matcell(A)
mat rownames A = "No HES income" "Has HES income"
mat colnames A = "No IRD income" "Has IRD income"
matrix A[1,1] =round( A[1,1], 50)
matrix A[1,2] =round( A[1,2], 50)
matrix A[2,1] =round( A[2,1], 50)
matrix A[2,2] =round( A[2,2], 50)


putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/`round'/aggregate_comps.xlsx", sheet("income indicator tabs") modify

tab hes_wages_ind ird_wages_ind , matcell(A)
mat rownames A = "No HES wages" "Has HES wages"
mat colnames A = "No IRD wages" "Has IRD wages"

matrix A[1,1] =round( A[1,1], 50)
matrix A[1,2] =round( A[1,2], 50)
matrix A[2,1] =round( A[2,1], 50)
matrix A[2,2] =round( A[2,2], 50)

putexcel  F2=matrix(A, names) using "${RESULTS}/aggregate_comps.xlsx", sheet("income indicator tabs") modify

tab hes_self_ind ird_self_ind  , matcell(A)
mat rownames A = "No HES self-employment income" "Has HES self-employment income"
mat colnames A = "No IRD self-employment income" "Has IRD self-employment income"

matrix A[1,1] =round( A[1,1], 50)
matrix A[1,2] =round( A[1,2], 50)
matrix A[2,1] =round( A[2,1], 50)
matrix A[2,2] =round( A[2,2], 50)
putexcel  J2=matrix(A, names) using "${RESULTS}/aggregate_comps.xlsx", sheet("income indicator tabs") modify

tab hes_wages_and_self_ind ird_wages_and_self_ind  , matcell(A) matcol(B) matrow(C)
mat rownames A = "No HES wage or self income" "Has HES wage or self income"
mat colnames A = "NO IRD wage or self income " "Has IRD wage or self income"

matrix A[1,1] =round( A[1,1], 50)
matrix A[1,2] =round( A[1,2], 50)
matrix A[2,1] =round( A[2,1], 50)
matrix A[2,2] =round( A[2,2], 50)
putexcel  N2=matrix(A, names) using "${RESULTS}/aggregate_comps.xlsx", sheet("income indicator tabs") modify


cap log close
