

libname pus "&dataDir\PISA\US";

options nofmterr fmtsearch = (work brfss.formats6) mstored sasmstore = sasuser;


** Was gitb es im Datensatz?;

proc contents data = pus.Sch6 varnum; run;

proc freq data = pus.Sch6;
	tables 	SCHSIZE SCHLTYPE STRATUM SC09Q11 SC09Q12
			SC07Q01 SC05N01 SC02Q01 SC01Q02 SC01Q01 
			PROPCERT PCGIRLS TCSHORT /missing;
run;

proc freq data = pus.Sch6;
	format _all_;
	tables STRATUM ;
run;

proc contents data = pus.stud6 varnum; run;

** Merge School and Student data;

proc sort data = pus.sch6; by schoolid; run;
proc sort data = pus.stud6; by schoolid; run;


data pus.pisa6;
	merge
		pus.Sch6(keep = schoolid PCGIRLS SC07Q01 SC01Q01 SC01Q02 SC02Q01 SC09Q11 SCHSIZE STRATIO TCSHORT W_FSCHWT)
		pus.stud6(keep = schoolid ST04Q01 PV: WVARSTRR W_FSTUWT W_FSTR: RANDUNIT)
		;
	by schoolid;
run;

proc univariate data = pus.stud6; 
	var PV: ;
run;


proc summary data = pus.pisa6;
