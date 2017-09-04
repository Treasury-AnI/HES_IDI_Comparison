proc datasets lib=work kill nolist memtype=data ;
quit ;

ods graphics ;

data comparison ;
	set intdata.comparison_full ;
run ;

proc format ;
	value myfmt
	low - -25000 = '<-25,000'
	-25000 - -10000 = '-25,000 to -10,000'
	-10000 - -5000 = '-10,000 to - 5,000'
	-5000 - -1000 = '-5000 to -1000'
	-1000 - 1000 = '-1,000 to 1,000'
	1000 - 5000 = '1,000 to 5,000'
	5000 - 10000 = '5,000 to 10,000'
	10000 - 25000 = '10000 to 25000'
	25000 - high = '25,000+'
	;
run ;

proc format ;
	value crosstab
	low - -1 = 'Negative'
	-1 - 1 = 'Zero'
	1 - 1000 = 'Zero to 1k'
	1000 - 5000 = '1k to 5k'
	5000 - 10000 = '5k to 10k'
	10000 - 15000 = '10k to 15k'
	15000 - 20000 = '15k to 20k'
	20000 - 25000 = '20k to 25k'
	25000 - 30000 = '25k to 30k'
	30000 - 35000 = '30k to 35k'
	35000 - 40000 = '35k to 40k'
	40000 - 45000 = '40k to 45k'
	45000 - 50000 = '45k to 50k'
	50000 - 60000 = '50k to 60k'
	60000 - 70000 = '60k to 70k'
	70000 - 80000 = '70k to 80k'
	80000 - 90000 = '80k to 90k'
	90000 - 100000 = '90k to 100k'
	100000 - 120000 = '100k to 120k'
	120000 - high = '120k+'
	 ;
run ;

ods Excel file= "crosstabs.xlsx" style=minimal options(orientation= 'landscape') ; /* File path removed */

proc freq data=comparison ;
	format hes_overall_new ird_overall_new crosstab. ;
	tables ird_overall_new*hes_overall_new / Nocum nopercent nocol norow ;
run ;

proc freq data=comparison ;
	format hes_wages ird_wages crosstab. ;
	tables ird_wages*hes_wages / Nocum nopercent nocol norow ;
run ;

proc format ;
	value crosstab_self
	low - -1 = 'Negative'
	-1 - 1 = 'Zero'
	1 - 10000 = 'Zero to 10k'
	10000 - 30000 = '10k to 30k'
	30000 - 60000 = '30k to 60k'
	60000 - 100000 = '60k to 100k'
	100000 - high = '100k+' ;
run ;

proc freq data=comparison ;
	format hes_self ird_self crosstab_self. ;
	tables ird_self*hes_self / Nocum nopercent norow nocol ;
run ;

proc freq data=comparison ;
	format hes_wages_and_self ird_wages_and_self crosstab. ;
	tables ird_wages_and_self*hes_wages_and_self / Nocum nopercent norow nocol ;
run ;

proc format ;
	value crosstab_PEN
	low - -1 = 'Negative'
	-1 - 1 = 'Zero'
	1 - 10000 = 'zero to 10k' 
	10000 - 12500 = '10k to 12.5k'
	12500 - 15000 = '12.5k to 15k'
	15000 - 17500 = '15k to 17.5k'
	17500 - 20000 = '17.5k to 20k'
	20000 - 22500 = '20k  to 22.5k'
	22500 - high = '22.5k+'
 ;
run ;

proc freq data=comparison ;
	format hes_pensions ird_PEN crosstab_PEN. ;
	tables ird_PEN*hes_pensions / Nocum nopercent norow nocol ;
run ;

proc freq data=comparison ;
	where hes_per_hes_year_code = '1415' ;
	format hes_pensions ird_PEN crosstab_PEN. ;
	tables ird_PEN*hes_pensions / Nocum nopercent norow nocol ;
run ;

ods excel close ;

%macro diff_inspect (irdvar= , hesvar = , diffvar =, data=) ;
	title "&hesvar vs. &irdvar" ;
	
	proc freq data=&data  ;
		format &diffvar myfmt. ;
		TABLES &diffvar / Nocum Scores=Table plots(only) = freq ;
	run ;	
	
	title "&hesvar var vs. &irdvar (excludes obs where either &hesvar = 0 OR &irdvar = 0)" ;

	proc freq data=&data  ;
		where NOT( &hesvar = 0 OR &irdvar = 0 ) ;
		format &diffvar myfmt. ;
		TABLES &diffvar / Nocum Scores=Table plots(only) = freq ;
	run ;
	
	title "&hesvar var vs. &irdvar (excludes obs where borth &hesvar = 0 AND &irdvar = 0)" ;

	proc freq data=&data  ;
		where NOT ( &hesvar = 0 AND &irdvar = 0 ) ;
		format &diffvar myfmt. ;
		TABLES &diffvar / Nocum Scores=Table plots(only) = freq ;
	run ;

	PROC sgplot data=&data ;
		title " &hesvar vs. &irdvar (w/ 45 degree line)" ;
		scatter x=&irdvar	
			y= &hesvar  ;
		lineparm x=0 y=0 slope=1 ;
	RUN ;
	
	data &data._temp ;
		set &data ;
		&hesvar = &hesvar + rand1 ;
		&irdvar = &irdvar + rand2 ;
	run ;

	PROC sgplot data=&data._temp ;
		where rand < 0.05  and (&hesvar. - rand1) >= 0 and (&irdvar. - rand2) >= 0;
		scatter x=&irdvar	
			y= &hesvar ;
		lineparm x=0 y=0 slope=1 ;
		xaxis max=120000 ;
		yaxis max= 120000 ;
		title " &hesvar vs. &irdvar (w/ 45 degree line, restricted axis, 5% rand sample)" ;
		inset 'Data have been confidentialised:' 'Outliers have been removed, the underlying data jittered,' 'and only a small random sample shown.' / BORDER POSITION=TOPLEFT  ;
	RUN ;	
run ;

%mend diff_inspect ; 
%diff_inspect (irdvar=ird_overall_new, hesvar=hes_overall_new, diffvar=diff_overall_new ,data=comparison) ;

%diff_inspect (irdvar=ird_wages , hesvar=hes_wages, diffvar=diff_wages ,data=comparison) ;

%diff_inspect (irdvar=ird_self, hesvar=hes_self, diffvar=diff_self ,data=comparison) ;

proc sgplot  data=comparison ;
	scatter x=ird_self 
			y= hes_self ;
	lineparm x=0 y=0 slope=1 ;
	title "HES self-employment income vs. IRD self-employment income (w/ 45 degree line, restricted axis, 5% random sample)" ;
	xaxis label= 'IRD Self-employment income' ;
	yaxis label= 'HES Self-employment income' ;
run ;

data temporary ;
	set comparison ;
	ird_self2 = ird_self + rand1 ;
	hes_self2 = hes_self + rand2 ;
run ;

proc sgplot  data=temporary ;
	where rand < 0.05 and  (hes_self - rand1 < 120000) and (ird_self - rand2 < 120000) and (hes_self > -50000) and (ird_self > - 50000)  ;
	scatter x=ird_self2 
			y= hes_self2 ;
	lineparm x=0 y=0 slope=1 ;
	title "HES self-employment income vs. IRD self-employment income (w/ 45 degree line, restricted axis, 5% random sample)" ;
	xaxis label= 'IRD self-employment income' max=120000 ;
	yaxis label= 'HES self-employment income' max= 120000 ;
	inset 'Data have been confidentialised:' 'Outliers have been removed, the underlying data jittered,' 'and only a small random sample shown.' / BORDER POSITION=TOPLEFT  ;
run ;

%diff_inspect (irdvar=ird_wages_and_self, hesvar=hes_wages_and_self, diffvar=diff_wages_and_self ,data=comparison) ;

%diff_inspect (irdvar=ird_S03, hesvar=hes_rent, diffvar=diff_rent ,data=comparison) ;

%diff_inspect (irdvar=ird_PEN, hesvar=hes_pensions, diffvar=diff_pensions ,data=comparison) ;

data Comparison_temp ;
		set comparison ;
		hes_pensions = hes_pensions + rand1 ;
		ird_pensions = ird_PEN + rand2 ;
	run ;

PROC sgplot data=comparison_temp ;
		where rand < 0.2 and hes_per_hes_year_code = '1415';
		title " hes pensions vs. ird pensions (w/ 45 degree line)" ;
		scatter x=ird_pensions	
			y= hes_pensions  ;
		lineparm x=0 y=0 slope=1 ;
		inset 'Data have been confidentialised:' 'Outliers have been removed, the underlying data jittered,' 'and only a small random sample shown.' / BORDER POSITION=TOPLEFT  ;
	RUN ;

%diff_inspect (irdvar=ird_PPL, hesvar=hes_PPL, diffvar=diff_PPL ,data=comparison) ;

%diff_inspect (irdvar=ird_STU, hesvar=hes_STU, diffvar=diff_STU ,data=comparison) ;

proc format ;
	value percentcat
	low - - 100 = '< -100%'
	-100 - -50 = '-100% to -50%'
	-50 - -25 = ' -50 to -25%'
	-25 - -10 = '-25% to -10%'
	-10 - -2 = '10% to -2%'
	-2 - 2 = '-2% to 2%'
	2 - 10 = '2% to 10%'
	10 - 25 = '10% to 25%'
	25 - 50 = '25% - 50%'
	50 - 100 = '50% - 100%'
	100 - high = '100%+'
 ;
run ;

data comparison ;
	set comparison ;
	diff_overall_pc_hes = 100*(diff_overall_new / abs(hes_overall_new) ) ;
	diff_wages_pc_hes = 100*(diff_wages / abs(hes_wages) ) ;
run ;

ods tagsets.ExcelXP file= "percent histograms.xls" style=minimal options(orientation= 'landscape' contents='yes' index='yes' embedded_titles='yes' embedded_footnotes='yes') ; /* File path removed */

proc freq data= comparison ;
	 	title '(IRD overall income - HES overall income)/|HES overall income|' ;
		footnote 'Only includes people where overall income is over 10k in HES .' ;
		where (hes_overall_new >= 10000) AND (IRD_linked > 0)  ;
		format diff_overall_pc_hes percentcat. ;
		TABLES diff_overall_pc_hes / Nocum Scores=Table ;
run ;

proc freq data= comparison ;
	 	title '(IRD wages - HES wages)/|HES wages|' ;
		footnote 'Only includes people where their wage is over 10k in HES ' ;
		where (hes_wages >= 10000) AND (IRD_linked > 0);
		format diff_wages_pc_hes percentcat. ;
		TABLES diff_wages_pc_hes / Nocum Scores=Table ;
run ;

ods tagsets.ExcelXP close ;
