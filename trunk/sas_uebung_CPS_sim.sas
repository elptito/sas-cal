/* PSID 2003-2007 

Datenaufbereitung:

1) 	Nur Personen im Alter 21-65 Jahre
2) 	Nur Personen, die in 2003 Respondenten waren (i.e. kein Nonresponse, 
	keine Personen in Institutionen.
3)  

*/

options nofmterr fmtsearch = (work psid.formats) mstored sasmstore = sasuser;

proc contents data = psid.p0107; run;

proc freq data = psid.p0107;
	format _all_;
	tables empl_stat1 educ1 age1 children_n1 sex /missing;
run;

data psid.simpop;
	set psid.p0107;
	if empl_stat1 in (9, 98, 99) then delete;

	/* Beschaeftigungsstatus zusammenfassen */
	if empl_stat1 = 1 then empl_stat1 = 1;
	else empl_stat1 = 2;

	if children_n1 > 1 then children_n1 = 2;
	else children_n1 = 1;

	if health_ins1_1 = 0 then health_ins = 1;
	else health_ins = 0;
	
	%cut(var = educ1, newvar=educ1Gr, breaks = 11 12);
	
	%cut(var = age1, newvar=age1Gr, breaks= 30 50);
run;


proc freq data = psid.simpop;
	*format _all_;
	tables empl_stat1 educ1Gr age1Gr children_n1 sex /missing;
run;

/* Generate response propensities... */


proc logistic data = psid.simpop outdesign = resp_desmat(drop = age1) outdesignonly;
	class empl_stat1 educ1Gr age1Gr children_n1 sex / param = reference ref = last order = formatted;
	model age1 = empl_stat1 educ1Gr children_n1 sex age1Gr;
run;

data resp_prob;
	set resp_desmat;
	
	linpr = 1.5*Intercept + 0.5*empl_stat1Temp__laid_off - 0.8*educ1Gr1 - 0.2*educ1Gr2 + 0.6*sexFemale - 0.2*age1Gr1;
	resp_prob = exp(linpr)/(1 + exp(linpr));
run;


data psid.simpop;
	merge psid.simpop resp_prob;
run;




/* Nun simulieren wir die Ziehung von 1000 Stichproben... */


proc surveyselect noprint
	data = psid.simpop
	method = SRS
	samprate = 20
	rep = 200
	stats
	out = psid.sim_smpl;
run;


/* Nun simulieren wir das response Verhalten */

proc sort data = psid.sim_smpl; by replicate; run;


data 	psid.sim_smpl(where = (resp = 1)) 
		psid.sim_smpl_aggr(keep = replicate resp_n);
	
	set psid.sim_smpl; 
	by replicate; 
	
	resp = ranbin(0, 1, resp_prob); 
	
	if first.replicate then
		do;
			resp_n = 0;
		end;

	resp_n + resp;
	
	if last.replicate then output psid.sim_smpl_aggr;

	output psid.sim_smpl; 
run;


data psid.sim_smpl;
	merge psid.sim_smpl(drop = resp_n)
			psid.sim_smpl_aggr;
	by replicate;
run;



/* Jetzt schaetzen wir den Mittelwert von */

%macro estimateRepl(dat=, replicate_ind=replicate, simname=);
	%local n_rep;

	proc sql noprint;
		select count(distinct &replicate_ind) into :n_rep
		from &dat;
		%if &SQLOBS = 0 %then %goto exit;
	quit;

	%let n_rep = %left(&n_rep);


	/** Set up CLAN **/
	
	%macro function(i, j);
		%tot(not_ins_tot, health_ins, 1);
		%tot(p_size, 1, 1);
		%div(not_ins_p, not_ins_tot, p_size);

		%estim(not_ins_p);
	%mend;
	
	%do i = 1 %to &n_rep;
		
		data rep&i;
			set &dat(where = (&replicate_ind = &i));
		run;
		
		%clan(data = rep&i, npop = 9837, nresp = resp_n, maxrow = 1, maxcol = 1);

		data Dut&i;
			set Dut;
			replicate = &i;
		run;
	%end;
	
	data Dut_&simname;
		set Dut1-Dut&n_rep;
		__unit__ = 1;
	run;
	
	proc means data = Dut_&simname noprint;
	by row col;
	var p:;
		output
			out = Dut_&simname._means mean= std= /autoname;
	run;

	/** Clean up **/
	proc datasets library = work;
		delete Dut1-Dut&n_rep rep1-rep&n_rep;
	run; quit;

%exit:
%mend estimateRepl;

%estimateRepl(dat = psid.sim_smpl, simname = all);

proc boxplots data = Dut_all;
	plot pnot_ins_p*__unit__ /vref = 0.166;
run;






proc freq data = psid.simpop;
	tables health_ins;
run;
































