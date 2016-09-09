* Run everything from start to finish ;

%let start_time = %sysfunc(datetime()) ;

%include "~\HIDI_init.sas" ; /* Directory needs to be changed to project home. */

%include "&code_dir.\HIDI_Address_Event_Create.sas" ;

%include "&code_dir.\HIDI_prep_HESImputation_step0.sas" ;

%include "&code_dir.\HIDI_prep_step1.sas" ;

%include "&code_dir.\HIDI_prep_step2.sas" ;

%include "&code_dir.\HIDI_prep_step3.sas" ;

%include "&code_dir.\HIDI_BenefitDays.sas" ;