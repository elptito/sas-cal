
/*
	Einstellen der Optionen zur Einbindung der Daten der dazugehoerigen Formate.	
*/

libname dat "&dataDir/FDZ";
options nofmterr fmtsearch = (work dat) mstored sasmstore = sasuser;

/* Ziehen einer 2-stufigen Stichprobe */

** Datensatz auf Betriebsebene;

** Sortieren nach den Schichtungsmerkmalen;

proc sort data = dat.gls01(drop = b_ef30 b_ef31); by betr_id; run;

data gls01_betr;
	set dat.gls01;
	by betr_id;
	if first.betr_id then output;
run;

proc sort data = gls01_betr; by region wzgruppe betr_gr_klasse; run;

%interaction(var_lst = region wzgruppe betr_gr_klasse, newvar=schicht_id, dat=dat.gls01);

proc surveyselect noprint
	data = gls01_betr
	method = SRS
	samprate = 0.08
	stats
	seed = 54231
	out = gls01_betr_smpl(rename = (samplingWeight = gew_betr) keep = betr_id samplingWeight);
	strata region wzgruppe betr_gr_klasse;
run;

proc sort data = gls01_betr_smpl; by betr_id; run;
proc sort data = dat.gls01; by betr_id; run;

data gls01_smpl;
	merge 
		gls01_betr_smpl( in = in_smpl)
		dat.gls01;
	;
	by betr_id;
	if in_smpl;
run;

/*
proc surveyselect noprint
	data = gls01_betr_smpl
	method = SYS
	samprate = 10
	stats
	seed = 23414
	out = gls01_smpl(rename = (SamplingWeight = gew_bes) drop = SelectionProb)
	;
	strata betr_id;
run;

*/

proc export data = gls01_smpl
			outfile = "&dataDir\FDZ\gls01_smpl.csv"
			dbms = csv
			replace
			;
		delimiter = ';';
run;



proc export data = gls01_smpl
			outfile = "&dataDir\FDZ\gls01_smpl.csv"
			dbms = csv
			replace
			;
		delimiter = ';';
run;
