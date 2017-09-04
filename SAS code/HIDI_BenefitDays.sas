proc datasets lib=work kill nolist memtype=data ;
quit ;

%include "HIDI_init.sas" ; /* File path removed */

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean&version. );
	create table HES_Individual as
	select *
	from connection to sqlservr (
		select a.*, coalesce(b.snz_spine_ind, 0) as snz_spine_ind
		from HES_clean.hes_person A LEFT JOIN data.personal_detail B
		on a.snz_uid = b.snz_uid
		order by a.snz_uid
	);
	DISCONNECT FROM sqlservr ;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean&version.  );
	create table HES_Individual as
		select a.*, mdy(b.hes_hhd_month_nbr,15,b.hes_hhd_year_nbr) as Interview_Date format yymmdd10.
		from HES_Individual a LEFT JOIN connection to sqlservr(
			select snz_hes_hhld_uid, hes_hhd_month_nbr, hes_hhd_year_nbr
			from HES_clean.hes_household ) b
		on a.snz_hes_hhld_uid = b.snz_hes_hhld_uid
		order by a.snz_uid;
	disconnect from sqlservr;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean&version. );
	create table HES_Income_Bens as
	select *
	from connection to sqlservr(
		select snz_uid, hes_inc_current_beneficiary_code, hes_inc_month_benefit_recd_date,
			hes_inc_coding_topic_group_text, hes_inc_coding_topic_text, hes_inc_coding_description_text,
			hes_inc_selection_text, hes_inc_amount_amt, RIGHT(hes_inc_income_source_code,2) as inc_source, coalesce(hes_inc_days_covered_nbr,0) as hes_days
		from HES_clean.hes_income
		where LEFT(hes_inc_income_source_code, 3) = '3.2' and
		RIGHT(hes_inc_income_source_code,2) in ('07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '28', '29', '30', '31')
		order by snz_uid
	);
	disconnect from sqlservr;
quit;

proc sql;
	create table HES_Income_Bens as
	select distinct snz_uid, sum(CASE WHEN b.inc_source = '07' THEN b.hes_days END) as HES_UB_DAYS,
		sum(CASE WHEN b.inc_source = '08' THEN b.hes_days END) as HES_SB_DAYS,
		sum(CASE WHEN b.inc_source = '09' THEN b.hes_days END) as HES_DPB_DAYS,
		sum(CASE WHEN b.inc_source = '10' THEN b.hes_days END) as HES_IB_DAYS, /* Multiple overlapping IB records */
		sum(CASE WHEN b.inc_source = '11' THEN b.hes_days END) as HES_WB_DAYS,
		sum(CASE WHEN b.inc_source = '12' THEN b.hes_days END) as HES_Orphans_DAYS,
		sum(CASE WHEN b.inc_source = '13' THEN b.hes_days END) as HES_IYB_DAYS,
		sum(CASE WHEN b.inc_source = '14' THEN b.hes_days END) as HES_EB_DAYS,
		sum(CASE WHEN b.inc_source = '15' THEN b.hes_days END) as HES_EMB_DAYS,
		sum(CASE WHEN b.inc_source = '16' THEN b.hes_days END) as HES_Other_DAYS,
		sum(CASE WHEN b.inc_source = '17' THEN b.hes_days END) as HES_AS_DAYS,
		sum(CASE WHEN b.inc_source = '28' THEN b.hes_days END) as HES_JSS_DAYS,
		sum(CASE WHEN b.inc_source = '29' THEN b.hes_days END) as HES_SPS_DAYS,
		sum(CASE WHEN b.inc_source = '30' THEN b.hes_days END) as HES_SLP_DAYS,
		sum(CASE WHEN b.inc_source = '31' THEN b.hes_days END) as HES_Other_New_DAYS
	from HES_Income_Bens B
	group by snz_uid
	order by snz_uid;

proc sql;
	create table HES_Individual as
	select a.*, b.*
	from HES_Individual A LEFT JOIN HES_Income_Bens B
	on a.snz_uid = b.snz_uid
	order by snz_uid;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean&version.  );
	create table msd_spell as
	select a.*
	from connection to sqlservr(
		select *
		from msd_clean.msd_spell) A INNER JOIN HES_Individual B
	on A.snz_uid = B.snz_uid
	order by snz_uid;
	disconnect from sqlservr;
quit;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean&version.  );
	create table msd_partner as
	SELECT C.*
	FROM CONNECTION TO SQLSERVR ( 
		SELECT A.*, B.partner_snz_uid AS snz_partner_uid, 
			CASE WHEN B.msd_ptnr_ptnr_from_date > A.msd_spel_spell_start_date 
				THEN B.msd_ptnr_ptnr_from_date
				ELSE A.msd_spel_spell_start_date END AS msd_ptnr_ptnr_from_date,
			CASE WHEN B.msd_ptnr_ptnr_to_date < A.msd_spel_spell_end_date 
				THEN B.msd_ptnr_ptnr_to_date
				ELSE A.msd_spel_spell_end_date END AS msd_ptnr_ptnr_to_date
		  	FROM msd_clean.msd_spell A INNER JOIN msd_clean.msd_partner B
		  ON A.snz_uid = B.snz_uid AND 
			A.msd_spel_spell_start_date <= B.msd_ptnr_ptnr_to_date AND A.msd_spel_spell_end_date >= B.msd_ptnr_ptnr_from_date
			WHERE A.msd_spel_spell_end_date != B.msd_ptnr_ptnr_from_date
		  ORDER BY A.snz_uid, A.msd_spel_spell_start_date
) C INNER JOIN HES_Individual D
	on C.snz_partner_uid = D.snz_uid
	order by snz_uid;
	disconnect from sqlservr;
quit;

data msd_partner (drop= snz_partner_uid msd_ptnr_ptnr_from_date msd_ptnr_ptnr_to_date);
	set msd_partner;
	msd_spel_spell_start_date = msd_ptnr_ptnr_from_date;
	msd_spel_spell_end_date = msd_ptnr_ptnr_to_date;
	snz_uid = snz_partner_uid;
	if msd_spel_spell_start_date = msd_spel_spell_end_date THEN DELETE;
run;

proc format ;
VALUE $bengp_pre2013wr
    '020','320' = "Invalid's Benefit"
    '030','330' = "Widow's Benefit"
    '040','044','340','344'
                = "Orphan's and Unsupported Child's benefits"
    '050','350','180','181'
    = "New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
    '115','604','605','610'
                = "Unemployment Benefit and Unemployment Benefit Hardship"
    '125','608' = "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"
    '313','613','365','665','366','666','367','667'
                = "Domestic Purposes related benefits"
    '600','601' = "Sickness Benefit and Sickness Benefit Hardship"
    '602','603' = "Job Search Allowance and Independant Youth Benefit"
    '607'       = "Unemployment Benefit Student Hardship"
    '609','611' = "Emergency Benefit"
    '839','275' = "Non Beneficiary"
    'YP ','YPP' = "Youth Payment and Young Parent Payment"
        ' '     = "No Benefit"
 ;
value $bennewgp 

'020'=	"Invalid's Benefit"
'320'=	"Invalid's Benefit"

'330'=	"Widow's Benefit"
'030'=	"Widow's Benefit"

'040'=	"Orphan's and Unsupported Child's benefits"
'044'=	"Orphan's and Unsupported Child's benefits"
'340'=	"Orphan's and Unsupported Child's benefits"
'344'=	"Orphan's and Unsupported Child's benefits"

'050'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
'180'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
'181'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"
'350'=	"New Zealand Superannuation and Veteran's and Transitional Retirement Benefit"

'115'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'604'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'605'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'610'=	"Unemployment Benefit and Unemployment Benefit Hardship"
'607'=	"Unemployment Benefit Student Hardship"
'608'=	"Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"
'125'=	"Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)"


'313'=  "Domestic Purposes related benefits"
'365'=	"Sole Parent Support "
'366'=	"Domestic Purposes related benefits"
'367'=	"Domestic Purposes related benefits"
'613'=	"Domestic Purposes related benefits"
'665'=	"Domestic Purposes related benefits"
'666'=	"Domestic Purposes related benefits"
'667'=	"Domestic Purposes related benefits"

'600'=	"Sickness Benefit and Sickness Benefit Hardship"
'601'=	"Sickness Benefit and Sickness Benefit Hardship"

'602'=	"Job Search Allowance and Independant Youth Benefit"
'603'=	"Job Search Allowance and Independant Youth Benefit"

'611'=	"Emergency Benefit"

'315'=	"Family Capitalisation"
'461'=	"Unknown"
'000'=	"No Benefit"
'839'=	"Non Beneficiary"

'370'=  "Supported Living Payment related"
'675'=  "Job Seeker related"
'500'=  "Work Bonus"
;
run  ;

proc format;
value $ADDSERV
'YP'	='Youth Payment'
'YPP'	='Young Parent Payment'
'CARE'	='Carers'
'FTJS1'	='Job seeker Work Ready '
'FTJS2'	='Job seeker Work Ready Hardship'
'FTJS3'	='Job seeker Work Ready Training'
'FTJS4'	='Job seeker Work Ready Training Hardship'
'MED1'	='Job seeker Health Condition and Disability'
'MED2'	='Job seeker Health Condition and Disability Hardship'
'PSMED'	='Health Condition and Disability'
''		='.';
run;

data msd_spell; 
	set msd_spell msd_partner;
	format startdate enddate spellfrom spellto yymmdd10.;
	startdate=input(compress(msd_spel_spell_start_date,"-"),yymmdd10.);
	enddate=input(compress(msd_spel_spell_end_date,"-"),yymmdd10.);
	if msd_spel_prewr3_servf_code='' then prereform=put(msd_spel_servf_code, $bengp_pre2013wr.); 
	else prereform=put(msd_spel_prewr3_servf_code,$bengp_pre2013wr.);	
if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='dpb';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='ib';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='ub';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='iyb';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='sb';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='ucb';
else ben='oth';
length benefit_desc_new $50;
servf=msd_spel_servf_code;
additional_service_data=msd_spel_add_servf_code;
	if  servf in ('602',
				 '603') 
		and additional_service_data ne 'YPP' then benefit_desc_new='1: YP Youth Payment Related' ;

	else if servf in ('313') 
		or additional_service_data='YPP' then benefit_desc_new='1: YPP Youth Payment Related' ;
  
	else if  (servf in (
				   '115',
                   '610', 
                   '611',
				   '030', 
				   '330', 
				   '366',
				   '666'))
		or (servf in ('675') and additional_service_data in (
					'FTJS1', 
					'FTJS2')) 
			
		then benefit_desc_new='2: Job Seeker Work Ready Related'; 

	else if  (servf in ('607', 
				   '608')) 
        or (servf in ('675') and additional_service_data in (
					'FTJS3', 
					'FTJS4'))
		then benefit_desc_new='2: Job Seeker Work Ready Training Related'; 


	else if (servf in('600',
				  '601')) 
		or (servf in ('675') and additional_service_data in (
				'MED1',   
				'MED2'))  
		then benefit_desc_new='3: Job Seeker HC&D Related' ;

	else if servf in ('313',   
				   
				   '365',   
				   '665' )  
		then benefit_desc_new='4: Sole Parent Support Related' ;

	else if (servf in ('370') and additional_service_data in (
						'PSMED', 
						'')) 
		or (servf ='320')    
		or (servf='020')     
		then benefit_desc_new='5: Supported Living Payment HC&D Related' ;

	else if (servf in ('370') and additional_service_data in ('CARE')) 
		or (servf in ('367',  
					  '667')) 
		then benefit_desc_new='6: Supported Living Payment Carer Related' ;

	else if servf in ('999') 
		then benefit_desc_new='7: Student Allowance';

	else if (servf = '050' )
		then benefit_desc_new='Other' ;

	else if benefit_desc_new='Unknown' ;

if prereform in ("Domestic Purposes related benefits", "Widow's Benefit","Sole Parent Support ") then ben='DPB';
else if prereform in ("Invalid's Benefit", "Supported Living Payment related") then ben='IB';
else if prereform in ("Unemployment Benefit and Unemployment Benefit Hardship",
   "Unemployment Benefit Student Hardship", "Unemployment Benefit (in Training) and Unemployment Benefit Hardship (in Training)") then ben='UB';
else if prereform in ("Job Search Allowance and Independant Youth Benefit") then ben='IYB';
else if prereform in ("Sickness Benefit and Sickness Benefit Hardship") then ben='SB';
else if prereform in ("Orphan's and Unsupported Child's benefits") then ben='UCB';
else ben='OTH';

if benefit_desc_new='2: Job Seeker Work Ready Training Related' then ben_new='JSWR_TR';
else if benefit_desc_new='1: YP Youth Payment Related' then ben_new='YP';
else if benefit_desc_new='1: YPP Youth Payment Related' then ben_new='YPP';
else if benefit_desc_new='2: Job Seeker Work Ready Related' then ben_new='JSWR';

else if benefit_desc_new='3: Job Seeker HC&D Related' then ben_new='JSHCD';
else if benefit_desc_new='4: Sole Parent Support Related' then ben_new='SPSR';
else if benefit_desc_new='5: Supported Living Payment HC&D Related' then ben_new='SLP_HCD';
else if benefit_desc_new='6: Supported Living Payment Carer Related' then ben_new='SLP_C';
else if benefit_desc_new='7: Student Allowance' then ben_new='SA';

else if benefit_desc_new='Other' then ben_new='OTH';
if prereform='370' and ben_new='SLP_C' then ben='DPB';
if prereform='370' and ben_new='SLP_HCD' then ben='IB';

if prereform='675' and ben_new='JSHCD' then ben='SB';
if prereform='675' and (ben_new ='JSWR' or ben_new='JSWR_TR') then ben='UB';

run;

proc sql;
	create table MSD_Individual_Benefit as
	select a.*, 
		CASE WHEN MISSING(b.startdate) THEN . 
			ELSE max(b.startdate, intnx('year', a.Interview_Date, -1, "SAME")) END as startdate format yymmdd10., 
		CASE WHEN MISSING(b.startdate) AND MISSING(b.enddate) THEN . 
			ELSE min(b.enddate, a.Interview_Date) END as enddate format yymmdd10.,
		b.startdate as True_Start, b.enddate as True_End,
		CASE WHEN MISSING(b.startdate) THEN . 
			ELSE datdif(max(b.startdate, intnx('year', a.Interview_Date, -1, "SAME")),
				coalesce(min(b.enddate, a.Interview_Date), a.Interview_Date), 'ACT/ACT') END as Days,
		b.prereform, b.benefit_desc_new, ben, ben_new
	from HES_Individual A INNER JOIN msd_spell B
	on A.snz_uid = B.snz_uid and 
		(b.enddate >= intnx('year', a.Interview_Date, -1, "SAME") or MISSING(b.enddate)) and
		b.startdate <= a.Interview_Date
	having Days > 0 
	order by Days;

	create table MSD_Individual_Old as
	select snz_uid, hes_per_hes_year_code, ben, sum(Days) as Days
	from MSD_Individual_Benefit
	group by snz_uid, hes_per_hes_year_code, ben;

	create table MSD_Individual_New as
	select snz_uid, hes_per_hes_year_code, ben_new, sum(Days) as Days
	from MSD_Individual_Benefit
	group by snz_uid, hes_per_hes_year_code, ben_new;
quit;

data MSD_Individual;
	set MSD_Individual_Old MSD_Individual_New;
run;

proc sql ;
	create table MSD_Individual_Wide as
	select distinct snz_uid,
		sum(CASE WHEN b.ben = 'UB' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_UB_DAYS,
		sum(CASE WHEN b.ben = 'IB' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_IB_DAYS,
		sum(CASE WHEN b.ben = 'SB' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_SB_DAYS,
		sum(CASE WHEN b.ben = 'DPB' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_DPB_DAYS,
		sum(CASE WHEN b.ben = 'IYB' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_IYB_DAYS,
		sum(CASE WHEN b.ben = 'UCB' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_UCB_DAYS,
		sum(CASE WHEN b.ben = 'OTH' AND b.hes_per_hes_year_code not in ('1314', '1415') THEN b.days END) as MSD_OTHER_DAYS,
		sum(CASE WHEN b.ben_new in ('JSWR_TR', 'JSWR', 'JSHCD') AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_JSS_DAYS,
		sum(CASE WHEN b.ben_new = 'YP' AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_YP_DAYS,
		sum(CASE WHEN b.ben_new = 'YPP' AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_YPP_DAYS,
		sum(CASE WHEN b.ben_new = 'SPSR' AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_SPS_DAYS,
		sum(CASE WHEN b.ben_new in ('SLP_HCD', 'SLP_C') AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_SLP_DAYS,
		sum(CASE WHEN b.ben_new = 'SA' AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_SA_DAYS,
		sum(CASE WHEN b.ben_new = 'OTH' AND b.hes_per_hes_year_code in ('1314','1415') THEN b.days END) as MSD_OTHER_NEW_DAYS
	from MSD_Individual B
	group by snz_uid;
quit ;

proc sql;
	create table HES_Individual as
	select a.*, b.*
	from HES_Individual A LEFT JOIN MSD_Individual_Wide B
	on a.snz_uid = b.snz_uid
	order by snz_uid;
quit;

proc sql ;
	create table HES_Individual as
	select a.* , b.snz_uid, b.IRD_PEN, b.HES_pensions
	from HES_Individual A LEFT JOIN intdata.comparison_full B
	on a.snz_uid = b.snz_uid 
	order by snz_uid ;
quit ;

data HES_Individual ;
	set HES_Individual ;
	IRD_PEN_IND = 0 ;
	IF IRD_PEN > 1 then IRD_PEN_IND = 1 ;
	HES_PEN_IND = 0 ;
	IF HES_pensions > 1 then HES_PEN_IND = 1 ;
run ;

proc sql;
	create table HES_Individual as
	select a.*, b.ird_linked
	from HES_Individual A LEFT JOIN intdata.comparison_full B
	on a.snz_uid = b.snz_uid
	where b.ird_linked = 1;
quit;

data intdata.HES_Individual_Benefit;
	set HES_Individual;
run;

data HES_Individual_Summary_14_15;
	set HES_Individual;
	HES_Total_Days = MIN(366, max(0, sum(HES_UB_DAYS, HES_SB_DAYS, HES_DPB_DAYS, HES_IB_DAYS, HES_WB_DAYS,
						HES_Orphans_DAYS, HES_IYB_DAYS, HES_EB_DAYS, HES_EMB_DAYS, HES_Other_DAYS,
						HES_JSS_DAYS, HES_SPS_DAYS, HES_SLP_DAYS, HES_Other_New_DAYS)));
	MSD_Total_Days = MIN(366, max(0, sum(MSD_UB_DAYS, MSD_IB_DAYS, MSD_SB_DAYS, MSD_DPB_DAYS, MSD_IYB_DAYS,
						MSD_UCB_DAYS, MSD_OTHER_DAYS, MSD_JSS_DAYS, MSD_YP_DAYS, MSD_YPP_DAYS,
						MSD_SPS_DAYS, MSD_SLP_DAYS, MSD_OTHER_NEW_DAYS)));
	HES_JSS_IND = HES_JSS_DAYS>0;
	HES_SPS_IND = HES_SPS_DAYS>0;
	HES_SLP_IND = HES_SLP_DAYS>0;
	HES_WB_IND = HES_WB_DAYS>0;
	HES_Orphans_IND = HES_Orphans_DAYS>0;
	HES_IYB_IND = HES_IYB_DAYS>0;
	HES_EB_IND = HES_EB_DAYS>0;
	HES_EMB_IND = HES_EMB_DAYS>0;
	HES_Other_IND = HES_Other_DAYS>0;
	HES_Other_New_IND = HES_Other_New_DAYS > 0;


	MSD_JSS_IND = MSD_JSS_DAYS>0;
	MSD_SPS_IND = MSD_SPS_DAYS>0;
	MSD_SLP_IND = MSD_SLP_DAYS>0;
	MSD_IYB_IND = MSD_IYB_DAYS>0;
	MSD_UCB_IND = MSD_UCB_DAYS>0;
	MSD_Other_IND = MSD_Other_DAYS>0;
	MSD_Other_New_IND = MSD_Other_New_DAYS>0;
	MSD_YP_IND = MSD_YP_DAYS >0;
	MSD_YPP_IND = MSD_YPP_DAYS > 0;

	HES_ALL_IND = max(HES_JSS_IND , HES_SPS_IND, HES_SLP_IND, HES_WB_IND, HES_Orphans_IND,
						HES_IYB_IND, HES_EB_IND, HES_EMB_IND, HES_Other_IND, HES_Other_New_IND) ;
	MSD_ALL_IND = max(MSD_JSS_IND, MSD_SPS_IND, MSD_SLP_IND, MSD_IYB_IND, 
						MSD_UCB_IND, MSD_Other_IND, MSD_Other_New_Ind, MSD_YP_IND, MSD_YPP_IND) ;	
 
	if MISSING(HES_Total_Days) and MISSING(MSD_Total_Days) then Diff_Total = .; 
	else Diff_Total = sum(MIN(366, max(0, MSD_Total_Days)), -MIN(366, max(0, HES_Total_DAYS)), 0);
	if MISSING(HES_UB_DAYS) and MISSING(MSD_UB_DAYS) then Diff_UB = .; 
	else Diff_UB = sum(MSD_UB_DAYS, -HES_UB_DAYS, 0);
	if MISSING(HES_DPB_DAYS) and MISSING(MSD_DPB_DAYS) then Diff_DPB = .; 
	else Diff_DPB = sum(MSD_DPB_DAYS, -HES_DPB_DAYS, 0);
	if MISSING(HES_IB_DAYS) and MISSING(MSD_IB_DAYS) then Diff_IB = .; 
	else Diff_IB = sum(MSD_IB_DAYS, -MIN(366, max(HES_IB_DAYS,0)), 0);
	if MISSING(HES_SB_DAYS) and MISSING(MSD_SB_DAYS) then Diff_SB = .; 
	else Diff_SB = sum(MIN(366, max(0, MSD_SB_DAYS)), -MIN(366, max(0, HES_SB_DAYS)), 0);
	if MISSING(HES_JSS_DAYS) and MISSING(MSD_JSS_DAYS) then Diff_JSS = .; 
	else Diff_JSS = sum(MSD_JSS_DAYS, -MIN(366, max(0, HES_JSS_DAYS)), 0);
	if MISSING(HES_SPS_DAYS) and MISSING(MSD_SPS_DAYS) then Diff_SPS = .; 
	else Diff_SPS = sum(MSD_SPS_DAYS, -HES_SPS_DAYS, 0);
	if MISSING(HES_SLP_DAYS) and MISSING(MSD_SLP_DAYS) then Diff_SLP = .; 
	else Diff_SLP = sum(MSD_SLP_DAYS, -HES_SLP_DAYS, 0);

	if snz_spine_ind = 0 or hes_per_age_nbr < 15 then DELETE;
	if hes_per_hes_year_code ne '1415' then DELETE;
run;

ods tagsets.ExcelXP file= "benefittabs_newbs.xls" style=minimal options(orientation= 'landscape') ; /* File path removed */

proc tabulate data=HES_Individual_Summary_14_15;
	class HES_JSS_IND HES_SPS_IND HES_SLP_IND MSD_JSS_IND MSD_SPS_IND MSD_SLP_IND HES_ALL_IND MSD_ALL_IND IRD_PEN_IND HES_PEN_IND;
	table (HES_JSS_IND HES_SPS_IND HES_SLP_IND HES_PEN_IND),(HES_JSS_IND HES_SPS_IND HES_SLP_IND MSD_JSS_IND MSD_SPS_IND MSD_SLP_IND IRD_PEN_IND) ;
	table HES_ALL_IND , MSD_ALL_IND ;
	table HES_PEN_IND, IRD_PEN_IND ;
run;

ods tagsets.excelxp close ;

proc sgpanel data=HES_Individual_Summary_14_15;
	panelby hes_SLP_IND msd_SLP_IND ;
	histogram Diff_SLP / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Supported living payments (14/15)";
run;

proc sgplot data=HES_Individual_Summary_14_15;
	histogram Diff_SLP / transparency=0.5 binstart=-359 binwidth=14;
	title "Supported Living Payment (14/15)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_14_15;
	panelby hes_SPS_IND msd_SPS_IND ;
	histogram Diff_SPS / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Sole Parent Support (14/15)";
run;

proc sgplot data=HES_Individual_Summary_14_15;
	histogram Diff_SPS / transparency=0.5 binstart=-359 binwidth=14;
	title "Sole Parent Support (14/15)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgplot data=HES_Individual_Summary_14_15;
	histogram Diff_JSS / transparency=0.5 binstart=-359 binwidth=14;
	title "Job Seeker Support (14/15)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_14_15;
	panelby hes_JSS_IND msd_JSS_IND ;
	histogram Diff_JSS / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Job Seeker Support (14/15)";
run;

proc sgplot data=HES_Individual_Summary_14_15(where=(hes_ALL_IND OR msd_ALL_IND));
	histogram Diff_Total / transparency=0.5 binstart=-359 binwidth=14;
	title "Any Benefit (14/15)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_14_15;
	panelby hes_ALL_IND msd_ALL_IND ;
	histogram Diff_Total / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Any Benefit (14/15)";
run;

proc sql;
	create table Anomaly as
	select *
	from HES_Individual_Summary_14_15
	where (HES_ALL_IND = 0 AND MSD_ALL_IND = 1 AND Diff_Total < 0) OR 
			(HES_ALL_IND = 1 AND MSD_ALL_IND = 0 AND Diff_Total > 0);
quit;

data HES_Individual_Summary_Old;
	set HES_Individual;
	HES_Total_Days = MIN(366, max(0, sum(HES_UB_DAYS, HES_SB_DAYS, HES_DPB_DAYS, HES_IB_DAYS, HES_WB_DAYS,
						HES_Orphans_DAYS, HES_IYB_DAYS, HES_EB_DAYS, HES_EMB_DAYS, HES_Other_DAYS)));
	MSD_Total_Days = MIN(366, max(0, sum(MSD_UB_DAYS, MSD_IB_DAYS, MSD_SB_DAYS, MSD_DPB_DAYS, MSD_IYB_DAYS,
						MSD_UCB_DAYS, MSD_OTHER_DAYS, MSD_OTHER_NEW_DAYS)));
	HES_UB_IND = HES_UB_DAYS>0;
	HES_SB_IND = HES_SB_DAYS>0;
	HES_IB_IND = HES_IB_DAYS>0;
	HES_DPB_IND = HES_DPB_DAYS>0;

	HES_WB_IND = HES_WB_DAYS>0;
	HES_Orphans_IND = HES_Orphans_DAYS>0;
	HES_IYB_IND = HES_IYB_DAYS>0;
	HES_EB_IND = HES_EB_DAYS>0;
	HES_EMB_IND = HES_EMB_DAYS>0;
	HES_Other_IND = HES_Other_DAYS>0;
	HES_ALL_IND = max(HES_UB_IND, HES_SB_IND, HES_IB_IND, HES_DPB_IND, HES_WB_IND, HES_Orphans_IND,
						HES_IYB_IND, HES_EB_IND, HES_EMB_IND, HES_Other_IND) ;

	MSD_UB_IND = MSD_UB_DAYS>0;
	MSD_SB_IND = MSD_SB_DAYS>0;
	MSD_IB_IND = MSD_IB_DAYS>0;
	MSD_DPB_IND = MSD_DPB_DAYS>0;

	MSD_IYB_IND = MSD_IYB_DAYS>0;
	MSD_UCB_IND = MSD_UCB_DAYS>0;
	MSD_Other_IND = MSD_Other_DAYS>0;
	MSD_Other_New_IND = MSD_Other_New_DAYS>0;
	MSD_ALL_IND = max(MSD_UB_IND, MSD_SB_IND, MSD_IB_IND, MSD_DPB_IND, MSD_IYB_IND, 
						MSD_UCB_IND, MSD_Other_IND, MSD_Other_New_Ind) ;

	if MISSING(HES_Total_Days) and MISSING(MSD_Total_Days) then Diff_Total = .; 
	else Diff_Total = sum(MIN(366, max(0, MSD_Total_Days)), -MIN(366, max(0, HES_Total_DAYS)), 0);
	if MISSING(HES_UB_DAYS) and MISSING(MSD_UB_DAYS) then Diff_UB = .; 
	else Diff_UB = sum(MSD_UB_DAYS, -HES_UB_DAYS, 0);
	if MISSING(HES_DPB_DAYS) and MISSING(MSD_DPB_DAYS) then Diff_DPB = .; 
	else Diff_DPB = sum(MSD_DPB_DAYS, -HES_DPB_DAYS, 0);
	if MISSING(HES_IB_DAYS) and MISSING(MSD_IB_DAYS) then Diff_IB = .; 
	else Diff_IB = sum(MSD_IB_DAYS, -MIN(366, max(0,HES_IB_DAYS)), 0);
	if MISSING(HES_SB_DAYS) and MISSING(MSD_SB_DAYS) then Diff_SB = .; 
	else Diff_SB = sum(MIN(366, max(0, MSD_SB_DAYS)), -MIN(366, max(0, HES_SB_DAYS)), 0);
	if MISSING(HES_JSS_DAYS) and MISSING(MSD_JSS_DAYS) then Diff_JSS = .; 
	else Diff_JSS = sum(MSD_JSS_DAYS, -MIN(366, max(0 , HES_JSS_DAYS)), 0);
	if MISSING(HES_SPS_DAYS) and MISSING(MSD_SPS_DAYS) then Diff_SPS = .; 
	else Diff_SPS = sum(MSD_SPS_DAYS, -HES_SPS_DAYS, 0);
	if MISSING(HES_SLP_DAYS) and MISSING(MSD_SLP_DAYS) then Diff_SLP = .; 
	else Diff_SLP = sum(MSD_SLP_DAYS, -HES_SLP_DAYS, 0);
	if snz_spine_ind = 0 or hes_per_age_nbr < 15 then DELETE;
	if hes_per_hes_year_code in ('1314', '1415') then DELETE;
run;
ods tagsets.ExcelXP file= "benefittabs_obs.xls" style=minimal options(orientation= 'landscape') ; /* File path removed */
proc tabulate data=HES_Individual_Summary_Old;
	class HES_UB_IND HES_IB_IND HES_SB_IND HES_DPB_IND MSD_UB_IND MSD_IB_IND MSD_SB_IND MSD_DPB_IND HES_ALL_IND MSD_ALL_IND HES_PEN_IND IRD_PEN_IND ;
	table (HES_UB_IND HES_IB_IND HES_SB_IND HES_DPB_IND HES_PEN_IND),(HES_UB_IND HES_IB_IND HES_SB_IND HES_DPB_IND MSD_UB_IND MSD_IB_IND MSD_SB_IND MSD_DPB_IND IRD_PEN_IND);
	table HES_ALL_IND , MSD_ALL_IND ;
	table HES_PEN_IND , IRD_PEN_IND ;
run;
ods tagsets.ExcelXP close;

proc sgpanel data=HES_Individual_Summary_Old ;
	panelby hes_UB_IND msd_UB_IND ;
	histogram Diff_UB / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Unemployment Benefit (06/07 to 12/13)";
run;

proc sgplot data=HES_Individual_Summary_Old;
	histogram Diff_UB / transparency=0.5 binstart=-359 binwidth=14;
	title "Unemployment Benefit (06/07 to 12/13)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_Old ;
	panelby hes_SB_IND msd_SB_IND ;
	histogram Diff_SB / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Sickness Benefit  (06/07 to 12/13)";
run;

proc sgplot data=HES_Individual_Summary_Old;
	histogram Diff_SB / transparency=0.5 binstart=-359 binwidth=14;
	title "Sickness Benefit  (06/07 to 12/13)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_Old ;
	panelby hes_IB_IND msd_IB_IND ;
	histogram Diff_IB / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Invalids Benefit (06/07 to 12/13)";
run;

proc sgplot data=HES_Individual_Summary_Old;
	histogram Diff_IB / transparency=0.5 binstart=-359 binwidth=14;
	title "Invalids Benefit  (06/07 to 12/13)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_Old ;
	panelby hes_DPB_IND msd_DPB_IND ;
	histogram Diff_DPB / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Domestic Purposes Benefit  (06/07 to 12/13)";
run;

proc sgplot data=HES_Individual_Summary_Old;
	histogram Diff_DPB / transparency=0.5 binstart=-359 binwidth=14;
	title "Domestic Purposes Benefit  (06/07 to 12/13)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgplot data=HES_Individual_Summary_Old(where=(hes_ALL_IND OR msd_ALL_IND));
	histogram Diff_Total / transparency=0.5 binstart=-359 binwidth=14;
	title "Any Benefit (14/15)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sql;
	create table Anomaly2 as
	select *
	from HES_Individual_Summary_Old
	where (HES_ALL_IND = 0 AND MSD_ALL_IND = 1 AND Diff_Total < 0) OR 
			(HES_ALL_IND = 1 AND MSD_ALL_IND = 0 AND Diff_Total > 0);
quit;

proc sgpanel data=HES_Individual_Summary_Old;
	panelby hes_ALL_IND msd_ALL_IND ;
	histogram Diff_Total / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Any Benefit (14/15)";
run;

proc sql;
	CONNECT TO sqlservr (server=WPRDSQL36\iLeed database=IDI_clean&version.  );
	create table msd_ste as
	select a.snz_uid, input(compress(msd_ste_start_date,"-"),yymmdd10.) as msd_ste_start_date format yymmdd10., 
		input(compress(msd_ste_end_date,"-"),yymmdd10.) as msd_ste_end_date format yymmdd10.
	from connection to sqlservr(
		select *
		from msd_clean.msd_second_tier_expenditure
		where msd_ste_supp_serv_code in (470, 471) AND msd_ste_end_date > '01/01/2005') A INNER JOIN HES_Individual B
	on A.snz_uid = B.snz_uid
	order by snz_uid;
	disconnect from sqlservr;
quit;

proc sql;
	create table MSD_AS as
	select a.*, 
		CASE WHEN MISSING(b.msd_ste_start_date) THEN . 
			ELSE max(b.msd_ste_start_date, intnx('year', a.Interview_Date, -1, "SAME")) END as startdate format yymmdd10., 
		CASE WHEN MISSING(b.msd_ste_start_date) AND MISSING(b.msd_ste_end_date) THEN . 
			ELSE min(b.msd_ste_end_date, a.Interview_Date) END as enddate format yymmdd10.,
		CASE WHEN MISSING(b.msd_ste_start_date) THEN . 
			ELSE datdif(max(b.msd_ste_start_date, intnx('year', a.Interview_Date, -1, "SAME")),
				coalesce(min(b.msd_ste_end_date, a.Interview_Date), a.Interview_Date), 'ACT/ACT') END as Days,
		'AS' as ben, 'AS' as ben_new
	from HES_Individual A INNER JOIN msd_ste B
	on A.snz_uid = B.snz_uid and 
		(b.msd_ste_end_date>= intnx('year', a.Interview_Date, -1, "SAME") or MISSING(b.msd_ste_end_date)) and
		b.msd_ste_start_date<= a.Interview_Date
	having Days > 0 
	order by Days;
	create table MSD_AS as
	select snz_uid, hes_per_hes_year_code, ben, min(366, sum(Days)) as MSD_AS_DAYS
	from MSD_AS
	group by snz_uid, hes_per_hes_year_code, ben;
quit;

proc sql;
	create table HES_Individual as
	select a.*, b.*
	from HES_Individual A LEFT JOIN MSD_AS B
	on a.snz_uid = b.snz_uid
	order by snz_uid;
quit;

data HES_Individual_Summary_AS;
	set HES_Individual;
	HES_AS_IND = HES_AS_DAYS>=0;
	MSD_AS_IND = MSD_AS_DAYS>=0;
	if MISSING(HES_AS_DAYS) and MISSING(MSD_AS_DAYS) then Diff_UB = .; 
	else Diff_AS = sum(MSD_AS_DAYS, -HES_AS_DAYS, 0);
	if snz_spine_ind = 0 or hes_per_age_nbr < 15 then DELETE;
run;

ods tagsets.ExcelXP file= "benefittabs_AS.xls" style=minimal options(orientation= 'landscape') ; /* File path removed */

proc tabulate data=HES_Individual_Summary_AS;
	title 'Accomodation Supplement (06/07 to 14/15)' ;
	class HES_AS_IND MSD_AS_IND;
	table HES_AS_IND,MSD_AS_IND;
run;

ods tagsets.ExcelXP close ;

proc sgplot data=HES_Individual_Summary_AS;
	histogram Diff_AS / transparency=0.5 binstart=-359 binwidth=14;
	title "Accommodation Supplement  (06/07 to 14/15)";
	xaxis label = "Days difference (MSD > HES +, HES > MSD -)";
	yaxis label = "% of respondents with either HES or MSD benefit record";
run;

proc sgpanel data=HES_Individual_Summary_AS ;
	panelby hes_AS_IND msd_AS_IND ;
	histogram Diff_AS / transparency=0.5 binstart=-359 binwidth=14  ;
	title "Accommodation Supplement  (06/07 to 14/15)";
run;


