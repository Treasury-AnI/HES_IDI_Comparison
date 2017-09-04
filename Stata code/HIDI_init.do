macro drop _all
set more off

global MAIN "HES_IDI_comps" /* File path removed */
cd "${MAIN}" 

global INTDATA "${MAIN}/Intermediate data"

global DOFILES "${MAIN}/Stata code"

global RESULTS "${MAIN}/Results and other non-data output"

global LOGS "${MAIN}/Stata log files"

local Y = c(current_date)
local Y = substr("`Y'",8,.)
local week = week(date(c(current_date), "DMY"))
local D = "Week `week' `Y'"

di "${LOGS}/`D'"

cap mkdir "${LOGS}/`D'"

global LOGS "${LOGS}/`D'"

version 14.0
set scheme s1color

macro list
