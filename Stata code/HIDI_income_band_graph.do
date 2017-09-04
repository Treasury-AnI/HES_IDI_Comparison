clear all
set more off
version 14.0
local gtype emf
local doname HIDI_linked_v_unlinked

cap log close
log using "${LOGS}/`doname' `c(current_date)'" , replace

use "${INTDATA}/comparison_full.dta", clear

order _all , alpha

isid snz_uid

compress

tab hes_linked

gen hes_linked_new = hes_linked
replace hes_linked_new = 1 if hes_linked > 0 & hes_linked < .

gen hes_linked_stats = hes_linked 
replace hes_linked_stats = 0 if hes_linked > 1 

gen enhanced_link = hes_linked
replace enhanced_link = . if hes_linked == 0
replace enhanced_link = enhanced_link -1
label var enhanced_link "Equals 1 if linked w/ enhanced method, equals zero otherwise"

replace hes_per_hes_year_code = substr(hes_per_hes_year_code,-2,.)
replace hes_per_hes_year_code = "20" + hes_per_hes_year_code

destring  hes_per_hes_year_code , replace

tab hes_per_hes_year_code

gen weird_link = 1 if ird_linked == 0 & hes_linked != 0
label var weird_link "Linked to spine but not IRD (in HES year)"

keep if ird_linked >= 1
preserve

egen incband = cut(ird_overall_new) , at(0(1000)1500000)
collapse (mean) meanird=ird_overall_new (count) countird=ird_overall_new (sum) totalird=ird_overall_new if hes_per_hes_year_code >= 2000 , by(incband)
twoway (connected total incband) if incband > 6000 & incband < 130000 , name(ird)

tempfile ird
save "`ird'"

restore

preserve
egen incband = cut(hes_overall_new) , at(0(1000)1500000)
collapse (mean) meanhes=hes_overall_new (count) counthes=hes_overall_new (sum) totalhes=hes_overall_new if hes_per_hes_year_code >= 2000, by(incband)
twoway (connected total incband) if incband > 6000 & incband < 130000 , name(hes)
tempfile hes
save "`hes'"
restore

clear
use "`ird'"
merge 1:1 incband using "`hes'"
assert _merge == 3 if incband < 150000

tempvar ird_count_check 
tempvar hes_count_check

egen `ird_count_check' = total(countird)
egen `hes_count_check' = total(counthes)

assert `ird_count_check' == `hes_count_check'

replace totalird = totalird / 1000000
replace totalhes = totalhes / 1000000
label var totalird "IRD data (same sample)" 
label var totalhes "HES data (same sample)"
replace totalird = round(totalird, .5)
replace totalhes = round(totalhes, .5)

cap graph drop _all
twoway (connected totalird incband , lcolor(ebblue) mcolor(ebblue) ) ///
		(connected totalhes incband, lcolor(cranberry) mcolor(cranberry) )  ///
		if incband <= 120000 ///
		, 	xtick(10000(10000)120000) ///
			xlabel(0(20000)120000)  ///
			ti("HES Respondents lump their income" "at 10k and 5k intervals") ///
			yti("Total income in band (millions)") ///
			xti("Income band (1k intervals)") ///
			name(totalinc)
	
graph export "${RESULTS}/Income by band.emf", replace

twoway (connected countird incband) (connected counthes incband) if incband < 120000 ///
		, 	xtick(10000(10000)120000) ///
			xlabel(0(20000)160000) ///
			ti("HES Respondents lump their income" "at 10k and 5k intervals") ///
			yti("Number of people") ///
			xti("Income band (1k intervals)") /// 
			name(count) 
			
	
graph export "${RESULTS}/count by band.emf" , replace

export excel using "${RESULTS}/data behind income graph.xls" , replace firstrow(variables)
	
