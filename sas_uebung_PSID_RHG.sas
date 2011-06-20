
data Dut_all;
   set Dut_RHG Dut_ohne_RHG;
run;
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
	tables empl_stat1 educ1 age1 children_n1 sex rel2head1 head_marst1/missing;
run;


proc freq data = psid.simpop;
	*format _all_;
	tables empl_stat1 educ1Gr age1Gr children_n1 sex rel2head1 head_marst1/missing;
run;

proc sort data = psid.p0107; by intvw1 descending rel2head1; run;

data psid.simpop;
	set psid.p0107;
	by intvw1;
	if empl_stat1 in (9, 98, 99) then delete;

	/* Beschaeftigungsstatus zusammenfassen */
	if empl_stat1 = 1 then empl_stat1 = 1;
	else empl_stat1 = 2;

	if children_n1 > 1 then children_n1 = 2;
	else children_n1 = 1;

	if health_ins1_1 = 0 then health_ins = 1;
	else health_ins = 0;

	if hval1 > 0 then owner = 1;
	else owner = 2;
	
	%cut(var = educ1, newvar=educ1Gr, breaks = 11 12);
	
	%cut(var = age1, newvar=age1Gr, breaks= 30 50);

	if first.intvw1 then fam_size = 0;

	fam_size + 1;

	if last.intvw1 then output;
run;

proc sort data = psid.simpop; by owner; run;

proc means data = psid.simpop;
	var fam_inc1 debt_val1 health_ins;
	by owner;
	output 
		out = by_owner_split
		mean = 
		/autoname
		;
run;


proc freq data = psid.simpop;
	tables owner;
run;



/* Generate response propensities... */

proc logistic data = psid.simpop outdesign = resp_desmat(drop = age1) outdesignonly;
	class empl_stat1 educ1Gr age1Gr children_n1 sex head_marst1 owner/ param = reference ref = last order = formatted;
	model age1 = empl_stat1 educ1Gr children_n1 sex age1Gr fam_size head_marst1 fam_inc1 owner;
run;




data resp_prob;
	set resp_desmat;
	
	*linpr1 = 1.3*Intercept - 1*educ1Gr1 - 0.4*educ1Gr2 + 0.8*sexFemale - 0.6*age1Gr1 - 0.15*fam_size + 0.85*head_marst11 + 0.3*head_marst12;
	*resp_prob1 = exp(linpr)/(1 + exp(linpr));

	linpr = 1.3*Intercept + 0.8*sexFemale - 0.6*age1Gr1 + 0.7*owner1;
	resp_prob = exp(linpr)/(1 + exp(linpr));
run;


data psid.simpop;
	merge psid.simpop resp_prob;
run;

proc sgplot data = psid.simpop;
	histogram resp_prob;
run;


/* Nun simulieren wir die Ziehung von 1000 Stichproben... */

proc surveyselect noprint
	data = psid.simpop
	method = SRS
	samprate = 20
	stats
	out = psid.sim_smpl;
run;


%interaction(var_lst = sex age1Gr owner, newvar=RHG, dat=psid.sim_smpl, fmtname = sageF);

/* Nun simulieren wir das response Verhalten */

proc sort data = psid.sim_smpl; by RHG; run;

data 	psid.sim_smpl;
	set psid.sim_smpl;

	resp = ranbin(0, 1, resp_prob); 
run;


proc means data = psid.sim_smpl noprint;
	var resp;
	by RHG;
	output out = psid.sim_smpl_info(drop = _TYPE_ rename = (_FREQ_ = sampled_n)) sum=resp_n;
run;

proc means data = psid.sim_smpl_info noprint;
	var sampled_n;
	output 
		out = psid.sim_smpl_strat_info(drop = _TYPE_ _FREQ_) 
		sum=sampled_strat_n
		;
run;


data psid.sim_smpl;
	merge psid.sim_smpl
			psid.sim_smpl_info;
	by RHG;
run;

data psid.sim_smpl;
	set psid.sim_smpl;
	if _n_ = 1 then set psid.sim_smpl_strat_info;
	stratid = 1;
run;

data psid.sim_smpl;
	set psid.sim_smpl(where = (resp = 1));
run;



	
%macro function(i, j);
	%tot(not_ins_tot, health_ins, 1);
	%tot(fam_inc_tot, fam_inc1, 1);
	%tot(debt_tot, debt_val1, 1);

	%tot(p_size, 1, 1);
	%div(not_ins_p, not_ins_tot, p_size);
	%div(fam_inc_mean, fam_inc_tot, p_size);
	%div(debt_mean, debt_tot, p_size);

	%estim(not_ins_p);
	%estim(fam_inc_mean);
	%estim(debt_mean);
%mend;


%clan(data = psid.sim_smpl, RHG = YES, npop = 5761, groupid = RHG,
		ngroup = sampled_n, nresp = resp_n, nsamp = sampled_strat_n, stratid = stratid,
		maxrow = 1, maxcol = 1);

data Dut_RHG;
	set Dut;
__model__ = 1;
run;


%clan(data = psid.sim_smpl, npop = 5761, nresp = 911, maxrow = 1, maxcol = 1);

data Dut_ohne_RHG;
	set Dut;
__model__ = 2;
run;

data Dut_all;
	set Dut_RHG Dut_ohne_RHG;
run;

proc print data = Dut_all; run;
