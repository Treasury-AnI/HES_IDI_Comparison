/*
Purpose: To create an event based address map for the population, and 
summarise the contents into "spells" at the same address.

Has been compared to Census 2013, seems about 80% accurate at this point
in time (with 99% coverage of the linked population).  
Weakest areas are ages 20-29, where accuracy is about 65%.

*/

proc datasets lib=work kill nolist memtype=data;
quit ;

%macro Address_Import(Out = , In = , Prefix = , Source = , Date = );
Proc SQL;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
	CREATE TABLE &Out. AS 
	SELECT snz_uid, input(StartDate,yymmdd10.) as StartDate format yymmdd10., 
			Region, TA, MeshBlock, snz_idi_address_register_uid, &Source. as Source
	FROM connection to  sqlservr (

		select distinct snz_uid, &Date as StartDate, &Prefix._region_code as Region, 
			&Prefix._ta_code as TA, &Prefix._meshblock_code as MeshBlock,
			snz_idi_address_register_uid 
		from &In.
		where &Prefix._region_code is not NULL
		order by snz_uid

	);
	DISCONNECT FROM sqlservr ;
Quit;
%mend Address_Import;

%Address_Import(Out = NHIAddress, In = moh_clean.pop_cohort_nhi_address, Prefix = moh_nhi, Source = 'nhi', Date = moh_nhi_effective_date);
%Address_Import(Out = PHOAddress, In = moh_clean.pop_cohort_pho_address, Prefix = moh_adr, Source = 'pho', Date = coalesce(moh_adr_consultation_date,moh_adr_enrolment_date));
%Address_Import(Out = MOEAddress, In = moe_clean.student_per, Prefix = moe_spi, Source = 'moe', Date = moe_spi_mod_address_date);
%Address_Import(Out = IRDAddress, In = ir_clean.ird_addresses, Prefix = ir_apc, Source = 'ird', Date = ir_apc_applied_date);
%Address_Import(Out = ACCAddress, In = acc_clean.claims, Prefix = acc_cla, Source = 'acc', Date = coalesce(acc_cla_lodgement_date, acc_cla_registration_date,acc_cla_accident_date));
%Address_Import(Out = MSDRAddress, In = msd_clean.msd_residential_location, Prefix = msd_rsd, Source = 'msdr', Date = msd_rsd_start_date);

proc sql;
CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
create table work.CensusAddress as
select snz_uid, mdy(3,5,2013) as StartDate format yymmdd10., 
	Region, TA, MeshBlock, snz_idi_address_register_uid,  'cen' as Source
from connection to sqlservr
	( select snz_uid, region_code as Region, ta_code as TA, 
		meshblock_code as MeshBlock, snz_idi_address_register_uid
		from cen_clean.census_address 
		where address_type_code = 'UR' AND meshblock_code is not NULL 
		order by snz_uid);
disconnect from sqlservr;
quit;

proc sql;
CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean  );
create table work.CensusAddress5 as
select snz_uid, mdy(3,5,2008) as StartDate format yymmdd10., Region, TA, MeshBlock, snz_idi_address_register_uid, 'cen' as Source
from connection to sqlservr
	( select snz_uid, region_code as Region, ta_code as TA, 
		meshblock_code as MeshBlock, snz_idi_address_register_uid
		from cen_clean.census_address 
		where address_type_code = 'UR5' AND meshblock_code is not NULL 
		order by snz_uid);
disconnect from sqlservr;
quit;

data Address;
set NHIAddress PHOAddress MOEAddress IRDAddress ACCAddress MSDRAddress CensusAddress CensusAddress5;
run;

proc datasets library=Work;
delete NHIAddress PHOAddress MOEAddress IRDAddress ACCAddress MSDRAddress CensusAddress CensusAddress5;
run;

proc sql;
	create table Sub_Source as
	select a.*, b.AddRep
	from Address a LEFT JOIN (
		select snz_uid, snz_idi_address_register_uid, sum(0*snz_uid+1) as AddRep
		from Address
		group by snz_uid, snz_idi_address_register_uid) b
	on a.snz_uid = b.snz_uid and a.snz_idi_address_register_uid = b.snz_idi_address_register_uid
	order by snz_uid, snz_idi_address_register_uid;
quit;

proc sort data=Sub_Source;
by snz_uid StartDate descending AddRep;
run;

data Sub_Source;
	set Sub_Source;
	if snz_uid = lag(snz_uid) and StartDate = lag(StartDate) then DELETE;
run;

data Sub_Source;
	set Sub_Source;
	if snz_idi_address_register_uid = lag(snz_idi_address_register_uid) and 
		snz_uid = lag(snz_uid) then DELETE;
run;

proc sort data=Sub_Source;
	by snz_uid descending StartDate;
run;

data Sub_Source;
	format Enddate yymmdd10.;
	set Sub_Source;
	EndDate = ifn(lag(snz_uid) = snz_uid, lag(StartDate)-1, .);
run;

proc sort data= Sub_Source;
	by snz_uid StartDate;
run;

data intdata.Address_Event;
	set Sub_Source;
run;
