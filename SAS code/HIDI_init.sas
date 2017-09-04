* HIDI intialisation ;
* This file specifies where everything for the HIDI project lives.
* include this file in each of the programs involved ;

%let version = ;

%let main_dir = HES_IDI_comps ; /* File path removed */
%let int_dir = Intermediate data ; /* File path removed */
%let code_dir = SAS code ; /* File path removed */
%let results_dir = Results and other non-data output ; /* File path removed */

libname intdata "Intermediate data" ; /* File path removed */
libname HIDIraw "Raw data" ; /* File path removed */
