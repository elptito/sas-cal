/* Testing HT Total estimators with CLAN */

libname peas "../../share/data/PEAS";

proc contents data = peas.frs02 varnum; run;
proc contents data = peas.wers98 varnum; run;

proc freq data = peas.wers98;
	tables disabgrp nempsize;
run;

proc sql;
	select sum(grosswt) from peas.wers98;
quit;

%macro function(arg1, arg2);
	%TOT(tab, eo, (disabgrp = &arg1) and (nempsize = &arg2));
	%TOT(nab, 1,  (disabgrp = &arg1) and (nempsize = &arg2));
	%DIV(rab, tab, nab);

	%estim(tab);
	%estim(nab);
	%estim(rab);
%mend;

%clan(data = peas.wers98, sampunit = e, npop = 264476, nresp = 2191,
		maxrow = 3, maxcol = 6);



proc print data = Dut; run;
