
*libname csfii "PFAD EINSETZEN";

options nofmterr fmtsearch = (work csfii.formats) mstored sasmstore = sasuser;


proc contents data = csfii.nutri_amnt96; run;


proc freq data = csfii.nutri_amnt96;
	format _all_;
	tables race sex region increp origin;
run;


proc means data = csfii.nutri_amnt96 sum;
	var wta_day1;
run;


proc sql;
	select count(distinct varunit) from csfii.nutri_amnt96
	group by varstrat;
quit;



proc surveymeans 
	data = csfii.nutri_amnt96
	mean
	N = 1404
	;
	var alcohol_sum;
	weight wta_day1;
	strata varstrat;
	cluster varunit;
	domain region ageGr6 sex;
run;


proc surveymeans 
	data = csfii.nutri_amnt96
	varmethod = jackknife
	mean
	;
	var alcohol_sum;
	weight wta_day1;
	repweights RA_D1_:;
	domain region ageGr6 sex;
run;


/**** 
	Simulation: Varianzschaetzung mit Replikationsgewichten...;

	Datenaufbereitung:
	Im Unterschied zum Originalmaterial (CSFII 1996, erster Tag) sind die 
	PSU (gekennzeichet durch die Variable varunit)
	in kleinere PSU (Variable pseudo_psu) aufgesplittet. In jedem der neuen PSU gibt es zumindest 2 Haushalte.

	Die Anzahl der Schichten wurde durch Zusammenlegung der urspuenglichen Schichten auf 14 reduziert.
	Die neu gebildeten Schichtindikatoren sind in der Variable pseudo_strat gegeben.

	Wir ziehen eine geschichtete Stichprobe aus PSU mit jeweils 2 PSU pro Schicht mit Wahrscheinlichkeit
	proportional zur Groesse der PSU (Anzahl der Haushalte in der PSU).

	
****/

** Schritt 1

Vorbereitung zum Ziehen mit Wahrscheinlichkeit proportional zur Groesse ohne Zuruecklegen.

Wir muessen die Groessen der PSUs ausrechnen
;

proc sort data = csfii.pseudo_data; by pseudo_strat pseudo_psu; run;

proc means noprint
	data = csfii.pseudo_data;
	var hhid;
	by pseudo_strat pseudo_psu;
	output
		out = csfii.psu_size(drop = _TYPE_ _FREQ_) N = psu_size;
run;

data csfii.pseudo_data;
	merge 
		csfii.pseudo_data
		csfii.psu_size;
	by pseudo_strat pseudo_psu;
run;


** Schritt 2.1: Ziehen der Stichproben

;

proc sort data = csfii.pseudo_data; by pseudo_strat; run;

proc surveyselect noprint
	data = csfii.psu_size /* Wir ziehen aus dem Datensatz auf PSU-Ebene, d.h. eine Zeile fuer jede PSU */
	method = PPS /* Ziehen der Elemente proportional zur Groesse */
	sampsize = 2 /* Ziehen von 2 Elementen pro Schicht */
	stats /* Ausgabe der Variablen selectionProb und SamplingWeight in die Outputdatei */
	out = csfii.smpl /* Name der Outputdatei */
	rep = 100 /* Anzahl der Replikationen */
	;
	strata pseudo_strat; /* Das Design ist geschichtet nach pseudo_strat */
	size psu_size; /* Groesse der Elente: Erforderlich wenn method = PPS angegeben wird. */
run;


** Schritt 2.2
	Spaeter werden wir die Anzahl der gezogenen PSU innerhalb jeder Schicht brauchen.
	Nun berechnen wir diese mit proc means und fuegen es dem Datensatz
	csfii.smpl hinzu	
;

proc means noprint
	data = csfii.smpl;
	by replicate pseudo_strat;
	output
		out = csfii.strat_size_sampled(drop = _TYPE_ _FREQ_) N = strat_sampled;
run;

data csfii.smpl;
	merge 
		csfii.smpl
		csfii.strat_size_sampled;
	by replicate pseudo_strat;
run;


** Schritt 2.3 
	Zusammenfuehren der gewaehlten PSUs und den Informationen ueber die
	Personen, die zu diesen PSUs gehoeren.
	
	Dieses Zusammenfuehren machen wir hier mittels proc sql,
	da dort das many-to-many Zusammenfuehrung einfacher
	zu bewerkstelligen ist.	
;


proc sql;
	create table csfii.smpl /* Wir ueberschreiben den csfii.smpl Datensatz */
	as /* Im folgenden geben wir an, dass in die Tabelle csfii.smpl 
		  das Ergebnis der folgenden Abfrage gespeichert werden soll*/
	select /* Mit dem select statement fangen wir die Abfrage an */
		smpl.replicate,  /* Wir waehlen die Variable replicate aus dem Datensatz mit alias smpl, siehe unten */
		smpl.SamplingWeight, /* ... analog... */
		pop.* /* Wir waehlen alle Variablen aus dem Datensatz mit alias pop, siehe unten */

		/* Im folgenden bestimmen wir mit dem 'from' statement auf welche Tabelle sich unsere Abfrage beziehen..
			In diesem Fall wird das diejenige Tabelle sein,
			die sich aus der zusammenfuehrung von csfii.pseudo_data (unsere Populationsdatei) und
			csfii.smpl (wo sich unsere Stichproben befinden 
		*/
	from 	
			csfii.smpl as smpl /* Mit dem as smpl vergeben wir dem Datensatz csfii.smpl einen Namen (Alias),
								  mit dem wir diesen Datensatz innerhalb dieses 'select' Statements
								  ansprechen koenne
								*/
			join 
			csfii.pseudo_data as pop /* ... analog ...*/
			on 
			/*  Bedingung fuer die Zusammenfuehrung. Es sollen nur diejenigen Zeilen
				in der zusammengefuehrten Tabelle bleiben,
				fuer die diese Bedingung zutrifft. In unserem Fall wollen wir damit erreichen,
				dass im zusammengefuehrten Datensatz nur die PSU aus der Stichprobe
				beibehalten werden.
			*/
			smpl.pseudo_strat = pop.pseudo_strat 
			and smpl.pseudo_psu = pop.pseudo_psu
			/* Am Ende sortieren wir den Datensatz nach disen Variablen 
			   fuer bessere Uebersichtlichkeit */
	order by replicate, pseudo_strat, pseudo_psu, hhid, spnum;
quit;


** Schitt 2: Erzeugen von Replikationsgewichten;

/** Wir erstellen einen Datensatz namens csfii.strat_size,
	den wir nachher fuer die Festsetzung der
	Endlichkeitskorrektur bei der Varianzschaetzung benutzen werden. **/

proc means noprint 
	data = csfii.psu_size; 
	var pseudo_psu;
	by pseudo_strat;
	output
		out = csfii.strat_size(drop = _TYPE_) /* Wir schmeissen die automatisch erzeugte Variable _TYPE_ 
												 aus dem Outputdatensatz csfii.strat_size raus.
											  */
			  N = _TOTAL_ /* N = _TOTAL_ verlagt die Ausgabe der Anzahl von (validen) Beobachtungen in jeder Gruppe
			  				 definiert durch die Variablen, angegeben in dem 'by' Statement. Die Variable, 
			  				 die diese Anzahl beinhaltet soll _TOTAL_ heissen. Den Namen waehlen wir,
			  				 weil das von proc surveymeans benoetigt wird. 
			  			  */
		;
run;

/***  
	Da wir eine Simulation durchfuehren wollen, brauchen wir diese Angaben 100 Mal (Anzahl der Replikationen).
	Im folgenden data step wiederholen wir jede Beobachtung aus dem Datensatz csfii.strat_size 100 Mal und erzeugen
	gleichzeitig eine neune Variable namens replicate mit Werten von 1 bis 100. Wohlbemerkt, diese Wahl ist nicht
	zufaellig, der Variablennamen und die Anzahl der Wiederholungen muessen mit der Anzahl der Stichproben
	uebereinstimmen.
***/

data csfii.strat_size;
	set csfii.strat_size;
	do replicate = 1 to 100;
		output; 
	end;
run;


proc sort data = csfii.strat_size; by replicate pseudo_strat; run;
proc sort data = csfii.smpl; by replicate pseudo_strat; run;

data csfii.pseudo_smpl;
	merge 
		csfii.smpl
		csfii.strat_size;
	by replicate pseudo_strat
	;
run;


** Erstellen der Jackknife Replikationsgewichten;


ods listing close;

proc surveymeans
	data = csfii.smpl
	varmethod = jackknife(OUTWEIGHTS = csfii.jackw)
	;
	by replicate; /* Wir benutzen das 'by' statement, weil wir die Prozedur fuer jede Stichprobe durchfuehren
					moechten */
	
	var alcohol_sum; /* Diese Angabe ist hier nicht relevant */
	
	/* 	Die folgenden Statements beschreiben das Design der Stichprobe. Die Bedeutung sollte
		selbstverstaendlich sein.
	*/
	strata pseudo_strat;
	cluster pseudo_psu;
	weight SamplingWeight;
	ods output Statistics = csfii.est_alc_jk_out;
run;


proc surveymeans
	data = csfii.jackw
	varmethod = jackknife;
	by replicate; /* Wir benutzen das 'by' statement, weil wir die Prozedur fuer jede Stichprobe durchfuehren
					moechten */
	
	var alcohol_sum; /* Diese Angabe ist hier nicht relevant */
	
	/* 	Die folgenden Statements beschreiben das Design der Stichprobe. Die Bedeutung sollte
		selbstverstaendlich sein.
	*/
	strata pseudo_strat;
	cluster pseudo_psu;
	weight SamplingWeight;
	ods output Statistics = csfii.est_alc_jk_rw_nout;
run;

proc surveymeans
	data = csfii.jackw
	varmethod = jackknife;
	by replicate; /* Wir benutzen das 'by' statement, weil wir die Prozedur fuer jede Stichprobe durchfuehren
					moechten */
	
	var alcohol_sum; /* Diese Angabe ist hier nicht relevant */
	
	/* 	Die folgenden Statements beschreiben das Design der Stichprobe. Die Bedeutung sollte
		selbstverstaendlich sein.
	*/
	repweights RepWt_:;
	ods output Statistics = csfii.est_alc_jk_rw;
run;


ods listing;


** Erstellen der BRR Replikationsgewichten;

ods listing close;

proc surveymeans
	data = csfii.smpl
	varmethod = BRR(reps = 44 OUTWEIGHTS = csfii.brr)
	;
	by replicate; /* Wir benutzen das 'by' statement, weil wir die Prozedur fuer jede Stichprobe durchfuehren
					moechten */

	var alcohol_sum; /* Diese Angabe ist hier nicht relevant */

	/* 	Die folgenden Statements beschreiben das Design der Stichprobe. Die Bedeutung sollte
			selbstverstaendlich sein.
	*/
	strata pseudo_strat;
	cluster pseudo_psu;
	weight SamplingWeight;
	ods output Statistics = csfii.est_alc_brr;
run;

ods listing;

ods listing close;

proc surveymeans
	data = csfii.smpl
	varmethod = BRR(reps = 44 OUTWEIGHTS = csfii.brr)
	;
	by replicate; /* Wir benutzen das 'by' statement, weil wir die Prozedur fuer jede Stichprobe durchfuehren
					moechten */

	var alcohol_sum; /* Diese Angabe ist hier nicht relevant */

	/* 	Die folgenden Statements beschreiben das Design der Stichprobe. Die Bedeutung sollte
			selbstverstaendlich sein.
	*/
	strata pseudo_strat;
	cluster pseudo_psu;
	weight SamplingWeight;
	ods output Statistics = csfii.est_alc_brr;
run;

ods listing;






data csfii.test;
	set csfii.brr(where = (replicate = 1) 
					keep = replicate SamplingWeight HHID SPNUM pseudo_strat pseudo_psu RepWt_:);
run;


%stack(dat=csfii.brr, var_lst = RepWt_1 RepWt_2 RepWt_3 RepWt_4 RepWt_5 RepWt_6 RepWt_7 RepWt_8 RepWt_9 RepWt_10 RepWt_11 RepWt_12 RepWt_13 RepWt_14
										  RepWt_15 RepWt_16 RepWt_17 RepWt_18 RepWt_19 RepWt_20 RepWt_21 RepWt_22 RepWt_23 RepWt_24 RepWt_25 RepWt_26 RepWt_27
										  RepWt_28 RepWt_29 RepWt_30 RepWt_31 RepWt_32 RepWt_33 RepWt_34 RepWt_35 RepWt_36 RepWt_37 RepWt_38 RepWt_39 RepWt_40
										  RepWt_41 RepWt_42 RepWt_43 RepWt_44, 
			newdat=csfii.brr_stack); 

proc sort data = csfii.brr_stack; by replicate _source_col_ pseudo_strat; run;

ods listing close;

proc surveymeans 
	data = csfii.brr_stack
	;
	by replicate _source_col_;
	var alcohol_sum;
	weight _stack_;
	strata pseudo_strat;
	cluster pseudo_psu;
	ods output Statistics = csfii.est_means_alc;
	;
run;

ods listing;







%gregeri(formula = ~ RACE + ageGr6 + sex, sframe = csfii.pseudo_data,
		 aux_out_file = csfii.__CLAN, backend = CLAN);


%macro function(i, j);
	%auxvar(datax = csfii.__CLAN, wkout = CLAN_cal, datawkut = csfii.test_smpl, ident = upid);
%mend function; 

%clan(data = csfii.test_smpl, clusterid = pseudo_psu,
		stratid = pseudo_strat,
		npop = strat_size,
		nresp = strat_smpl,
		maxrow = 1, maxcol = 1);


%gregeri(formula = ~ RACE + ageGr6 + sex, sframe = csfii.pseudo_data, sample = csfii.test_smpl,
		 weight_var = SamplingWeight, cal_weight_name = calwgt_0, backend = REG);





/**
data csfii.pseudo_data;
	set csfii.pseudo_data;	
run;



proc surveyselect noprint 
	data = csfii.pseudo_data
	method = SRS
	sampsize = 500
	stats
	seed = 131232
	out = csfii.test_smpl;
	;
run;

**/
