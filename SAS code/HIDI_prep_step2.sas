proc datasets lib=work kill nolist memtype=data ;
quit ;

proc sql;
	connect to sqlservr(server=WPRDSQL36\iLeed database=IDI_Clean&version.);;
	create table IRDIndividual as 
	select a.snz_uid, a.Interview_Date, 
			b.inc_tax_yr_year_nbr,	b.inc_tax_yr_income_source_code, 
	      	b.inc_tax_yr_mth_01_amt, b.inc_tax_yr_mth_02_amt,
		  	b.inc_tax_yr_mth_03_amt, b.inc_tax_yr_mth_04_amt,
		  	b.inc_tax_yr_mth_05_amt, b.inc_tax_yr_mth_06_amt,
		  	b.inc_tax_yr_mth_07_amt, b.inc_tax_yr_mth_08_amt,
		  	b.inc_tax_yr_mth_09_amt, b.inc_tax_yr_mth_10_amt,
		  	b.inc_tax_yr_mth_11_amt, b.inc_tax_yr_mth_12_amt, b.inc_tax_yr_tot_yr_amt
	from intdata.HESIndividual A INNER JOIN connection to sqlservr (
		select snz_uid, inc_tax_yr_year_nbr,
		inc_tax_yr_tot_yr_amt,  inc_tax_yr_income_source_code, 
		inc_tax_yr_mth_01_amt, inc_tax_yr_mth_02_amt,
		inc_tax_yr_mth_03_amt, inc_tax_yr_mth_04_amt,
		inc_tax_yr_mth_05_amt, inc_tax_yr_mth_06_amt,
		inc_tax_yr_mth_07_amt, inc_tax_yr_mth_08_amt,
		inc_tax_yr_mth_09_amt, inc_tax_yr_mth_10_amt,
		inc_tax_yr_mth_11_amt, inc_tax_yr_mth_12_amt
		from data.income_tax_yr
		) B
	on a.snz_uid = b.snz_uid
	order by a.snz_uid, b.inc_tax_yr_year_nbr;
	disconnect from sqlservr;
quit ;

data HIDIraw.IRD_RAW ;
	set IRDIndividual ;
run ;

proc export data=IRDIndividual
			outfile="IRDIndividual_raw.dta" /* File path removed */
			replace ;
run ; 

data IRDIndividual;
	set IRDIndividual;
	if MISSING(inc_tax_yr_mth_01_amt) then inc_tax_yr_mth_01_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_02_amt) then inc_tax_yr_mth_02_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_03_amt) then inc_tax_yr_mth_03_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_04_amt) then inc_tax_yr_mth_04_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_05_amt) then inc_tax_yr_mth_05_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_06_amt) then inc_tax_yr_mth_06_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_07_amt) then inc_tax_yr_mth_07_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_08_amt) then inc_tax_yr_mth_08_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_09_amt) then inc_tax_yr_mth_09_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_10_amt) then inc_tax_yr_mth_10_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_11_amt) then inc_tax_yr_mth_11_amt = inc_tax_yr_tot_yr_amt / 12;
	if MISSING(inc_tax_yr_mth_12_amt) then inc_tax_yr_mth_12_amt = inc_tax_yr_tot_yr_amt / 12;
run;

data IRDIndividual;
	set IRDIndividual;
	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 3) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 4) then inc_tax_yr_mth_01_amt = inc_tax_yr_mth_01_amt;
	else inc_tax_yr_mth_01_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 4) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 5) then inc_tax_yr_mth_02_amt = inc_tax_yr_mth_02_amt;
	else inc_tax_yr_mth_02_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 5) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 6) then inc_tax_yr_mth_03_amt = inc_tax_yr_mth_03_amt;
	else inc_tax_yr_mth_03_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 6) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 7) then inc_tax_yr_mth_04_amt = inc_tax_yr_mth_04_amt;
	else inc_tax_yr_mth_04_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 7) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 8) then inc_tax_yr_mth_05_amt = inc_tax_yr_mth_05_amt;
	else inc_tax_yr_mth_05_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 8) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 9) then inc_tax_yr_mth_06_amt = inc_tax_yr_mth_06_amt;
	else inc_tax_yr_mth_06_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 9) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 10) then inc_tax_yr_mth_07_amt = inc_tax_yr_mth_07_amt;
	else inc_tax_yr_mth_07_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 10) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 11) then inc_tax_yr_mth_08_amt = inc_tax_yr_mth_08_amt;
	else inc_tax_yr_mth_08_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 11) or 
		(year(Interview_Date) + 1 = inc_tax_yr_year_nbr and month(Interview_Date) ge 12) then inc_tax_yr_mth_09_amt = inc_tax_yr_mth_09_amt;
	else inc_tax_yr_mth_09_amt = 0 ;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) le 12) then inc_tax_yr_mth_10_amt = inc_tax_yr_mth_10_amt;
	else inc_tax_yr_mth_10_amt = 0 ;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) > 1) or 
		(year(Interview_Date) - 1 = inc_tax_yr_year_nbr and month(Interview_Date) le 1) then inc_tax_yr_mth_11_amt = inc_tax_yr_mth_11_amt;
	else inc_tax_yr_mth_11_amt = 0;

	if  (year(Interview_Date) = inc_tax_yr_year_nbr and month(Interview_Date) > 2) or 
		(year(Interview_Date) - 1 = inc_tax_yr_year_nbr and month(Interview_Date) le 2) then inc_tax_yr_mth_12_amt = inc_tax_yr_mth_12_amt;
	else inc_tax_yr_mth_12_amt = 0;

	Derived_Total = sum(inc_tax_yr_mth_01_amt, inc_tax_yr_mth_02_amt, inc_tax_yr_mth_03_amt, inc_tax_yr_mth_04_amt,
						inc_tax_yr_mth_05_amt, inc_tax_yr_mth_06_amt, inc_tax_yr_mth_07_amt, inc_tax_yr_mth_08_amt,
						inc_tax_yr_mth_09_amt, inc_tax_yr_mth_10_amt, inc_tax_yr_mth_11_amt, inc_tax_yr_mth_12_amt);
run;

proc sql;
	create table IRDReportingPeriod as
	select snz_uid, sum(Derived_Total) as inc_tax_yr_tot_yr_amt
	from IRDIndividual
	group by snz_uid
	order by snz_uid;
quit;

data intdata.IRDReportingPeriod ;
	set IRDReportingPeriod ;
run ;

proc sql ;
	create table IRDReportingPeriod_type as
	select 	snz_uid,
			inc_tax_yr_income_source_code,
			sum(Derived_Total) as inc_tax_yr_tot_yr_amt
	from IRDIndividual
	group by snz_uid, inc_tax_yr_income_source_code
	order by snz_uid, inc_tax_yr_income_source_code ;
quit ;

proc transpose data=IRDReportingPeriod_type out=IRDReporting_wide (drop=_name_) prefix=IRD_ ;
	by snz_uid ;
	id inc_tax_yr_income_source_code ;
	var inc_tax_yr_tot_yr_amt ;
run ;

data IRDReporting_wide (drop = i);
	set IRDReporting_wide ;
	array irdvar{*} IRD:;
	do i=1 to dim(irdvar);
		if MISSING(irdvar{i}) then irdvar{i} = 0;
	end;
	sumird=sum(of ird:);
run;

proc sql;
	create table IRDReporting_wide as
	select a.*, b.* 
	from IRDReporting_wide A 
	  	LEFT JOIN
		IRDReportingPeriod B
	on a.snz_uid = b.snz_uid
	order by snz_uid;
run;

Data intdata.IRDReporting_wide ;
	set IRDReporting_wide ;
run ;