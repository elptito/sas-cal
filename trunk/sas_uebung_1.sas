

/* Uebung 1*/

** Einlesen der Daten;

libname dat "e:\proj\dmadata\srvsmpl\share\data\FDZ";

** Laden der Makros;

options nofmterr fmtsearch = (dat work) mstored sasmstore = sasuser;


data vse6;
	set dat.vse6;
			
	if missing(ef16u2) then delete;
run;


** Wie sieht die Population aus?
	
	In dieser Uebung betrachten wir zwei Untersuchungsvariablen: ef21 Brutto Monatseinkommen und 
	und die Hilfsmerkmale Wirtschaftszwweig (wzgruppe), Geschlecht (ef10) und Alter (gebildet als 2006 - Geburtsjahr (ef11)
;

** 0) Ueberpuefen, ob die Daten richtig eingelesen sind;

proc contents data = dat.vse6 varnum; run;

** 1) Bilden der Variable alter;

data vse6; ** Die Aenderungen werden in einen neuen Datensatz gespeichert, der sich in der work Bibliothek befindet;
	set vse6;
	
	alter = 2006 - ef11;
run;


** 2) Graphische Darstellung;

*** proc boxplot erwartet einen sortierten Datensatz, deswegen...;
proc sort data = vse6; by wzgruppe; run;

proc boxplot data = vse6;
	plot ef21*wzgruppe;
run;

proc sort data = vse6; by ef10; run;

proc boxplot data = vse6;
	plot ef21*ef10;
run;

** 2 a) Bilden von Altersgruppen;

data vse6;
	set vse6;
	
	%cut(var = alter, newvar = alterGr, breaks = 25 35 45 55, right = 0);	
run;


proc sort data = vse6; by alterGr ef10 ; run;

proc boxplot data = vse6;
	plot ef21*(alterGr ef10);
run;


** Wir ziehen eine Stichprobe vom Umfang n;

%let n = 500;


proc surveyselect
	data = vse6
	method = SRS
	sampsize = &n
	stats
	out = vse6_smpl(rename = (samplingWeight = des_gew))
	seed = 54321
	;
run;

** Berechnen des pi-Schaetzers mit proc surveymeans;

proc surveymeans
	data = vse6_smpl
	N = 60551
	mean
	;
	var ef21;
	weight des_gew;
run;

**	Berechnung des pi-Schaetzers mit CLAN;

%macro function(i, j);
	
	%tot(ef21_tot, ef21, 1);
	%tot(p_size, 1, 1);
	%div(ef21_mean, ef21_tot, p_size);
	
	%estim(ef21_mean);
%mend function;


%clan(data = vse6_smpl, npop = 60551, nresp = &n, maxrow = 1, maxcol = 1);

title "pi-Schaetzer: Mittelwert ef21";
proc print data = Dut; run;



** Poststratifizierung nach wzgruppe;

proc freq data = vse6;
	table wzgruppe /out = wzgruppe_tbl;
run;


data clan_aux_input;
	length Var $ 32.;
	input Var $ n MAR1 MAR2 MAR3 MAR4 MAR5 MAR6 MAR7 MAR8 MAR9 MAR10;
		
	datalines;
	wzgruppe 10 3043 14071 1459 2190 4887 1188 5996 2208 15668 9841
	;
run;



%macro function(i, j);
	%auxvar(datax = clan_aux_input, wkout = cal_gew, datawkut = vse6_smpl, ident = bes_id);
	
	%tot(ef21_tot, ef21, 1);
	%tot(p_size, 1, 1);
	
	%greg(ef21_tot_reg, ef21, 1);
	
	%div(ef21_mean, ef21_tot, p_size);
	%div(ef21_mean_reg, ef21_tot_reg, p_size);
	

	%estim(ef21_mean);
	%estim(ef21_mean_reg);
%mend function;

%clan(data = vse6_smpl, npop = 60551, nresp = &n, maxrow = 1, maxcol = 1);

title "GREG-Schaetzer: Mittelwert ef21";
proc print data = Dut; run;


** Kalibration nach wzgruppe und Geschleht;

%gregeri(formula = ~ wzgruppe + ef10 + alterGr + ef16u2, sframe = vse6, aux_out_file = CLAN_IN_wzgruppe_ef10);


%macro function(i, j);

	%auxvar(datax = CLAN_IN_wzgruppe_ef10);
	
	%tot(ef21_tot, ef21, 1);
	%tot(p_size, 1, 1);
	
	%greg(ef21_tot_reg, ef21, 1);
	
	%div(ef21_mean, ef21_tot, p_size);
	%div(ef21_mean_reg, ef21_tot_reg, p_size);
	

	%estim(ef21_mean);
	%estim(ef21_mean_reg);

%mend function;

%clan(data = vse6_smpl, npop = 60551, nresp = &n, maxrow = 1, maxcol = 1);

proc print data = Dut; run;

** 3) Wir betrachten die Tabelle wzgruppe*geschlecht und moechten die gemeinsame Verteilung schaetzen.;

** 3a) Mit proc surveymeans;

data vse6_smpl;
	set vse6_smpl;

	unit = 1;
run;

** 	Im folgenden ist wichtig, das domain statement zu verwenden, 
	damit richtige Standardfehler ausgegeben werden;

proc surveymeans
	data = vse6_smpl
	N = 60551
	sum
	;
	var unit;
	weight des_gew;
	domain wzgruppe*ef10
	;
run;


** Das folgende ist FALSCH! Beachte die Warnung, die im SAS log ausgegeben wird;

proc sort data = vse6_smpl; by wzgruppe ef10; run;

proc surveymeans
	data = vse6_smpl
	N = 60551
	sum
	;
	var unit;
	weight des_gew;
	by wzgruppe ef10;
run;


** 3b) Mit CLAN97;

%macro function(i, j);

	%tot(freq_ij, 1, wzgruppe = &i and ef10 = &j);
	%estim(freq_ij);

%mend function;


%clan(data = vse6_smpl, npop = 60551, nresp = &n, maxrow = 10, maxcol = 2);

proc print data = Dut; run;

** 3c) Mit Randanpassung;

%gregeri(formula = ~ wzgruppe + ef10, sframe = vse6, aux_out_file = CLAN_IN_wzgruppe_ef10);

%macro function(i, j);
	%auxvar(datax = Clan_in_wzgruppe_ef10);
	
	%tot(freq_ij, 1, wzgruppe = &i and ef10 = &j);
	

	%greg(freq_ij_reg, 1, wzgruppe = &i and ef10 = &j);
	
	%estim(freq_ij);
	%estim(freq_ij_reg);
%mend function;


%clan(data = vse6_smpl, npop = 60551, nresp = &n, maxrow = 10, maxcol = 2);

proc print data = Dut; run;


/* 4) CLAN und geschichtete Stichproben */

proc sort data = vse6; by wzgruppe; run;

proc surveyselect
	data = vse6
	samprate = 0.01
	method = SRS
	stats
	seed = 54231
	out = vse6_stsi(rename = (samplingWeight = des_gew))
	;
	strata wzgruppe;
run;


proc sort data = vse6; by wzgruppe; run;

proc means data = vse6 noprint;
	by wzgruppe;
	output
		out = strata_pop_gr(drop = _FREQ_ _TYPE_)
		N = wzgruppe_pop_groesse
		;
run;

proc sort data = vse6_stsi; by wzgruppe; run;

proc means data = vse6_stsi noprint;
	by wzgruppe;
	output
		out = strata_smpl_gr(drop = _FREQ_ _TYPE_)
		N = wzgruppe_smpl_gr
		;
run;

data vse6_stsi;
	merge 
		vse6_stsi
		strata_pop_gr
		strata_smpl_gr
		;
	by wzgruppe;
run;


%macro function(i, j);
	%tot(ef21_tot, ef21, 1);
	%tot(p_size, 1, 1);

	%div(ef21_mean, ef21_tot, p_size);
	
	%estim(ef21_mean);
%mend function;

%clan(data = vse6_stsi, stratid = wzgruppe, npop = wzgruppe_pop_groesse, nresp = wzgruppe_smpl_gr, maxrow = 1, maxcol = 1);



