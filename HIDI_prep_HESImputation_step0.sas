/*
Author: Christopher Ball
Date Created: 10/03/2016

Purpose:
To identify how much better we can do using IDI information to link
HES households/individuals.
*/

proc datasets lib=work kill nolist memtype=data;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	create table HESIndividual as
	select *
	from connection to sqlservr (
		select *
		from HES_clean.hes_person
	);
	DISCONNECT FROM sqlservr ;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	create table HesIndividual as
		select a.*, coalesce(b.snz_spine_ind, 0) as snz_spine_ind
			from HESIndividual a LEFT JOIN connection to sqlservr(
				select snz_uid, snz_spine_ind
				from data.personal_detail
					) b
			on a.snz_uid = b.snz_uid
			order by a.snz_uid;
	disconnect from sqlservr;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	create table HESIndividual as
	select a.*, mdy(b.hes_hhd_month_nbr,15,b.hes_hhd_year_nbr) as Interview_Date format yymmdd10.
	from HESIndividual a LEFT JOIN connection to sqlservr(
		select snz_hes_hhld_uid, hes_hhd_month_nbr, hes_hhd_year_nbr
		from hes_clean.hes_household
		) b
	on a.snz_hes_hhld_uid = b.snz_hes_hhld_uid;
	disconnect from sqlservr;
quit;

proc sql;
	create table HESHH as
	select snz_hes_hhld_uid, min(snz_spine_ind) as AllMatch, max(snz_spine_ind) as OneMatch
	from HESIndividual
	group by snz_hes_hhld_uid; 
quit;

proc sql;
	create table HESHHImpute as
	select snz_hes_hhld_uid
	from HESHH
	where OneMatch = 0;
quit;

proc freq data=HESIndividual;
table snz_spine_ind/ MISSING;
run;

proc freq data=HesHH;
table AllMatch/ MISSING;
table OneMatch/ MISSING;
run;

data Combined;
	set intdata.address_event;
run;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	create table Combined as 
		select distinct a.*, b.snz_birth_year_nbr, b.snz_birth_month_nbr, b.snz_sex_code
			from Combined a LEFT JOIN connection to sqlservr(
				select snz_uid, snz_birth_year_nbr, snz_birth_month_nbr, snz_sex_code
					from data.personal_detail
						) b
						on a.snz_uid = b.snz_uid
					where not MISSING(b.snz_birth_year_nbr);
	disconnect from sqlservr;
quit;

proc sql;
	create table HESIndividual as
	select a.*, b.snz_idi_address_register_uid
	from HESIndividual a LEFT JOIN Combined b
	on a.snz_uid = b.snz_uid and b.StartDate <= a.Interview_Date and (a.Interview_Date <= b.EndDate or MISSING(b.EndDate))
	order by snz_hes_hhld_uid, snz_uid;
quit;

proc sql;
	create table HESHHAdd as
	select distinct snz_hes_hhld_uid, snz_idi_address_register_uid
	from HESIndividual
	where not MISSING(snz_idi_address_register_uid)
	order by snz_hes_hhld_uid, snz_idi_address_register_uid;
	create table HESHHAddCheck as
	select snz_hes_hhld_uid, count(snz_idi_address_register_uid) as Different_Address
	from HESHHAdd
	group by snz_hes_hhld_uid;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	create table HESHHADD2 as
	select *
	from connection to sqlservr (
		select snz_hes_hhld_uid, snz_idi_address_register_uid 
		from hes_clean.hes_address 
		);
	disconnect from sqlservr;
run;

data HESHHADD;
	set HESHHADD HESHHADD2;
	if MISSING(snz_idi_address_register_uid) then DELETE;
run;

proc sort data=HESHHADD noduprecs;
	by snz_hes_hhld_uid;
run;

data HESIndividual;
	format hes_per_sex_code $1.;
	set HESIndividual;
	hes_per_year_of_birth_nbr = year(Interview_Date)-hes_per_age_nbr - 1*(hes_per_month_of_birth_nbr > month(Interview_Date));
run;

proc sql;
	create table HESIndividual as
	select a.*, coalesce(a.snz_idi_address_register_uid,  b.snz_idi_address_register_uid) as address
	from HESIndividual a LEFT JOIN HESHHAdd b
	on a.snz_hes_hhld_uid = b.snz_hes_hhld_uid
	order by a.snz_hes_hhld_uid, a.snz_uid;
quit;

proc sql;
	create table HESOffSpineMatched as
		select a.*, b.snz_uid as Possible, coalesce(0*b.snz_uid + 1, 0) as Match
			from HESIndividual a LEFT JOIN Combined b
				on a.address = b.snz_idi_address_register_uid and 
				a.hes_per_year_of_birth_nbr = b.snz_birth_year_nbr and a.hes_per_month_of_birth_nbr = b.snz_birth_month_nbr and 
				a.hes_per_sex_snz_code = b.snz_sex_code and
				b.StartDate <= a.Interview_Date and (a.Interview_Date <= b.EndDate or MISSING(b.EndDate))
			where a.snz_uid ne b.snz_uid
			order by a.snz_hes_hhld_uid, a.snz_uid;
quit;

proc freq data= HESOffSpineMatched;
table Match;
run;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	create table Map as
	select distinct snz_uid, Possible
	from HESOffSpineMatched
	where snz_spine_ind = 0 and not MISSING(Possible) and 
	Possible not in (
		select snz_uid 
		from connection to sqlservr(
			select snz_uid 
			from HES_clean.hes_person)
		);
	disconnect from sqlservr;
quit;

proc sql;
	create table Map_Dedup as
	select *
	from Map 
	where snz_uid not in (select snz_uid from Map group by snz_uid having count(snz_uid) > 1) and
	Possible not in (select Possible from Map group by Possible having count(Possible) > 1)
	order by snz_uid;
quit;

data intdata.HES_Geo_Impute;
	set Map_Dedup;
run;