/****

Beispielprogramm zur Simulation von Nonresponse und Nonresponse 

Als Grundlage (fiktive Population) dient die Welle aus dem Jahr 2001 der
Panel Study of Income Dynamics (PSID). Diese Population ist allerdings 
_KEINE_ zufaellige Auswahl aus dem Originalmaterial.

****/


** Schritt 0: Einlesen der Daten, Einstellen der SAS Optionen; 

options nofmterr fmtsearch = (work psid.formats) mstored sasmstore = sasuser;


** Schritt 0.1: Welche Variablen sind im Datensatz vorhanden? Die Option varnum dient dazu, die Variablen in der Liste nicht alphabetisch,
	sondern ihrer Reihenfolge im Datensatz nach zu ordnen;

proc contents data = psid.simpop varnum; run;


** Schritt 0.2: Haufigkeitsauszaehlungen der Diskreten Variablen, die wir benutzen werden.;

proc freq data = psid.simpop;
	format _all_;
	tables age1Gr sex owner health_ins /missing;
run;

** Verteilungsmerkmale der stetigen Variablen;

proc univariate data = psid.simpop;
	format _all_;
	var fam_inc1 debt_val1;
run;


** Schritt 1: Erzeugung von Responsewahrscheinlichkeiten;

** Schritt 1.1 Erstellung der Designmatrix fuer das Modell;

proc logistic data = psid.simpop outdesign = resp_desmat(drop = age1) outdesignonly;
	class sex owner 
		/ param = reference ref = last order = formatted;
	
	model age1 = owner sex;
	* age1 dient hier als response. Wenn wir eine Designmatrix erzeugen ist die Responsevariable irrelevant. Wichtig ist, aber, dass sie nicht
	  unter den erklaerenden Variablen aufgelistet ist!;
run;

** Schritt 1.2: Erzeugung der Wahrscheinlichkeiten; 

data resp_prob;
	set resp_desmat;
	
	*linpr1 = 1.3*Intercept - 1*educ1Gr1 - 0.4*educ1Gr2 + 0.8*sexFemale - 0.6*age1Gr1 - 0.15*fam_size + 0.85*head_marst11 + 0.3*head_marst12;
	*resp_prob1 = exp(linpr)/(1 + exp(linpr));
	
	linpr = 1.3 + 1*owner1;
	resp_prob = exp(linpr)/(1 + exp(linpr));
run;


** Zusammenfuehren der erzeugten Wahrscheinlichkeiten und den Populationsdatensatz;
data psid.simpop;
	merge psid.simpop resp_prob;
run;

** Wie sind die Responsewahrscheinlichkeiten verteilt?;

proc sgplot data = psid.simpop;
	histogram resp_prob;
run;




** Schritt 2: Ziehen von 200 Stichproben aus der Population;

proc surveyselect noprint
	data = psid.simpop
	method = SRS
	samprate = 20
	rep = 200 /* Anzahl der unabhaengigen Stichproben, die gezogen werden */
	stats
	out = psid.sim_smpl;
run;


** Schritt 3: Jetzt erzeugen wir eine variable, die die RHG indiziert, die wir spaeter bei der Schaetzung benutzen werden;
%interaction(var_lst = sex age1Gr owner, newvar=RHG, dat=psid.sim_smpl, fmtname = sageF);


** Schritt 4: In jeder Stichprobe simulieren wir das Responseverhalten;

proc sort data = psid.sim_smpl; by replicate RHG; run;

data 	psid.sim_smpl;
	set psid.sim_smpl;

	resp = ranbin(0, 1, resp_prob);
	/*  resp ist entweder 1 (Response) oder 0 (Nonresponse). */
run;


** Schritt 5: Um CLAN97 zu benutzen benoetigen wir 
	die folgenden Angaben:
	1) Indikator der RHGs (das haben wir schon mit dem %interaction Makro gemacht...
	2) Fuer jeden Wert von diesem Indikator brauchen wir die Anzahl der fuer die 
		Stichprobe ausgewaehlten Elemente und die Anzahl der Respondenten.
	Diese zwei Angaben berechnen wir im folgenden mit proc means. Anschliessend
	fuehren wir diese zwei neue Variablen mit dem Datensatz mit den Stichproben zusammen
	mittels
	data...
		merge...
		by...
	run...

 	Da wir dise Angaben fuer jede Stichprobe getrennt berechnen muessen,
	benutzen wir replicate in der by gruppe in proc means unten.
;

proc means data = psid.sim_smpl noprint;
	var resp;
	by replicate RHG;
	output out = psid.sim_smpl_info(drop = _TYPE_ rename = (_FREQ_ = rgh_sampled)) sum=rhg_resp_n;
run;


data psid.sim_smpl;
	merge psid.sim_smpl
			psid.sim_smpl_info;
	by replicate RHG;
run;


** Weiterhin muessen wir die Anzahl der gezogenen Personen pro Schicht angeben (Argument nsamp in CLAN).
	Hier haben wir keine Schichtung (oder nur 1 Schicht), deswegen berechnen wir fuer jede Stichprobe 
	die Anzahl der gezogenen Personen.

	Hier tun wir das, indem wir fuer jede Stichprobe die Anzahl der gezogenen aussumieren.
	Anschiessend fuehren wir auch diese Variable dem Datensatz hinzu.
;

proc means data = psid.sim_smpl_info noprint;
	by replicate;
	var rgh_sampled;
	output 
		out = psid.sim_smpl_strat_info(drop = _TYPE_ _FREQ_) 
		sum = strat_sampled
		;
run;


data psid.sim_smpl;
	merge psid.sim_smpl
			psid.sim_smpl_strat_info
			; 
	by replicate; 
run;


** Bevor wir zur Schaetzung uebergehen, entfernen wir die nichtrespondenten aus den Stichproben; 

data psid.sim_smpl;
	set psid.sim_smpl(where = (resp = 1));
run;


** Schritt 6: Schaetzung;


%macro repeatCLAN(dat=, /* In welchem Datensatz befinde sich die Stichproben?*/
						replicate_ind=replicate, /* Variable im Datensatz, die die Stichproben indiziert */
						simname= /*Name der Simulation. Wird benutzt, um den Outputdatensatz zu benennen */
						);
	%local n_rep;
	
	/* Wieviele Stichproben gibt es im Datensatz? */
	proc sql noprint;
		select count(distinct &replicate_ind) into :n_rep
		from &dat;
		%if &SQLOBS = 0 %then %goto exit;
	quit;	
	
	/* Entfernen von Leerzeichen in der Makrovariable n_rep */
	
	%let n_rep = %left(&n_rep);
		
	/** CLAN Setup: hier gibt es nichts neues **/
		
	%macro function(i, j);
		%tot(not_ins_tot, health_ins, 1);
		%tot(fam_inc_tot, fam_inc1, 1);
		%tot(debt_tot, debt_val1, 1);
		
		%tot(p_size, 1, 1);
		%div(not_ins_p, not_ins_tot, p_size);
		%div(fam_inc_mean, fam_inc_tot, p_size);
		%div(debt_mean, debt_tot, p_size);
		
		%estim(not_ins_p);
		%estim(fam_inc_mean);
		%estim(debt_mean);
	%mend;
		
	/* Makroschleife: Iteriert von 1 bis zur Anzahl der Stichproben */
		
	%do i = 1 %to &n_rep;
		
		/* Ein neuer Datensatz, der nur die Stichprobe i enthaelt */
		data rep&i;
			set &dat(where = (&replicate_ind = &i));
		run;
		
		/* CLAN Aufruf ohne RHG */
		%clan(data = rep&i, npop = 5761, nresp = rhg_resp_n, maxrow = 1, maxcol = 1);
		
		/* Dem Outputdatensatz von CLAN wird eine neue Variable hinzugefuegt, die die
			Nummer der Stichprobe angibt. Der Datensatz wird in Dut&i, d.h. Dut1 fuer die 
			erste Stichprobe, z.B., damit es in der naechsten Iteration nicht ueberschrieben
			wird.
		*/
		
		data Dut&i;
			set Dut;
			replicate = &i;
		run;
		
		/* CLAN Aufruf: RHG Modell */
		
		%clan(data = rep&i, R
				HG = YES, 
				npop = 5761, 
				groupid = RHG,
				ngroup = rgh_sampled, 
				nresp = rhg_resp_n, 
				nsamp = strat_sampled,
				maxrow = 1, maxcol = 1
				);
		
		/* Dasselbe wie oben */
		
		data DutRHG&i;
			set Dut;
			replicate = &i;
		run;	
	%end;
	
	/* Die Dut Datensaetze fuer von allen Iterationen werden in einen neuen Datensatz 
		untereinanergesetzt */
	
	data Dut_&simname;
		set Dut1-Dut&n_rep;
		__model__ = 1;
	run;
	
	/* Dasselbe fuer das RHG Modell */
	
	data DutRHG_&simname;
			set DutRHG1-DutRHG&n_rep;
			__model__ = 2;
	run;
	
	data Dut_&simname._all;
		set Dut_&simname DutRHG_&simname;
	run;
	
	/* Fuer jedes Modell und jede Variable wird der Mittelwert der Schatzungen berechnet */
	
	proc means data = Dut_&simname._all noprint;
	by __model__ row col;
	var p:;
		output
			out = Dut_&simname._means mean= std= /autoname;
	run;
	

	/** Clean up: Am Ende loeschen wir alle durch die Iterationen 
		 gebildeten Datensaetze, die wir nicht mehr brauchen **/

	proc datasets library = work;
		delete Dut1-Dut&n_rep DutRHG1-DutRHG&n_rep rep1-rep&n_rep;
	run; quit;

%exit:
%mend repeatCLAN;

** Jetzt fuehren wir das Makro aus;

%repeatCLAN(dat = psid.sim_smpl, simname = test);



** Nun koennen wir die Ergebnisse graphisch Darstellen;

proc boxplots data = Dut_test_all;
	plot pnot_ins_p*__model__ /vref = 0.1666;
run;

proc boxplots data = Dut_test_all;
	plot pfam_inc_mean*__model__ /vref = 60707.10;
run;


proc boxplots data = Dut_test_all;
	plot pdebt_mean*__model__ /vref = 7173.66;
run;
