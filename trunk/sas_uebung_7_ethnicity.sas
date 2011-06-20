
/* LFS 2005 */

proc freq data = uk.qlfs5(drop = piwt03 pwt03 caseno hhld thiswv persno recno);
	tables _numeric_ /missing;
run;

ods graphics off;

proc sgplot data = uk.qlfs5;
	hbox hourpay / category = ages;
run;


proc sort data = uk.qlfs5; by ages; run;

proc boxplot data = uk.qlfs5;
	plot hourpay*ages /clipfactor = 1.1;
run;

proc sgplot data = uk.qlfs5;
	scatter x = age y = hourpay;
run;
