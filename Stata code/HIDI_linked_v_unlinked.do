clear all
set more off
version 14.0
local gtype emf
local doname HIDI_linked_v_unlinked_`round'

cap log close
log using "${LOGS}/`doname' `c(current_date)'" , replace

use "${INTDATA}/comparison_full.dta", clear

order _all , alpha

gen weird_link = 1 if sumird >= . & hes_linked != 0
label var weird_link "Linked to spine but not IRD (in HES year)"
tab hes_per_hes_year_code weird_link

gen hes_PPL = hes_inc_3_2_0_05
label var hes_PPL "HES measured Paid Parental Leave"

gen hes_STU = hes_inc_3_2_0_27	
label var hes_STU "HES measured Student Allowance"

label var hes_self "HES measured Self-employment income"

gen hes_UB = hes_inc_3_2_0_07
gen hes_SB = hes_inc_3_2_0_08
gen hes_DPB = hes_inc_3_2_0_09
gen hes_IB = hes_inc_3_2_0_10

label var hes_UB "Unemployment Benefit"
label var  hes_SB "Sickness Benefit"
label var hes_DPB "Domestic Purposes Benefit"
label var hes_IB "Invalids benefit"

gen hes_JSS = hes_inc_3_2_0_28
gen hes_SPS = hes_inc_3_2_0_29
gen hes_SLP = hes_inc_3_2_0_30

label var hes_JSS "Job Seeker Support"
label var hes_SPS "Sole Parent Support"
label var hes_SLP "Supported Living Payment"
 
foreach var in hes_JSS hes_SPS hes_SLP hes_UB hes_IB hes_SB hes_DPB {
	gen `var'_ind = 1 if `var' > 1 & `var' < .
	replace `var'_ind = 0 if ~(`var' > 1 & `var' < .)
}
compress

tab ird_linked

egen rtotal_eth = rowtotal(hes_per_ethnic_grp*)
replace hes_per_ethnic_grp6 = 1 if rtotal_eth == 0
drop rtotal_eth

rename hes_per_ethnic_grp1_snz_ind eth_euro
label var eth_euro "European"

rename hes_per_ethnic_grp2_snz_ind eth_maori
label var eth_maori "Maori"

rename hes_per_ethnic_grp3_snz_ind eth_pacific 
label var eth_pacific "Pacific Peoples"

rename hes_per_ethnic_grp4_snz_ind eth_asian
label var eth_asian "Asian"

rename hes_per_ethnic_grp5_snz_ind eth_eastern
label var eth_eastern "Middle Eastern/Lating American/African"

rename hes_per_ethnic_grp6_snz_ind eth_other
label var eth_other "Other ethnicity/undefined"

replace hes_per_hes_year_code = substr(hes_per_hes_year_code,-2,.)
replace hes_per_hes_year_code = "20" + hes_per_hes_year_code

destring  hes_per_hes_year_code , replace

tab hes_per_hes_year_code

cap prog drop sumtable 
prog define sumtable 

	version 14.0
	
	syntax varlist (numeric) , group(varlist numeric max=1)

	assert `group' == 0 |`group' == 1 | `group' >= .
	if `group' == . di as error "WARNING: group takes on missing values"
	
	
	local numvars : word count `varlist'
	matrix A= J(`numvars'*2,4,.) 
	
	di "`varlist'"
	local i = 1
	
	foreach var in `varlist' {
			
		quietly: sum `var' if `group' == 0, detail
		matrix A[`i',1] = round(r(mean),.001)
		matrix A[`i' + 1,1] = round(r(sd),0.001)
		
		quietly: sum `var' if `group' == 1, detail
		matrix A[`i',2] = round(r(mean), .001)
		matrix A[`i'+1,2] = round(r(sd),0.001)
		
		matrix A[`i', 3] = A[`i',1] - A[`i',2]
		
		ttest `var' , by(`group')
				
		matrix A[`i'+1,3] = round(r(p),0.001)
		
		quietly: sum `var' 
		matrix A[`i',4] =  r(N)
		
		local i = `i' + 2
		}
		
		mat list A
		
		mat colnames A = "Unlinked" "Linked" "Difference" "Nonmissing obs"
		local rownames
		foreach name in `varlist' {
			local rownames "`rownames' `name' SDSE"
		}

		di "`rownames'"
		mat rownames A = `rownames'
		mat list A
			
end 

local ethnicities eth_euro eth_maori eth_pacific eth_asian eth_eastern eth_other 

local new_ben_ind hes_JSS_ind hes_SPS_ind hes_SLP_ind 
local old_ben_ind hes_UB_ind hes_SB_ind hes_DPB_ind hes_IB_ind

local hes_incomes sumhes hes_overall_new hes_wages hes_self hes_rent hes_pensions hes_STU hes_PPL
local sumvars `hes_incomes'  hes_age female `ethnicities'

sumtable `sumvars' , group(ird_linked)

putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/Linked v Unlinked", sheet("All links")modify

preserve
keep if hes_per_hes_year_code == 2015
sumtable `new_ben_ind' , group(ird_linked)

putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/Linked v Unlinked", sheet("New benefits")modify

restore

preserve
keep if hes_per_hes_year_code <= 2013 
sumtable `old_ben_ind' , group(ird_linked)

putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/Linked v Unlinked", sheet("Old benefits")modify

restore

egen invest_inc = rowtotal(hes_inc_2* )
replace invest_inc = invest_inc - hes_inc_2_3_0_01 - hes_inc_2_5_0_03

bys ird_linked : su invest_inc

egen bens_3_2 = rowtotal(hes_inc_3_2*)
bys ird_linked : su bens_3_2

bys ird_linked : su hes_inc_3_1_0_05 

bys ird_linked : su hes_inc_4_1_0_01 
bys ird_linked : su hes_inc_4_1_0_02 

egen other_regular_income = rowtotal(hes_inc_4*)
bys ird_linked : su other_regular_income

egen overseas_income = rowtotal(hes_inc_5*)
bys ird_linked : su overseas_income 

egen irregular_income = rowtotal(hes_inc_6*)
bys ird_linked : su irregular_income

local non_comparable_vars bens_3_2 invest_inc overseas_income other_regular_income irregular_income

egen non_comp = rowtotal (`non_comparable_vars')

gen overall_maybe = non_comp + hes_overall_new

local non_comparable_vars sumhes hes_overall_new non_comp overall_maybe `non_comparable_vars' 

sumtable `non_comparable_vars' , group(ird_linked)

putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/Linked v Unlinked", sheet("Uncomparable") modify

tab ird_linked , matcell(heslinks)

mat rownames heslinks = "Unlinked" "Linked" 

putexcel  A1=("`c(current_date)' `c(current_time)' ") B2=matrix(heslinks, names) using "${RESULTS}/Linked v Unlinked", sheet("Links rates") modify

tab hes_per_hes_year_code ird_linked , matcell(heslinks)
mat colnames heslinks = "Unlinked" "Linked"
levelsof hes_per_hes_year_code , local(years)
mat rownames heslinks = `years'

putexcel  A1=("`c(current_date)' `c(current_time)' ") G2=matrix(heslinks, names) using "${RESULTS}/Linked v Unlinked", sheet("Links rates") modify

local cols = colsof(heslinks)
local rows = rowsof(heslinks)

local tl_cell G2

local l_column = substr("`tl_cell'",1,1)
local t_row = substr("`tl_cell'",2,2)

local b_row = `t_row' + `rows'  

tokenize `c(ALPHA)'
di "`3'"
di "`l_column'"
forvalues i = 1/26 {
	if "`l_column'" == "``i''" local num `i'
}
local num = `num' + `cols'

local r_column ``num''

local bl_cell `l_column'`b_row' 
local br_cell `r_column'`b_row'
local tr_cell `r_column'`t_row'

di "`tl_cell' `tr_cell' `br_cell' `bl_cell'" 
putexcel set "${RESULTS}/Linked v Unlinked" , modify sheet("Links rates") 
putexcel (`tl_cell':`tr_cell')= border("bottom", "double")
putexcel (`tl_cell':`tr_cell')= border("top", "thin")
putexcel (`bl_cell':`br_cell')= border("bottom", "thin")

label define laird_linked 0 "Unlinked" 1 "Linked" 
label values ird_linked laird_linked
label variable sumhes "Total HES income"
label variable sumird "Total IRD income"
label variable hes_wages "HES wages"
label variable hes_self "HES self-employment income"
label variable hes_rent "HES rental income"
label variable hes_pensions "Total HES pension income"
label variable hes_STU "HES student allowance income"
label variable hes_PPL "HES PPL income"

foreach var in sumhes sumird hes_wages hes_self hes_rent hes_pensions hes_STU hes_PPL eth_euro eth_maori eth_pacific female hes_age ird_self  {
	local ytitle : variable label `var'
	local title "`ytitle' by link type over time"
	
	reg `var' i.hes_per_hes_year_code##i.ird_linked
	margins i.hes_per_hes_year_code, over(i.ird_linked)
	marginsplot , noci ///
			xti("HES year") ///
			title("`title'") ///
			ytitle("`ytitle'") ///
			name(`var') yscale(range(0))
			
	graph export "${RESULTS}/`round'/`ytitle' by link type.`gtype'" , replace
			
}

twoway 	(kdensity sumhes if ird_linked == 0 & sumhes>= 0 & sumhes < 200000) ///
		(kdensity sumhes if ird_linked == 1 & sumhes >= 0 & sumhes < 200000) ///
		 if hes_per_hes_year_code == 2015  ///
		 , legend(label(1 "Unlinked") label(2 "Linked")) ///
		 note("Includes all sources of income (including those not in IRD data)")
		 
graph export "${RESULTS}/sumhes_kdensity_by_link_type.`gtype'" , replace		

cap log close
