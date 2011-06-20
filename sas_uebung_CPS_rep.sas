/* PSID 2003-2007 

Datenaufbereitung:

1) 	Nur Personen im Alter 21-65 Jahre
2) 	Nur Personen, die in 2003 Respondenten waren (i.e. kein Nonresponse, 
	keine Personen in Institutionen.
3)  

*/

options nofmterr fmtsearch = (work cps.formats) mstored sasmstore = sasuser;

%include "&dataDir\CPS\CPS_ASEC_ASCII_REPWGT_2009.SAS";
%include "&dataDir\CPS\CPS_suppl_MAR09_input.sas";

proc contents data = cps.mar09sup; run;
proc contents data = cps.repwgt_2009; run;


proc sort data = cps.mar09sup; by H_SEQ PPPOS; run;
proc sort data = cps.repwgt_2009; by H_SEQ PPPOS; run;

data cps.mar09sup;
	merge 
		cps.mar09sup
		cps.repwgt_2009
	;
	by H_SEQ PPPOS;
run;

proc sort data = cps.mar98; by HRHHID HUHHNUM PULINENO; run;
proc sort data = cps.mar99; by HRHHID HUHHNUM PULINENO; run;


%renameAll(cps, mar99,,1, HRHHID HUHHNUM PULINENO);


data cps.mar98_h; 
	set cps.mar98; 
	by HRHHID; 
	
	if first.HRHHID; 
run;

data cps.mar99_h; 
	set cps.mar99; 
	by HRHHID;

	if first.HRHHID; 
run; 


data cps.test_h;
	merge  
		cps.mar98_h(in = in98 where = (HRMIS in (1, 2, 3, 4)))
		cps.mar99_h(in = in99 where = (HRMIS1 in (5, 6, 7, 8)))
		;
	by HRHHID HUHHNUM;
	in_98 = in98;
	in_99 = in99;
run;

proc freq data = cps.test_h;
	tables in_98*in_99;
run;


data cps.test;
	merge 
		cps.mar98(in = in98 where = (HRMIS in (1, 2, 3, 4)))
		cps.mar99(in = in99 where = (HRMIS1 in (5, 6, 7, 8)))
		;
	by HRHHID HUHHNUM PULINENO;
	
	in_98 = in98;
	in_99 = in99;
run;

proc freq data = cps.test;
	tables in_98*in_99;
run;



data cps.h_dec00;
	set cps.dec00;
	by HRHHID;
	if first.hrhhid;
run;

proc sql;
	select count(distinct HRHHID) from cps.dec00;
quit;

proc freq data = cps.h_dec00;
	tables HUFAMINC /missing;
run;



proc freq data = cps.h_dec00;
	tables _all_ /missing;
run;
