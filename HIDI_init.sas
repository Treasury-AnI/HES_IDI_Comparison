%let version = ;

%let main_dir = ~ ; /* Directory needs to be changed to project home. */
%let int_dir = &main_dir.\Intermediate data ;
%let code_dir = &main_dir.\SAS code ;
%let results_dir = &main_dir.\Results and other non-data output ;

libname intdata "&main_dir.\Intermediate data" ;
libname HIDIraw "&main_dir.\Raw data" ;
