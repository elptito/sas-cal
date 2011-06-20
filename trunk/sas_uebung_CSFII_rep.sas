
/* CSFII 1994-1996, 1998 

Datenaufbereitung:


*/

options nofmterr fmtsearch = (work csfii.formats) mstored sasmstore = sasuser;

/** 
proc contents data = csfii.rt20 memtype = data; run;
proc contents data = csfii.rt25 memtype = data; run;
proc contents data = csfii.rt30 ; run;
proc contents data = csfii.rt35 memtype = data; run;
proc contents data = csfii.rt40 memtype = data; run;

proc contents data = csfii.Jkwanndh memtype = data; run;

proc sort data = csfii.rt30; by hhid spnum; run;
**/

proc means data = csfii.rt30(where = (year = 1996 and daycode = 1))
	noprint;
	by hhid spnum;
	var sodium calcium carbo energy alcohol caffeine;
	id 	wta_day1 age INCREP race region sex varstrat varunit povcat 
		impflag inccode income
		origin;
	output 
		out = csfii.nutri_amnt96(drop = _TYPE_ _FREQ_) sum= /autoname;
run;

proc sort 	data = csfii.jkwanncs(where = (year = 1996) keep = YEAR hhid spnum RA_D1_:)
			out = csfii.nutri_jackw; 
	by hhid spnum;
run;



proc format library = csfii.formats;
	value yes10no
		1 = 'Yes'
		0 = 'No'
		;
	value racem
		1 = 'White'
		2 = 'Black'
		3 = 'Asian, Pacific'
		4 = 'Other'
		;
	value age6Gr
		1 = '0-20'
		2 = '21-30'
		3 = '31-50'
		4 = '51-60'
		5 = '61-70'
		6 = '71+'
		;
run;

data csfii.nutri_amnt96;
	merge
		csfii.nutri_amnt96(in = in_nutri)
		csfii.nutri_jackw
		;
	by hhid spnum;
	
	if in_nutri;
	
	if origin = 5 then hispanic = 0;
	else hispanic = 1;
	format hispanic yes10no.;
	
	if race = 5 then race = 4;
	format race racem.;
	
	%cut(var = age, newvar = ageGr6, breaks = 20 30 50 60 70);
	format ageGr6 age6Gr.;
	
	if impflag ne 1 then call missing(increp);
run;


proc datasets library = csfii;
	modify nutri_amnt96;
	format
		sex sex.
		region region.
		increp increp.
		origin origin.
		;
run;
quit;
	

proc sql;
	create table csfii.hh_counts as 
		select varstrat, varunit, count(distinct hhid) as hh_cnt
		from csfii.nutri_amnt96
		group by varstrat, varunit;

	create table csfii.nutri_amnt96 as
		select nutri.*, cnts.hh_cnt
		from csfii.nutri_amnt96 as nutri join csfii.hh_counts as cnts
		on nutri.varstrat = cnts.varstrat and nutri.varunit = cnts.varunit;
quit;


proc sort data = csfii.nutri_amnt96; by varstrat varunit hhid; run;


** WARNING: depends on the dataset being sorted on both varstrat and varunit;

data csfii.pseudo_data
	  ;
	retain pseudo_strat pseudo_psu hhid upid __psu varunit;
	set csfii.nutri_amnt96;
	by varstrat varunit hhid;
	
	if _n_ = 1 then
		do;
			hhid_cntr = 0;
			__psu = 0;
		end;
	
	%cut(var = varstrat, newvar = pseudo_strat, breaks = %seq(2, 43, 2));
	
	if varunit ne lag1(varunit) then hhid_cntr = 0;
	
	if first.hhid then hhid_cntr + 1;
	
	if hh_cnt > 6 then 
		do;
			if hhid_cntr < hh_cnt/3 then __psu = 1;
			else 
			if hhid_cntr < 2*hh_cnt/3 then __psu = 2;
			else
			__psu = 3;
		end;
	else __psu = 1;
	
	__psu = 100*varstrat + 10*varunit + __psu;
	
	if __psu ne lag1(__psu) then pseudo_psu + 1;

	_Intercept_ = 1;
	
	upid = 1000*pseudo_psu + 100*hhid + spnum;
	
	drop hhid_cntr hh_cnt __psu RA_D1_: YEAR WTA_DAY1 varstrat varunit;
	*put _n_= hhid_cntr= hh_cnt= __psu= psu= varunit=;
run;

/**
proc sql;
	select count(distinct hhid) as cnt from csfii.pseudo_data
	group by pseudo_psu
	order by cnt;
quit;
**/
