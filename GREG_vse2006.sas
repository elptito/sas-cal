
/**/
*proc contents data = fdz.vse6 varnum; run;



proc surveyselect noprint
	data = fdz.vse6(keep = betr_id bes_id ef10 ef17 ef18 ef16u2 ef11)
	method = SRS
	sampsize = 1000
	stats
	seed = 412321
	out = vse6_srs;
run;

data vse6_srs;
	set vse6_srs;
	id = 10000*BETR_ID + bes_id;
	_Intercept_ = 1;
run;

** Por el amor de dios... missing in variables simply listed in the class statement cause omission of the whole observation..;

proc surveyreg
	data = vse6_srs
	total = 60551
	;
	format _all_;
	class ef10;
	weight samplingWeight;
	model ef18 = ef10 ef11 ef11(ef10) /solution vadjust=none INVERSE ;
	*estimate "t_y" Intercept 60551 EF17 43104 4479 2428 1106 3961 5473 EF10 33750 26801
						ef11 118961366 ef11(ef10) 66308900 52652466;
	*estimate "t_y" Intercept 60551 EF17 43104 4479 2428 1106 3961 5473 EF10 33750 26801
						EF17*EF10 25541 17563 2305 2174 1413 1015 578 528 1576 2385 2337 3136
						ef11(ef10) 66308900 52652466;
		;
	ods output
		ParameterEstimates = RegEst_out InvXPX = XXinv ClassVarInfo = X_coding EstimateCoef=est_coeff;
run;


proc freq data = fdz.vse6 noprint;
	tables EF9 /out = _test_ef9(drop = PERCENT);
	tables EF9*EF10 /out = _test_full(drop = PERCENT);
run;

proc sort data = fdz.vse6; by ef9 EF10; run;

proc means data = fdz.vse6 noprint;
	var EF12U2 EF18;
	by EF9 EF10;
	output out = _test_sum(drop = _TYPE_ _FREQ_) sum=;
run;

proc sql;
	create table _sums_only as 
	select sum(ef12U2) as EF12U2, sum(ef18) as EF18
	from fdz.vse6; 
quit;

proc transpose data = _sums_only out = __red__sums_only(rename = (_NAME_ = term COL1 = COUNT)); run;

options mprint nosymbolgen;
%combineTables(tables_lst= _test_ef9 _test_full _test_sum _sums_only, cont_vars = EF12U2 EF18, debug=1,type=REG)

%stack(dat = _test_sum, var_lst = EF12U2, newdat = _test_sum_stack);

%let test = deeba putka ti lelina;
%put %match(&test, puta deemba , 1);

data test;
	length term $ 32.;
	set _test_full;
	term='';
	
	array __all_num{*} _numeric_;
	
	do i = 1 to dim(__all_num);
	vname = vname(__all_num(i));
		
		if vname ne 'COUNT' then
			do;
				call symput();
				__all_num(i) = cats(vname(__all_num(i)), __all_num(i));
					
				put "Variable is not a frequency count";
				term = cats(term, vname);
				put term=;
			end;
	end;
run;

data TEST;
	length term $32.;
	length EF9_str EF10_str $32.;
	set _test_full;
	
	array __dscr{2} EF9 EF10;
 	array __dscr_s{2} $ EF9_str EF10_str;
	
	do i = 1 to 2;
 		__dscr_s(i) = cats(vname(__dscr(i)), __dscr(i));
 	end;
		term = cats(EF9_str,EF10_str);
	
 	drop EF9 EF10 EF9_str EF10_str;
 run;




%buildAuxDataTable(aux_out_file=test_combine, population= _test_ef9 _test_full _test_sum, cont_vars = EF12U2, 
					out_lib=work,  margins_lib=, debug=1,type=REG);



proc transpose data = sums_only out = sums_only_red; run;


proc sql;
	create table ttls as
	select
quit;

proc iml;
	%desmat(data = vse6_srs, model = ef10 ef11 ef10*ef11, para = dum dir dum*dir, intrcpt = Y);
	print design;
quit;


options mprint mprintnest nosymbolgen;

%gregeri(formula = ~ ef10 + ef17 + c(ef11) + ef10*c(ef11) + c(ef18), sframe = fdz.vse6, aux_out_file = test_IN, backend = REG, debug = 1);

%gregeri(formula = ef18 ~ 0 + ef10 + c(ef11) + ef10*c(ef11) + ef17, sframe = fdz.vse6, 
			sample = vse6_srs, weight_var = samplingWeight,
			aux_out_file = test_IN_CLAN, backend = CLAN, debug = 1);

%gregeri(formula = ef18 ~  ef10 + c(ef11) + ef10*c(ef11) + ef17*ef10, sframe = fdz.vse6, 
			sample = vse6_srs, weight_var = samplingWeight,
			aux_out_file = test_IN, backend = REG, debug = 1);


%gregeri(formula = ef18 ~  ef10 + c(ef11) + ef10*c(ef11) + ef10*EF16U2 , sframe = fdz.vse6, 
			sample = vse6_srs, weight_var = samplingWeight,
			aux_out_file = test_IN, backend = REG, debug = 1);

%gregeri(formula = ef18 ~  ef10 + c(ef11) + ef10*c(ef11) , sframe = fdz.vse6, 
			sample = vse6_srs, weight_var = samplingWeight,
			aux_out_file = test_IN, backend = CLAN, debug = 1);


%macro function(r, c);
	%auxvar(datax = test_IN, datawkut = vse6_srs, ident = id, wkout = cal_w);
	%greg(t_reg, ef18, 1);
	%estim(t_reg);
%mend function;

%clan(data = vse6_srs, npop = 60551, nresp = 1000, maxrow = 1, maxcol = 1);

data vse6_srs;
	set vse6_srs;
	g_k = cal_w/samplingWeight;
run;

data Dut1;
	set Dut;
run;

%let dat_names = %names(vse6_srs);

%let test = %match(&dat_names, cal_weight);
%put Test is:&test@@;


%let test = %names(__X__);
%put &test;

%let test1 = %drop(%upcase(&test), %upcase(samplingWeight));


options mprint nosymbolgen;
%put &test1;

data t1;
	input x y;
	datalines;
	1 2 
	2 3
	4 5
	5 1
	;
run;


data t2;
	retain _all_;
	set t1;
	
	array tmp{2} x y;
		do i = 1 to 2;
			tmp(i) + tmp(i);
		end;
run;

data t12;
	merge t1 t2(rename = (x = x_sum y = y_sum));
run;

proc print data = t12; run;

	
proc iml;
	use __X__;
	read all into X;
	
	X_n = nrow(X);
	X_c = ncol(X);
	print X_n;
	print X_c;

	X_test = X[, ];

	use vse6_srs; 
	read all var {samplingWeight} into W;
	
	W = diag(W);

	use Test_in;
	read all var {_TOTAL_} into poptotal;
	use Test_in_est;
	read all var {_TOTAL_} into pi_estimate;

	correction = poptotal - pi_estimate;
	
	tmp =  nrow(W);
	print tmp;

	tmp1 = nrow(correction);
	print tmp1;

	use __RegXXinv;
	read all into XWX_inv;

	tmp2 = nrow(XWX_inv);
	tmp3 = ncol(XWX_inv);
	print tmp2;
	print tmp3;

	g_k = 1 + t(correction)*XWX_inv*t(X)*W;

	
	print W;
quit;
















proc surveymeans
	data = vse6_srs sum
	;
	var ef11;
	weight samplingWeight;
run;


proc surveymeans
	data = vse6_srs sum
	;
	var ef11;
	weight samplingWeight;
	domain ef10;
run;


proc surveyfreq
	data = vse6_srs
	;
	tables ef10 ef17;
	weight samplingWeight;
run;
			
%gregeri(formula = ef18 ~ ef10 + ef17 + c(ef11) + ef10*c(ef11), sframe = fdz.vse6, 
			sample = vse6_srs, weight_var = samplingWeight,
			aux_out_file = test_IN, backend = REG);



%gregeri(formula = ~ c(ef11), sframe = fdz.vse6, aux_out_file = test_IN, backend = REG, debug = 1);


%let test0 =  ef11, ef23, ef123;
%let test =  %encloseEach(%quote(&test0), %str(%(), %str(%)), %quote(,));
%let test1 = %encloseEach(%quote(&test), sum,%str( as ), %quote(,));
%let test2 = %encloseEach(%quote(&test1),, %quote(&test0), %quote(,));
%put &test0: &test :::: &test1 :::: &test2;


%let test0 = ef11;
%let test =  %encloseEach(%quote(&test0), %str(%(), %str(%)), %quote(,));
%let test1 = %encloseEach(%quote(&test), sum,%str( as ), %quote(,));
%put TEST1: %quote(&test1)@@;
%let test2 = %encloseEach(%nrbquote(&test1),, %quote(&test0), %quote(,));
%put &test0:&test::::&test1::::&test2;


%put %wc(%quote(&test1), %quote(,));





proc transpose data = test_IN(drop = xtype xdom n)
					out  = test_tr;
	by notsorted Var ;
run;


proc sql;
	create table __tmp_var_lst as
	select varnum, name
	from dictionary.columns
	where memname = %upcase("tmp") and name like or name like ;
quit;


data _null_;
	set sashelp.vcolumn(where = (memname = %upcase("tmp")));
	put _all_;
run;


proc transpose data = test_in(drop = n xtype xdom) out = test_tr;
	var MAR1 ;
	by Var;
run;


proc print data = test_in(drop = n xtype xdom); run;
proc print data = test_tr; run;



proc print data = test_tr; run;

proc sql;
create table tmp as
select ef10, ef17, sum(ef11) as ef11, sum(EF18) as ef18
from vse6_srs
group by ef10, ef17
;
quit;

proc transpose data = tmp out = tmp_tr(rename = (COL1 = COUNT)); run;

data test_in;
	set test_in;
	id_var + 1;
run;

%macro function(r, c);
	%auxvar(datax = test_IN);
	%greg(t_reg, ef18, 1);
	%estim(t_reg);
%mend function;

%clan(data = vse6_srs, npop = 60551, nresp = 1000, maxrow = 1, maxcol = 1);

data Dut1;
	set Dut;
run;







proc iml;
%desmat(data = vse6_srs, model = ef10 ef11 ef10*EF11, para = dum dir dum*dir);

print design;
quit;



proc freq data = fdz.vse6 noprint;
	format _all_;
	table ef17 /out = tab1(drop = PERCENT);
	table ef10 /out = tab2(drop = PERCENT);
	table ef17*ef10 /out = tab3(drop = PERCENT);
run;

data vse6_srs;
	set vse6_srs;
	ef17ef10 = ef17*ef10;
run;

proc sql noprint;
	create table tab4 as
		select ef10, sum(ef11) as COUNT
		from fdz.vse6
		group by ef10
	;
quit;


*%buildAuxData(out = test_marg, pop_margins=tab1 tab2);

data test_marg;
	input Var $ n MAR1-MAR6 XTYPE $ XDOM $;
	
	datalines;
	EF17 6 43104 		4479 	2428 	1106 3961 5473 c . 
	EF10 2 33750 		26801 	.  .    .    .   	c .
	EF11 2 66308900 	52652466 . 	.	  . 	 .    n EF10
	;
run;

%macro function(r, c);
	%auxvar(datax = test_marg);
	%greg(t_reg, ef18, 1);
	%estim(t_reg);
%mend function;

%clan(data = vse6_srs, npop = 60551, nresp = 1000, maxrow = 1, maxcol = 1);

proc print data = Dut; run;


options mprint mprintnest;

%gregeri(formula = ~ ef10 + wzgruppe + c(alter), sframe = vse6, aux_out_file = work.__CLAN_IN);
