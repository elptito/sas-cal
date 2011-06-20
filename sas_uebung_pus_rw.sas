
libname pus "&dataDir\PISA\US";

options nofmterr fmtsearch = (work brfss.formats6) mstored sasmstore = sasuser;
	
	
proc univariate data = pus.pisa6;
	var W_FSTUWT;
run;
	
%macro function();
	
	%tot(test, PV1MATH, 1);
	%tot(p_size, 1, 1);
	
	%div(mtest, test, p_size);
	
	%estim(mtest);

%mend function;

%clan();

proc surveyreg 
	data = pus.pisa6;
	model pv1math = pv1read;
	weight W_FSTUWT;
run;
