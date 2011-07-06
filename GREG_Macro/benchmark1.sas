
/*************
  benchmark1.sas
  
  Author
  Descr: Vergleich vom Cal-Makro mit CLAN (und CALMAR)
  
**************/


/******************************BEISPIEL I- Verglecih*********************************************/
%interaction(var_lst = gender cohort, newvar = gender_cohort1, dat = sample, newdat=sample, fmtname = gc, fmtlib = work, type = clan)
data clan_aux_input;
length Var $ 32.;
infile datalines missover;
input VAR $ n MAR1 MAR2 MAR3 MAR4 MAR5 MAR6 MAR7 MAR8 MAR9 MAR10 MAR11 MAR12;
datalines;
gender_cohort1 12 331 1320 1892 2318 1208 77 156 1033 1689 1822 1177 96 
marital_status 4 8591 3123 214 1191
;
run;


%macro function(i, j);
	%auxvar(datax = clan_aux_input,wkout=wvikt, datawkut=sample, ident=PID);
	%greg(earnings_tot_reg, earnings, 1);

	%estim(earnings_tot_reg);
%mend function;

%clan(data = sample, npop = 13119, nresp = 1000, maxrow = 1, maxcol = 1);


proc compare base = sample(rename=(wvikt=col1)) compare = weight;
  var col1;
  run;

/*****************************************************************************************************/


/******************************BEISPIEL Ia- Verglecih*********************************************/


%interaction(var_lst = gender cohort, newvar = gender_cohort1, dat = sample, newdat=sample, fmtname = gc, fmtlib = work, type = clan)
data clan_aux_input;
length Var $ 32.;
infile datalines missover;
input VAR $ n MAR1 MAR2 MAR3 MAR4 MAR5 MAR6 MAR7 MAR8 MAR9 MAR10 MAR11 MAR12;
datalines;
born 0  25702253
;
run;

proc freq data = sample;
  format _all_;
  tables gender_cohort1 /missing;
run;


%macro function(i, j);
	%auxvar(datax = clan_aux_input,wkout=wvikt, datawkut=sample, ident=PID);
	%greg(earnings_tot_reg, earnings, 1);

	%estim(earnings_tot_reg);
%mend function;

%clan(data = sample, npop = 13119, nresp = 1000, maxrow = 1, maxcol = 1);


proc compare base = sample(rename=(wvikt=col1)) compare = weight;
  var col1;
  run;

 /******************************BEISPIEL Ib- Verglecih*********************************************/
%interaction(var_lst = gender cohort, newvar = gender_cohort1, dat = sample, newdat=sample, fmtname = gc, fmtlib = work, type = clan)

data clan_aux_input;
length Var $ 32.;
infile datalines missover;
input VAR $ n MAR1 MAR2 MAR3 MAR4 MAR5 MAR6 MAR7 MAR8 MAR9 MAR10 MAR11 MAR12;
datalines;
gender_cohort1 12 331 1320 1892 2318 1208 77 156 1033 1689 1822 1177 96 
marital_status 4 8591 3123 214 1191
born 0  25702253
;
run;

proc freq data = sample;
  format _all_;
  tables gender_cohort1 /missing;
run;


%macro function(i, j);
	%auxvar(datax = clan_aux_input,wkout=wvikt, datawkut=sample, ident=PID);
	%greg(earnings_tot_reg, earnings, 1);

	%estim(earnings_tot_reg);
%mend function;

%clan(data = sample, npop = 13119, nresp = 1000, maxrow = 1, maxcol = 1);


proc compare base = sample(rename=(wvikt=col1)) compare = weight;
  var col1;
  run;
