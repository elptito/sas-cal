
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

proc sort data = gls01_betr; by region wzgruppe b_ef13; run;

proc surveyselect 
	data = gls01_betr
	method = SRS
	samprate = 0.08
	stats
	out = gls01_betr_smpl(rename = (samplingWeight = gew_betr) keep = betr_id samplingWeight);
	strata region wzgruppe b_ef13;
run;

proc sort data = gls01_betr_smpl; by betr_id; run;
proc sort data = dat.gls01; by betr_id; run;

data gls01_betr_smpl;
	merge 
		gls01_betr_smpl( in = in_smpl)
		dat.gls01;
	;
	by betr_id;
	if in_smpl;
run;

proc surveyselect
	data = gls01_betr_smpl
	method = SYS
	samprate = 10
	stats
	out = gls01_smpl(rename = (SamplingWeight = gew_bes) drop = SelectionProb)
	;
	strata betr_id;
run;
