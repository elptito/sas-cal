
/* SAS Macros: A gentle introduction */

** Definieren einer globalen Makrovariable; 

%let name = Amarov;
%let vorname = Boyko;

** Definieren eines SAS Makros;

%macro printName;
	
	%put Mein Name ist &name..;
	%put Einfuehrung in SAS Macros by &vorname_&name;

%mend printName;

%macro printNameArg(name);

	%put A SAS course by &name;

%mend printNameArg;

%printNameArg(Boyko Amarov);



data klausurWS;
	input Name $ fach note;
	datalines;
	Boyko 1 3.7
	Boyko 2 1.3
	Peter 1 2.3
	Peter 2 1
	Peter 3 5
	;
run;

data klausurSS;
	input Name $ fach note;
	datalines;
	Boyko 1 2
	Boyko 2 2.3
	Peter 1 1
	Peter 2 2.3
	Peter 3 1.3
	;
run;


%macro getResultsFor(teilnehmer_name);
	
	proc print data = klausurWS( where = ( Name = "&teilnehmer_name")); run;

%mend getResultsFor;

%getResultsFor(Boyko);


%macro getResultsFor(teilnehmer_name, semester);
	
	proc print data = klausur&semester.( where = ( Name = "&teilnehmer_name")); run;

%mend getResultsFor;

%getResultsFor(SS, Boyko);

options nomprint;

%macro getResultsFor(teilnehmer_name=, semester=);
	
	proc print data = klausur&semester.(where = ( Name = "&teilnehmer_name")); run;

%mend getResultsFor;

%getResultsFor(semester = SS, teilnehmer_name = Boyko);
