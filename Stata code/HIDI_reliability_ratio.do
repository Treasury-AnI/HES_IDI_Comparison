clear all
set more off
version 14.0
local gtype emf
local doname HIDI_reliablity_ratio


cap log close
log using "${LOGS}/`doname' `c(current_date)'" , replace

use "${INTDATA}/comparison_full.dta", clear

order _all , alpha

matrix define A = J(8,13,.)
matrix colnames A = "IRD comparable income" "IRD comparable income" "arcsinh HES comparable income" "arcsinh HES comparable income" "ln(IRD comparable income)" "IRD wages" "IRD wages" "arcsinh wages" "arcsinh wages" "ln(IRD wages)" "IRD self" "IRD self" "ln(IRD self)"
matrix rownames A = "" "Constant" "" "HES RR" "" "R squared" "N" "Correlation coefficient"

matrix define B = J(8,13,.)

matrix colnames B = "HES comparable income" "HES comparable income" "arcsinh HES comparable income" "arcsinh HES comparable income" "ln(HES comparable income)" "HES wages" "HES wages" "arcsinh wages" "arcsinh  wages" "ln(HES wages)" "HES self" "HES self" "ln(HES self)"
matrix rownames B = "" "Constant"  "" "IRD RR" "" "R squared" "N" "Correlation coefficient" 

mat list A
mat list B

reg ird_overall_new hes_overall_new , robust

corr ird_overall_new hes_overall_new if e(sample) 
mat A[8,1] = round(`r(rho)',0.001)

mat A[2,1] = round(_b[_cons],10)
mat A[3,1] = round(_se[_cons],10)

mat A[4,1] = round(_b[hes_overall_new],0.001)
mat A[5,1] = round(_se[hes_overall_new],0.001)

mat A[6,1] = round(e(r2),0.001)
mat A[7,1] = e(N)


reg ird_overall_new hes_overall_new 	if  ird_overall_new > 1 ///
										& hes_overall_new > 1 , robust

corr ird_overall_new hes_overall_new if e(sample) 
mat A[8,2] = round(`r(rho)',0.001)
										
mat A[2,2] = round(_b[_cons],10)
mat A[3,2] = round(_se[_cons],10)

mat A[4,2] = round(_b[hes_overall_new],0.001)
mat A[5,2] = round(_se[hes_overall_new],0.001)

mat A[6,2] = round(e(r2),0.001)
mat A[7,2] = e(N)
	
reg hes_overall_new ird_overall_new , robust

corr ird_overall_new hes_overall_new if e(sample) 
mat B[8,1] = round(`r(rho)',0.001)

mat B[2,1] = round(_b[_cons],10)
mat B[3,1] = round(_se[_cons],10)

mat B[4,1] = round(_b[ird_overall_new],0.001)
mat B[5,1] = round(_se[ird_overall_new],0.001)

mat B[6,1] = round(e(r2),0.001)
mat B[7,1] = e(N)

reg hes_overall_new ird_overall_new 	if ird_overall_new > 1 ///
										& hes_overall_new > 1 , robust

corr ird_overall_new hes_overall_new if e(sample) 
mat B[8,2] = round(`r(rho)',0.001)
										
mat B[2,2] = round(_b[_cons],10)
mat B[3,2] = round(_se[_cons],10)

mat B[4,2] = round(_b[ird_overall_new],0.001)
mat B[5,2] = round(_se[ird_overall_new],0.001)

mat B[6,2] = round(e(r2),0.001)
mat B[7,2] = e(N)

gen asinh_hes_overall_new = asinh(hes_overall_new)
gen asinh_ird_overall_new = asinh(ird_overall_new)

reg asinh_ird_overall_new asinh_hes_overall_new , robust

corr asinh_hes_overall_new asinh_ird_overall_new if e(sample) 
mat A[8,3] = round(`r(rho)',0.001)

mat A[2,3] = round(_b[_cons],0.01)
mat A[3,3] = round(_se[_cons],0.01)

mat A[4,3] = round(_b[asinh_hes_overall_new],0.001)
mat A[5,3] = round(_se[asinh_hes_overall_new],0.001)

mat A[6,3] = round(e(r2),0.001)
mat A[7,3] = e(N)

reg asinh_ird_overall_new asinh_hes_overall_new 	if ird_overall_new > 1 ///
													& hes_overall_new > 1 , robust
												
corr asinh_hes_overall_new asinh_ird_overall_new if e(sample) 
mat A[8,4] = round(`r(rho)',0.001)
													
mat A[2,4] = round(_b[_cons],0.01)
mat A[3,4] = round(_se[_cons],0.01)

mat A[4,4] = round(_b[asinh_hes_overall_new],0.001)
mat A[5,4] = round(_se[asinh_hes_overall_new],0.001)

mat A[6,4] = round(e(r2),0.001)
mat A[7,4] = e(N)

reg asinh_hes_overall_new asinh_ird_overall_new  , robust 

corr asinh_hes_overall_new asinh_ird_overall_new if e(sample) 
mat B[8,3] = round(`r(rho)',0.001)

mat B[2,3] = round(_b[_cons],0.01)
mat B[3,3] = round(_se[_cons],0.01)

mat B[4,3] = round(_b[asinh_ird_overall_new],0.001)
mat B[5,3] = round(_se[asinh_ird_overall_new],0.001)

mat B[6,3] = round(e(r2),0.001)
mat B[7,3] = e(N)

reg asinh_hes_overall_new asinh_ird_overall_new if ird_overall_new > 1 ///
													& hes_overall_new > 1 , robust

corr asinh_hes_overall_new asinh_ird_overall_new if e(sample) 
mat B[8,4] = round(`r(rho)',0.001)													
													
mat B[2,4] = round(_b[_cons],0.01)
mat B[3,4] = round(_se[_cons],0.01)

mat B[4,4] = round(_b[asinh_ird_overall_new],0.001)
mat B[5,4] = round(_se[asinh_ird_overall_new],0.001)

mat B[6,4] = round(e(r2),0.001)
mat B[7,4] = e(N)
													
** repeat regression in logs		

gen ln_hes = ln(hes_overall_new)
gen ln_ird = ln(ird_overall_new)

reg ln_ird ln_hes if hes_overall_new > 1 & ird_overall_new > 1 , robust

corr ln_ird ln_hes if e(sample) 
mat A[8,5] = round(`r(rho)',0.001)

mat A[2,5] = round(_b[_cons],0.001)
mat A[3,5] = round(_se[_cons],0.001)

mat A[4,5] = round(_b[ln_hes],0.001)
mat A[5,5] = round(_se[ln_hes],0.001)

mat A[6,5] = round(e(r2),0.001)
mat A[7,5] = e(N)

reg ln_hes ln_ird if hes_overall_new > 1 & ird_overall_new > 1 , robust

corr ln_ird ln_hes if e(sample) 
mat B[8,5] = round(`r(rho)',0.001)

mat B[2,5] = round(_b[_cons],0.001)
mat B[3,5] = round(_se[_cons],0.001)

mat B[4,5] = round(_b[ln_ird],0.001)
mat B[5,5] = round(_se[ln_ird],0.001)

mat B[6,5] = round(e(r2),0.001)
mat B[7,5] = e(N)

gen ln_diff = ln(hes_overall_new) - ln(ird_overall_new) 
su ln_diff

reg hes_wages ird_wages 

corr hes_wages ird_wages if e(sample) 
mat B[8,6] = round(`r(rho)',0.001)

mat B[2,6] = round(_b[_cons],10)
mat B[3,6] = round(_se[_cons],10)

mat B[4,6] = round(_b[ird_wages],0.001)
mat B[5,6] = round(_se[ird_wages],0.001)

mat B[6,6] = round(e(r2),0.001)
mat B[7,6] = e(N)

reg hes_wages ird_wages if hes_wages > 1 & ird_wages > 1

corr hes_wages ird_wages if e(sample) 
mat B[8,7] = round(`r(rho)',0.001)

mat B[2,7] = round(_b[_cons],10)
mat B[3,7] = round(_se[_cons],10)

mat B[4,7] = round(_b[ird_wages],0.001)
mat B[5,7] = round(_se[ird_wages],0.001)

mat B[6,7] = round(e(r2),0.001)
mat B[7,7] = e(N)

reg ird_wages hes_wages

corr hes_wages ird_wages if e(sample) 
mat A[8,6] = round(`r(rho)',0.001)

mat A[2,6] = round(_b[_cons],10)
mat A[3,6] = round(_se[_cons],10)

mat A[4,6] = round(_b[hes_wages],0.001)
mat A[5,6] = round(_se[hes_wages],0.001)

mat A[6,6] = round(e(r2),0.001)
mat A[7,6] = e(N)

reg ird_wages hes_wages if hes_wages > 1 & ird_wages > 1

corr hes_wages ird_wages if e(sample) 
mat A[8,7] = round(`r(rho)',0.001)

mat A[2,7] = round(_b[_cons],10)
mat A[3,7] = round(_se[_cons],10)

mat A[4,7] = round(_b[hes_wages],0.001)
mat A[5,7] = round(_se[hes_wages],0.001)

mat A[6,7] = round(e(r2),0.001)
mat A[7,7] = e(N)

gen asinh_hes_wages = asinh(hes_wages)
gen asinh_ird_wages = asinh(ird_wages)

reg asinh_ird_wages asinh_hes_wages , robust

corr asinh_ird_wages asinh_hes_wages if e(sample) 
mat A[8,8] = round(`r(rho)',0.001)

mat A[2,8] = round(_b[_cons],0.01)
mat A[3,8] = round(_se[_cons],0.01)

mat A[4,8] = round(_b[asinh_hes_wages],0.001)
mat A[5,8] = round(_se[asinh_hes_wages],0.001)

mat A[6,8] = round(e(r2),0.001)
mat A[7,8] = e(N)

reg asinh_ird_wage asinh_hes_wage if hes_wages > 1 & ird_wages > 1 , robust

corr asinh_ird_wages asinh_hes_wages if e(sample) 
mat A[8,9] = round(`r(rho)',0.001)

mat A[2,9] = round(_b[_cons],0.01)
mat A[3,9] = round(_se[_cons],0.01)

mat A[4,9] = round(_b[asinh_hes_wages],0.001)
mat A[5,9] = round(_se[asinh_hes_wages],0.001)

mat A[6,9] = round(e(r2),0.001)
mat A[7,9] = e(N)

reg asinh_hes_wage asinh_ird_wage , robust

corr asinh_ird_wages asinh_hes_wages if e(sample) 
mat B[8,8] = round(`r(rho)',0.001)

mat B[2,8] = round(_b[_cons],0.01)
mat B[3,8] = round(_se[_cons],0.01)

mat B[4,8] = round(_b[asinh_ird_wages],0.001)
mat B[5,8] = round(_se[asinh_ird_wages],0.001)

mat B[6,8] = round(e(r2),0.001)
mat B[7,8] = e(N)

reg asinh_hes_wage asinh_ird_wage if hes_wages > 1 & ird_wages > 1 , robust

corr asinh_ird_wages asinh_hes_wages if e(sample) 
mat B[8,9] = round(`r(rho)',0.001)

mat B[2,9] = round(_b[_cons],0.01)
mat B[3,9] = round(_se[_cons],0.01)

mat B[4,9] = round(_b[asinh_ird_wages],0.001)
mat B[5,9] = round(_se[asinh_ird_wages],0.001)

mat B[6,9] = round(e(r2),0.001)
mat B[7,9] = e(N)

gen ln_hes_wages = ln(hes_wages)
gen ln_ird_wages = ln(ird_wages)

reg ln_hes_wages ln_ird_wages if hes_wages > 1 & ird_wages > 1 , robust

corr ln_hes_wages ln_ird_wages if e(sample) 
mat B[8,10] = round(`r(rho)',0.001)

mat B[2,10] = round(_b[_cons],0.001)
mat B[3,10] = round(_se[_cons],0.001)

mat B[4,10] = round(_b[ln_ird_wages],0.001)
mat B[5,10] = round(_se[ln_ird_wages],0.001)

mat B[6,10] = round(e(r2),0.001)
mat B[7,10] = e(N)

reg ln_ird_wages ln_hes_wages if hes_wages > 1 & ird_wages > 1 , robust

corr ln_ird_wages ln_hes_wages if e(sample) 
mat A[8,10] = round(`r(rho)',0.001)

mat A[2,10] = round(_b[_cons],0.001)
mat A[3,10] = round(_se[_cons],0.001)

mat A[4,10] = round(_b[ln_hes_wages],0.001)
mat A[5,10] = round(_se[ln_hes_wages],0.001)

mat A[6,10] = round(e(r2),0.001)
mat A[7,10] = e(N)

gen ln_wages_diff = ln(hes_wages/ird_wages)
su ln_wages_diff if hes_wages > 1 & ird_wages > 1

reg hes_self ird_self , robust

corr hes_self ird_self if e(sample) 
mat B[8,11] = round(`r(rho)',0.001)

mat B[2,11] = round(_b[_cons],10)
mat B[3,11] = round(_se[_cons],10)

mat B[4,11] = round(_b[ird_self],0.001)
mat B[5,11] = round(_se[ird_self],0.001)

mat B[6,11] = round(e(r2),0.001)
mat B[7,11] = e(N)

reg hes_self ird_self if hes_self > 1 & ird_self > 1 , robust

corr hes_self ird_self if e(sample) 
mat B[8,12] = round(`r(rho)',0.001)

mat B[2,12] = round(_b[_cons],10)
mat B[3,12] = round(_se[_cons],10)

mat B[4,12] = round(_b[ird_self],0.001)
mat B[5,12] = round(_se[ird_self],0.001)

mat B[6,12] = round(e(r2),0.001)
mat B[7,12] = e(N)

reg ird_self hes_self , robust

corr hes_self ird_self if e(sample) 
mat A[8,11] = round(`r(rho)',0.001)

mat A[2,11] = round(_b[_cons],10)
mat A[3,11] = round(_se[_cons],10)

mat A[4,11] = round(_b[hes_self],0.001)
mat A[5,11] = round(_se[hes_self],0.001)

mat A[6,11] = round(e(r2),0.001)
mat A[7,11] = e(N)

reg ird_self hes_self if hes_self > 1 & ird_self > 1 , robust

corr hes_self ird_self if e(sample) 
mat A[8,12] = round(`r(rho)',0.001)

mat A[2,12] = round(_b[_cons],10)
mat A[3,12] = round(_se[_cons],10)

mat A[4,12] = round(_b[hes_self],0.001)
mat A[5,12] = round(_se[hes_self],0.001)

mat A[6,12] = round(e(r2),0.001)
mat A[7,12] = e(N)


gen ln_hes_self = ln(hes_self)
gen ln_ird_self = ln(ird_self)

reg ln_hes_self ln_ird_self if hes_self > 1 & ird_self > 1 , robust

corr ln_hes_self ln_ird_self if e(sample) 
mat B[8,13] = round(`r(rho)',0.001)

mat B[2,13] = round(_b[_cons],0.001)
mat B[3,13] = round(_se[_cons],0.001)

mat B[4,13] = round(_b[ln_ird_self],0.001)
mat B[5,13] = round(_se[ln_ird_self],0.001)

mat B[6,13] = round(e(r2),0.001)
mat B[7,13] = e(N)

reg ln_ird_self ln_hes_self if hes_self > 1 & ird_self > 1 , robust

corr ln_hes_self ln_ird_self if e(sample) 
mat A[8,13] = round(`r(rho)',0.001)

mat A[2,13] = round(_b[_cons],0.001)
mat A[3,13] = round(_se[_cons],0.001)

mat A[4,13] = round(_b[ln_hes_self],0.001)
mat A[5,13] = round(_se[ln_hes_self],0.001)

mat A[6,13] = round(e(r2),0.001)
mat A[7,13] = e(N)

gen ln_self_diff = ln(hes_self/ird_self)
su ln_self_diff 

mat list A
mat list B


putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(A, names) using "${RESULTS}/Reliability_ratios", sheet("HES Reliability ratios")modify
putexcel A1=("`c(current_date)' `c(current_time)' ") B2=matrix(B, names) using "${RESULTS}/Reliability_ratios", sheet("IRD Reliability ratios")modify

foreach var in overall_new {
	reg asinh_ird_`var' asinh_hes_`var' 
	reg asinh_ird_`var' asinh_hes_`var' if hes_`var' > 1 & ird_`var' > 1
	
	reg asinh_hes_`var' asinh_ird_`var'
	reg asinh_hes_`var' asinh_ird_`var' if hes_`var' > 1 & ird_`var' > 1
	
	corr asinh_ird_`var' asinh_hes_`var'
	corr asinh_ird_`var' asinh_hes_`var' if hes_`var' > 1 & ird_`var' > 1
}

gen ln_diff2 = ln(hes_overall_new)  - ln(ird_overall_new)
gen pct_diff_ird = (hes_overall_new-ird_overall_new)/ird_overall_new 

su ln_diff2 pct_diff_ird

su ln_diff2 pct_diff_ird if abs(ln_diff2) < .4 & abs(ln_diff2) > 0.02

encode hes_per_hes_year , gen(year)

reg ln_hes_wages ln_ird_wages i.year i.year#c.ln_ird_wages   if hes_wages > 1 & ird_wages > 1 , robust

margins year , dydx(c.ln_ird_wages) 
marginsplot ,  	yti("Reliability ratio") ///
				xti("HES year") ///
				ti("IRD reliablity ratio over time" "(for wage and salaries in logs)") ///
				yscale(range(0 1)) ///
				ytick(0(0.1)1) ///
				ymtick(0.05 (0.1) 0.95)  ///
				ylabel(0(0.1)1) ///
				note("95% CI interval based on robust s.e. plotted") ///
				name(wages_RR_time)
				
reg ln_hes_self ln_ird_self i.year i.year#c.ln_ird_self   if hes_self > 1 & ird_self > 1 , robust

margins year , dydx(c.ln_ird_self) 
marginsplot ,  	yti("Reliability ratio") ///
				xti("HES year") ///
				ti("IRD reliablity ratio over time" "(for self employment income in logs)") ///
				yscale(range(0 1)) ///
				ytick(0(0.1)1) ///
				ymtick(0.05 (0.1) 0.95)  ///
				ylabel(0(0.1)1) ///
				note("95% CI interval based on robust s.e. plotted") ///
				name(self_RR_time)

su ln_diff ln_wages_diff ln_self_diff

su ln_diff if hes_overall_new > 1 & ird_overall_new > 1 
su ln_wages_diff if hes_wages > 1 & ird_wages > 1
su ln_self_diff if hes_self > 1 & ird_self > 1

bys female: su ln_diff if hes_overall_new > 1 & ird_overall_new > 1 
bys female: su ln_wages_diff if hes_wages > 1 & ird_wages > 1
bys female: su ln_self_diff if hes_self > 1 & ird_self > 1

gen abs_ln_diff = abs(ln_diff)
gen abs_ln_wages_diff = abs(ln_wages_diff)
gen abs_ln_self_diff = abs(ln_self_diff)

su abs_ln_diff if hes_overall_new > 1 & ird_overall_new > 1 
su abs_ln_wages_diff if hes_wages > 1 & ird_wages > 1
su abs_ln_self_diff if hes_self > 1 & ird_self > 1

egen age_cut = cut(hes_age) , group(6)

replace diff_overall_new = -diff_overall_new 


gen abs_diff_overall_new = abs(diff_overall_new)

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

compress

gen eth_sum = eth_euro + eth_maori + eth_pacific + eth_asian + eth_eastern + eth_other
egen hes_age_HT = cut(hes_age) , at(15,25,55,150) 
notes hes_age_HT : "uses the same age bins as in the regs in Hyslop and Towsend 2016"
encode hes_educ , gen(educ)

local controls female b55.hes_age_HT i.educ eth_maori eth_pacific eth_asian eth_eastern eth_other  hes_hours

local ifcond eth_sum > 0 & ird_linked == 1 
local positive ird_overall_new > 1 & hes_overall_new > 1

compress

reg diff_overall_new ird_overall_new `controls' if `ifcond'  , robust
estimates store levels_full

reg abs_diff_overall_new ird_overall_new `controls' if `ifcond' , robust
estimates store abs_levels_full

reg diff_overall_new ird_overall_new `controls' if `ifcond' & `positive' , robust
estimates store cond_levels_full

reg abs_diff_overall_new ird_overall_new `controls' if `ifcond' & `positive' , robust
estimates store cond_abs_levels_full

reg ln_diff ln_ird `controls' if `ifcond' & `positive' , robust
estimates store ln_full

reg abs_ln_diff ln_ird `controls' if `ifcond' & `positive' , robust
estimates store abs_ln_full

estimates table * , keep(ird_overall_new ln_ird `controls') b(%6.0g) star stats(N r2)

cap log close reg_table

log using "${RESULTS}/reg_table" , text name(reg_table) replace

estimates table cond_levels_full cond_abs_levels_full ln_full abs_ln_full , varwidth(45) modelwidth(16) keep(ird_overall_new ln_ird `controls') b(%9.3f) se stats(N r2)

cap log close reg_table
cap log close
