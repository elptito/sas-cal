
/*
	Einstellen der Optionen zur Einbindung der Daten der dazugehoerigen Formate.	
*/

libname dat "&dataDir/FDZ";
options nofmterr fmtsearch = (work dat) mstored sasmstore = sasuser;

/* Ziehen einer 2-stufigen Stichprobe */

** Datensatz auf Betriebsebene;

** Sortieren nach den Schichtungsmerkmalen;

%interaction(var_lst = region wzgruppe betr_gr_klasse, newvar=schicht_nr, dat=dat.gls01);

proc sql;
	create table schicht_gr as
	select schicht_nr, count(betr_id) as schicht_gr
	from (
		select betr_id, min(schicht_nr) as schicht_nr
		from dat.gls01
		group by betr_id
		)
	group by schicht_nr
	;
	create table gls01_betr as
	select distinct betr_id, schicht_nr, region, wzgruppe, betr_gr_klasse
	from dat.gls01
	order by region, wzgruppe, betr_gr_klasse;
quit;

proc surveyselect noprint
	data = gls01_betr
	method = SRS
	samprate = 0.1
	stats
	seed = 54231
	out = gls01_betr_smpl(rename = (samplingWeight = gew_betr) keep = betr_id schicht_nr samplingWeight);
	strata region wzgruppe betr_gr_klasse;
run;

proc sort data = gls01_betr_smpl; by betr_id; run;
proc sort data = dat.gls01; by betr_id; run;

data gls01_smpl;
	merge 
		gls01_betr_smpl( in = in_smpl)
		dat.gls01(drop = b_ef30 b_ef31);
	;
	by betr_id;
	if in_smpl;
run;

proc sql;
	create table dat.gls01_smpl as 
	select smpl.*, sinf.schicht_gr, count(distinct smpl.betr_id) as schicht_n
	from
		gls01_smpl as smpl join schicht_gr as sinf
		on smpl.schicht_nr = sinf.schicht_nr
	group by smpl.schicht_nr
	;
quit;


proc datasets library = fdz;
	modify gls01_smpl;
	label
		schicht_nr = 'Schicht Nummer'
		schicht_gr = 'Schichtgroesse'
		schicht_n  = 'Stichprobengroesse in Schicht'
		;
run;
quit;

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

proc export data = dat.gls01_smpl
			outfile = "&dataDir\FDZ\gls01_smpl.csv"
			dbms = csv
			replace
			;
		delimiter = '09'x;
run;
