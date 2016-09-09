/*
Purpose:
To do some basic income comparisons between HES and IDI.

This program pulls in the HES data, updates the linking variables, updates the linking variables, and then reshapes the data wide.
*/

proc datasets lib=work kill nolist memtype=data ;
quit ;

*%include "~\HIDI_init.sas" ; /* Directory needs to be changed to project home. */

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean);
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
	outfile= "&int_dir.\HESIncome_raw.dta"
replace ;

proc sql;
	create table HESIndividual as
	select a.*, b.Possible
	from HESIndividual A LEFT JOIN intdata.hes_geo_impute B
	on a.snz_uid = b.snz_uid;
run;

proc sql ;
	create table HESIncome as
	select a.*, b.Possible
	from HESIncome A LEFT JOIN intdata.hes_geo_impute B
	on a.snz_uid = b.snz_uid 
	order by  b.Possible ;
run ;

data HESIndividual;
	set HESIndividual;
	snz_uid_old = snz_uid ;
	if not MISSING(Possible) then snz_uid = Possible;
	if not MISSING(Possible) then improved_link = 1 ;
	else improved_link = 0 ;
run;

data HESIncome ;
	set HESIncome ;
	snz_uid_old = snz_uid ;
	if not MISSING(Possible) then snz_uid = Possible ;
run ;

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean);
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

proc sort 	data=HESIndividual 
			out=nodups
			dupout = dups (keep=snz_uid improved_link)
			nodupkey ;
	by snz_uid ;			
run ;

data dups ;
	set dups ;
	dup_tag = 1 ;
run ;

proc sql ;
	create table HESIndividual as
	select a.* , b.*
	from 	HESIndividual a LEFT JOIN
			dups b
	on a.snz_uid = b.snz_uid 
	order by snz_uid , hes_per_hes_year_code  ;

	create table HESIncome as
	select a.*, b.* 
	from	HESIncome a LEFT JOIN
			dups b
	on		a.snz_uid = b.snz_uid
	order by snz_uid , hes_inc_hes_year_code ;
quit ;

data HESIndividual (drop=dup_tag) ;
	set HESIndividual ;
	if dup_tag = 1 then snz_uid=snz_uid_old ;
run ;

data HESIncome (drop=dup_tag) ;
	set HESIncome ;
	if dup_tag =1 then snz_uid = snz_uid_old ;
run ;

data HESIndividual ;
	set HESIndividual ;
	hes_linked = 0 ;
	if snz_spine_ind = 1 then hes_linked = 1 ;
	if (snz_spine_ind = 1 and improved_link = 1 ) then	
		hes_linked = 2 ;
run ; 

proc sql ;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean);
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

data HESIncome ;
	set HESIncome ;
	if substr(hes_inc_income_source_code, 1, 1) in ('5', '6', '9') then  hes_inc_amount_amt = 0 ;
	if hes_inc_income_source_code in ('3.2.0.01', '3.2.0.02', '3.2.0.03', '3.2.0.04' , '3.2.0.06') then hes_inc_amount_amt = 0 ;
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
			B.hes_per_hes_year_code , snz_uid_old ,
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