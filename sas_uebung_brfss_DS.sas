

libname brfss "PFAD EINSETZEN!";

options nofmterr fmtsearch = (work brfss.formats8) mstored sasmstore = sasuser;


** Was gitb es im Datensatz?;

proc contents data = brfss.Cdbrfs08 varnum; run;

