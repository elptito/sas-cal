
/* Washington and Florida Crime Data 2006 */

*libname crime "PFAD EINSETZEN!";

options fmtsearch = (work crime) mstored sasmstore = sasuser;

*** Verzeichnis der enthaltenen Variablen;
proc contents data = crime.pds6_cens_le varnum; run;


** Total Crime Index and pct poverty ;


data crime.pds6_cens_le;
	set  crime.pds6_cens_le;
	
	if state_id = 1 then
		do;
			if metro = 1 then metro_state = 1;
			else metro_state = 2;
		end;
	else
		do;
			if metro = 2 then metro_state = 3;
			else metro_state = 4;
		end;
run;


ods graphics on;

proc glm data = crime.pds6_cens_le
	;
	model ci_tot = pov_est_all pop;
run;
quit;

ods graphics off;

** Design I; 
proc surveyselect
	data = crime.pds6_cens_le
	method = SRS
	samprate = 0.168
	stats
	seed = 45123
	out = pd_smpl;
run;

** Design II;

proc sort data = crime.pds6_cens_le; by state; run;

proc surveyselect
	data = crime.pds6_cens_le
	method = SRS
	samprate = 0.168
	stats
	seed = 45123
	out = pd_strat;
	strata state_id;
run;

/* Groessen der Strata */

proc freq data = crime.pds6_cens_le;
	tables state;
run;


proc freq data = pd_strat;
	tables state;
run;

data pd_strat;
	set pd_strat;
	
	if state = 'Washington' then
		do;
			strat_size = 228;
			strat_resp = 39;
		end;
	else
		do;
			strat_size = 364;
			strat_resp = 62;
		end;
run;


%macro function(i, j);

	%tot(ci_total, ci_tot, 1);
	%estim(ci_total);
%mend function;

%clan(data = pd_strat, stratid = state_id, npop = strat_size, nresp = strat_resp, maxrow = 1, maxcol = 1);

proc print data = Dut; run;




%gregeri(formula = ~ c(pop) + year*c(vc_tot), sframe = crime.wc34, aux_out_file = test, debug = 1);

proc surveyselect noprint
	data = crime.wc34
	method = SRS
	rate = 20
	stats
	out = cr_smpl;
run;
