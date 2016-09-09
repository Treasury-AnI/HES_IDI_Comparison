* This code brings the HES and IRD data sets together, and then makes a concordance between the two data sets ;

proc datasets lib=work kill nolist memtype=data;
quit;

* %include "\\wprdfs08\Datalab-MA\MAA2015-27 IDI based micro-simulation modelling of the New Zealand tax and welfare system\Judd\HES_IDI_comps\SAS code\HIDI_init.sas" ;

proc sql ;
	create table comparison_full as	
	select A.* , B.*
	from 	intdata.HES_wide_full A LEFT JOIN
			intdata.IRDReporting_wide B
	on a.snz_uid = b.snz_uid 
	order by a.snz_uid ;
quit ;

data comparison_full ;
	set comparison_full ;
	if hes_sex = "2" then female = 1 ;
	if hes_sex = "1" then female = 0 ;
run ;

proc sql;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean);;
	create table IRDIndividuals as 
	select a.* ,
		b.snz_uid ,	b.snz_ird_uid 
	from comparison_full A LEFT JOIN connection to sqlservr (
		select snz_uid, snz_ird_uid 
		from security.concordance
		) B
	on a.snz_uid = b.snz_uid
	order by a.snz_uid ;
	disconnect from sqlservr;
quit ;

data comparison_full (drop = i);
	set irdindividuals ;

	if not MISSING(snz_ird_uid) then ird_linked = 1 ;
	else ird_linked = 0 ;

	if not missing(snz_ird_uid) and hes_linked >= 1 and MISSING(sumird) then ird_imputed_zero = 1 ;
	else ird_imputed_zero = 0 ;
	
	array irdvar{*} IRD: ;
	do i=1 to dim(irdvar);
		if not MISSING(snz_ird_uid) and hes_linked >= 1 and MISSING(irdvar{i}) then irdvar{i} = 0 ;
	end ;

	if not MISSING(snz_ird_uid) and hes_linked >= 1 and MISSING(sumird) then sumird = 0 ;
run ;

data comparison_full ;
	set comparison_full ;
	overall_diff = sumird - sumhes ;
	hes_wages = 	'hes_inc_1.1.1.01'n +
				 	'hes_inc_1.1.1.02'n +
					'hes_inc_1.1.1.03'n +
					'hes_inc_1.1.1.04'n +
					'hes_inc_1.1.1.05'n +
					'hes_inc_1.1.1.07'n + 
					'hes_inc_1.1.2.01'n +
				 	'hes_inc_1.1.2.02'n +
				 	'hes_inc_1.1.2.03'n +
					'hes_inc_1.1.2.04'n +
				 	'hes_inc_1.1.2.05'n +
				 	'hes_inc_1.1.2.06'n +
					'hes_inc_1.1.2.07'n +
				 	'hes_inc_1.1.2.08'n +
					'hes_inc_1.1.2.10'n  ;

	hes_self = 		'hes_inc_1.2.1.01'n +
					'hes_inc_1.2.1.02'n +
					'hes_inc_1.2.1.03'n +
					'hes_inc_1.2.2.01'n +
					'hes_inc_1.2.2.02'n +
					'hes_inc_1.2.2.03'n ; 

	hes_wages_and_self = hes_wages + hes_self ;
	hes_pensions = 	'hes_inc_3.1.0.01'n +
					'hes_inc_3.1.0.02'n +
					'hes_inc_3.1.0.03'n +
					'hes_inc_3.1.0.04'n;

	hes_PPL = 'hes_inc_3.2.0.05'n ;	
	hes_STU = 'hes_inc_3.2.0.27'n ;
	hes_rent = 'hes_inc_2.3.0.01'n ;
	hes_partner = 'hes_inc_2.5.0.03'n ;

	hes_overall_new =   hes_wages + hes_self +
						hes_pensions + hes_PPL + 
						hes_STU + hes_rent +
						hes_partner ;

	ird_wages = 'ird_W&S'n ;

	ird_self = ird_S00 + ird_S01 + ird_S02 ; 
	ird_wages_and_self = 'ird_W&S'n + ird_self ;
	ird_partner = 	'ird_P00'n + 'ird_P01'n ;

	ird_overall_new = 	'IRD_W&S'n + ird_self +
						IRD_PEN + IRD_PPL + 
						IRD_STU  + ird_S03 +
						ird_partner ;

	diff_wages = 'IRD_W&S'n - hes_wages ;
	diff_wages_and_self = ird_wages_and_self - hes_wages_and_self ;
	diff_self = ird_self - hes_self ;
	diff_rent = ird_S03 - hes_rent ;
	diff_partner = ird_partner - hes_partner ;
	diff_pensions = ird_PEN - hes_pensions ;
	diff_PPL = ird_PPL - hes_PPL ;
	diff_STU = ird_STU - hes_STU ;
	diff_overall_new = ird_overall_new - hes_overall_new ;

	call streaminit(100) ; /* Number has been changed for code release. */
	rand = rand("Uniform") ;
	
	rand1 = 300*rand("Uniform") - 150 ;

	rand2 = 300*rand("Uniform") - 150 ;
run ;

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean);
	create table comparison_full as
	select a.* , b.hes_inc_income_is_imputed_code
	from comparison_full a LEFT JOIN connection to sqlservr (
		select distinct snz_uid , hes_inc_income_is_imputed_code 
		from hes_clean.hes_income
		) B
	on a.snz_uid_old=b.snz_uid ;
	disconnect from sqlservr ;
quit ;

data intdata.comparison_full ;
	set comparison_full ;
run ;

proc export data=comparison_full
			outfile= "&int_dir.\comparison_full.dta"
			replace ;
run ;
