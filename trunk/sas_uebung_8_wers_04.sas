

options fmtsearch = (work uk);

proc contents data = uk.wers4_m varnum; run;

proc freq data = uk.wers4_m;
	tables a8d a8b;
run;

data test;
	set uk.wers4_m(obs = 3000 where = (cmiss(a8d, a8b) = 0) keep = a8d a8b a3);
run;

options mprint;
%interaction(var_lst= a8d a8b, newvar=, dat=test, newdat = test);

%let debug_greg = 1;
