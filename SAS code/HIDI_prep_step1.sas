proc datasets lib=work kill nolist memtype=data ;
quit ;

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean&version.);
	create table HESIndividual as
		select *
			from connection to sqlservr(
				select *
					from hes_clean.hes_person
						);
	create table HESIncome as
		select *
			from connection to sqlservr(
				select *
					from hes_clean.hes_income
						);
	disconnect from sqlservr;
quit ;

data HIDIraw.HESIndividual_raw ;
	set HESIndividual ;
run ;

data HIDIraw.HESIncome_raw ;
	set HESIncome ;
run ;
proc export data=HESIncome 
	outfile= "HESIncome_raw.dta" /* File path removed */
replace ;

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean&version.);
	create table HesIndividual as
		select a.*, coalesce(b.snz_spine_ind, 0) as snz_spine_ind
			from HESIndividual a LEFT JOIN connection to sqlservr(
				select snz_uid, snz_spine_ind
					from data.personal_detail
						) b
						on a.snz_uid = b.snz_uid
					order by a.snz_uid;
	disconnect from sqlservr ;
quit ;

data HESIndividual ;
	set HESIndividual ;
	hes_linked = 0 ;
	if snz_spine_ind = 1 then hes_linked = 1 ;
run ; 

proc freq data=HESIndividual  ;
	tables hes_linked*hes_per_hes_year_code ;
run ;

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean&version.);
	create table HESIndividual as
		select a.*, mdy(b.hes_hhd_month_nbr,15,b.hes_hhd_year_nbr) as Interview_Date format yymmdd10.
			from HESIndividual a LEFT JOIN connection to sqlservr(
				select snz_hes_hhld_uid, hes_hhd_month_nbr, hes_hhd_year_nbr
					from hes_clean.hes_household
						) b
						on a.snz_hes_hhld_uid = b.snz_hes_hhld_uid;
	disconnect from sqlservr;
quit ;

data intdata.HESIndividual ;
	set HESIndividual ;
run ;

proc sql ;
	create table HES_income_long as
	select 	snz_uid,
			hes_inc_income_source_code ,
			sum(hes_inc_amount_amt) as hes_inc_amount_amt 
	from HESIncome
	group by snz_uid , hes_inc_income_source_code 
	order by snz_uid , hes_inc_income_source_code ;
quit ;
	
proc transpose 	data=HES_income_long
				out=HES_wide_full (drop= _name_ )
				prefix= HES_inc_ ;
	by snz_uid ;
	id hes_inc_income_source_code ;
	var hes_inc_amount_amt ;
run ;

data HES_wide_full (drop=i) ;
	set HES_wide_full ;
	array hes_var{*} HES_inc_: ;
	do i = 1 to dim(hes_var) ;
			if MISSING(hes_var{i}) then hes_var{i} = 0 ;
	end ;
	sumhes = sum(of hes_inc_:) ;
run ;

proc sql ;
	create table HES_wide_full as
	select 	A.* ,
			B.hes_per_sex_snz_code as hes_sex ,
			B.hes_per_age_nbr as hes_age ,
			B.hes_per_ethnic_grp1_snz_ind ,
			B.hes_per_ethnic_grp2_snz_ind ,
			B.hes_per_ethnic_grp3_snz_ind ,
			B.hes_per_ethnic_grp4_snz_ind ,
			B.hes_per_ethnic_grp5_snz_ind ,
			B.hes_per_ethnic_grp6_snz_ind ,
			B.hes_per_highest_qual_desc_text as hes_educ ,
			B.hes_per_labfor_status_short_code as hes_LFstatus ,
			B.hes_per_hrs_worked_per_week_nbr as hes_hours_wrkd ,
			B.hes_per_hes_year_code ,
			B.hes_linked 
	from 	HES_wide_full A LEFT JOIN
			HESINDIVIDUAL B	
	on A.snz_uid = B.snz_uid
	order by a.snz_uid ;
quit ;

PROC freq data=HES_wide_full nlevels ;
	table hes_linked ;
run ; 

data intdata.HES_wide_full ;
	set HES_wide_full ;
run ;
