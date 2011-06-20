/* IPF with SAS and CLAN */

/* Als erstes Schaetzen wir die gemeinsame Verteilung... */

/* Schritt 0: Datenaufbereitung */

options fmtsearch = (work fdz);

proc contents data = fdz.cvts3 varnum; run;

data cvts3;
	set fdz.cvts3(rename = (c10a1 = tz a205kat = gkl)
					  keep = id c10a1 a205kat
					 );
	
	if gkl > 4 then gklGr4 = 4;
	else gklGr4 = gkl;
	
	format gklGr4 a2044G.;
	label gklGr4 = 'Betriebsgroessenklasse';
run;

proc freq data = fdz.cvts3 noprint;
	tables c10a1 /out = tab1 (drop = percent);
	tables a205kat /out = tab2(drop = percent);
run;


/* Schritt 1: Die gemeinsame Verteilung... */

ods tagsets.TablesOnlyLaTeX
	file = "&sTablesDir\tmp-cvts3_gklGr4-tz_pop_SAS.tex" (notop nobot)
	newfile = table;

proc tabulate data = cvts3;
	class tz gklGr4;
	table tz all, gklGr4 all;
run;

ods tagsets.TablesOnlyLatex close;


/* Schritte: einfache Stichprobe... */
/*
proc surveyselect noprint
	data = cvts3
	method = SRS
	sampsize = 200
	stats
	out = cvts3_smpl
	;
run;
*/

** Compare the results from survey, CLAN and proc surveyfreq.. Import the sample drawn with ;

data cvts3_smpl;
	infile "&iSysDir/R_cvts3_200_SRS.csv" dsd delimiter = ';' firstobs = 2;
	input id tz gklGr4;
	samplingWeight = 2305/200;
run;

/* Schaetzen der gemeinsamen Verteilung... */

proc surveyfreq data = cvts3_smpl N = 2305;
	tables tz*gklGr4;
	weight SamplingWeight;
	ods output CrossTabs = est_counts;
run;

ods tagsets.TablesOnlyLaTeX
	file = "&sTablesDir\tmp-cvts3_gklGr4-tz_est_SAS.tex" (notop nobot)
	newfile = table;

proc tabulate data = est_counts;
	freq WgtFreq;
	class F_tz F_gklGr4;
	table F_tz, F_gklGr4;
run;

ods tagsets.TablesOnlyLaTeX close;


/*************** Los mismo con %CLAN ****************/

/******* NOT RUN! ********/

%macro function(arg1, arg2); /* Es muessen _Positionsparameter_ sein! */
	*%local nab; /* Nicht unbedingt notwendig, aber ich habe es ungern, wenn Makrovariablen frei im Raum liegen...*/
	
	%tot(nab, /* Ein Name fuer die geschaetzten Totals)*/
		  1,   /* Die 1 bedeutet, dass Haeufigkeiten geschaetzt werden */
		  (tz = &arg1) and (gklGr4 = &arg2) /* Bedingung, die die Domain (Zellen in der Kontingenztabellen 
		  											definiert */
		  );

	%estim(nab); /* Ausgabe der Schaetzung im Output Datensatz */
%mend function;

%clan(data = cvts3_smpl,/* Das ist klar */
		sampunit = e,		/* Es wurden SSU gezogen: kein cluster sampling */
		npop = 2305,		/* Anzahl der Elemente in der Population */
		nresp = 200,		/* Anzahl der Respondenten: hier 200 (= Stichprobenumfang), da kein Nonresponse */
		maxrow = 8,			/* Anzahl der Kategorien von "tz"  */
		maxcol = 4			/* Anzahl der Kategorien von gklGr4 */
		);

/********* END NOT RUN! **********/

** CAN hat Probleme mit der Kodierungen, die nicht durchgehend sind
	...tz umkodieren... ;

/*	When sample is imported from R: tz is already recoded..
data cvts3_smpl;
	set cvts3_smpl;

	if tz = 0 then tz = 1;
	else
		if tz = 1 then tz = 2;
		else
			if tz = 8 then tz = 3;
	format tz;
run;
*/

%macro function(r, c);
	%tot(nab, 1, (tz = &r) and (gklGr4 = &c));
	
	%estim(nab);
%mend function;


%clan(data = cvts3_smpl, sampunit = e, npop = 2305, 
		nresp = 200, maxrow = 3, maxcol = 4);

/* Output in work.Dut */

/********* Kalibration der Gewichte an die zwei Randverteilungen **********/

** Schritt 1: Datensatz mit den Hilfsinformationen;

data pop_mrgns;
	input var $ N MAR1-MAR4;
	
	datalines;
		tz				3	262	1224	819	.
		gklGr4		4	466	503		452	884
	;
run;

** Schritt 2: Makro %function(r, c), danach %CLAN aufrufen;

%macro function(r, c);
	%auxvar(datax = pop_mrgns, wkout = cal_weights, datawkut = cvts3_smpl,
			  ident = id);
	%greg(nab_cal, 1, (tz = &r) and (gklGr4 = &c));
	
	%estim(nab_cal);
%mend function;

%clan(data = cvts3_smpl, sampunit = e, npop = 2305, 
		nresp = 200, maxrow = 3, maxcol = 4);


%macro function(r, c);
	%tot(nab_cal1, 1, (tz = &r) and (gklGr4 = &c));
	
	%estim(nab_cal1);
%mend function;

%clan(data = cvts3_smpl, sampunit = e, npop = 2305, 
		nresp = 200, maxrow = 3, maxcol = 4);




** Schritt 3: Kalibrationsschaetzer, aber falsche Standardfehler;

proc surveyfreq 
	data = cvts3_smpl
	N = 2305;
	weight cal_weights;
	
	table tz*gklGr4;
	ods output CrossTabs = est_counts_cal;
run;

** Oder mit CLAN;

%clan(data = cvts3_smpl, sampunit = e, npop = 2305,
	  	nresp = 200, maxrow = 1, maxcol = 2);










* 	Por el amor de dios...: Wenn die _Kodierung_!!
	der Variablen nicht durchgehend von 1 bis maxrow/maxcol lauft... 
	PROBLEM!!! CLAN läuft, berücksichtigt aber mit 0 kodierten Levels nicht.. 
	schlecht bei 0/1 Variablen
	und das Output kann bei leeren Zellen in der Stichprobe schwer zu lesen sein...
	;
