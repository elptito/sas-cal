
/*
	Ziel dieser 
*/

libname dat "e:\proj\dmadata\srvsmpl\share\data\FDZ";

options nofmterr fmtsearch = (dat work) mstored sasmstore = sasuser;


proc contents data = dat.gkv_jahr varnum; run;

proc contents data = dat.gkv_amb varnum; run;

proc sort data = dat.gkv_amb; by ef4_311; run;

proc sgplot data=dat.gkv_amb;
  title "Ausgaben nach Fachrichtung des Artztes";
  hbox ef5_311 / category=ef4_311;
run;

proc freq data = dat.gkv_amb;
	tables ef4_311;
run;
