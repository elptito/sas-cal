/* PSID 2003-2007 

Datenaufbereitung:

1) 	Nur Personen im Alter 21-65 Jahre
2) 	Nur Personen, die in 2003 Respondenten waren (i.e. kein Nonresponse, 
	keine Personen in Institutionen.
3)  

*/

options nofmterr fmtsearch = (work cps.formats) mstored sasmstore = sasuser;

/**
proc contents data = psid.p0107_raw; run;
**/

