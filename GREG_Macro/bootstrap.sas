/*Beispiel wie man Varianz mit bootstrap berechnen kann*/
/*Gleichzeitig Vergleich mit Bootstrap aus R Paket SURVEY*/
/*Bootstrap für apiclus1*/

PROC IMPORT DATAFILE="C:\Users\darek\Desktop\sas-cal_wc\greg in R\apiclus1.csv"
DBMS=csv
OUT=WORK.apiclus1;
RUN;

PROC IMPORT DATAFILE="C:\Users\darek\Desktop\sas-cal_wc\greg in R\apiclus2.csv"
DBMS=csv
OUT=WORK.apiclus2;
RUN;


data tot;
input stype;
datalines;
4421
755
1018
;
run;



data sample ;
  set apiclus1;
  pseudo_strat = 1;
run;



proc sql;
  create table _nsize_ as
  select pseudo_strat, count(VAR1) - 1 as _nsize_
  from sample
;
quit;


ODS LISTING CLOSE;
%let rep= 3000;
proc surveyselect 
  data=sample  (keep = VAR1 enroll pw pseudo_strat rename = (pw = DesignWeight))
  method= urs
  sampsize= _nsize_ 
  rep = &rep
  stats
  out= boots
;
strata pseudo_strat;

run;
ODS LISTING;



data boots ;
  merge _nsize_ boots;
  by pseudo_strat;
  w_r= (NumberHits*DesignWeight*_nsize_)/(_nsize_-1) ;
run;



proc sort data = boots out = boots;
  by var1;
run;


data boots;
  merge boots sample(keep = var1);
  by var1;
  if MISSING(w_r) then w_r = 0;
run; 


proc transpose data=boots out = boots2 prefix=Rep_wt;
  by var1;
  var w_r;
  id replicate;
run;

data boots2;
  set boots2;
  if not MISSING(var1);
  array _rep{*} rep_wt1-rep_wt&rep ;
  do i=1 to dim(_rep);
     if missing(_rep{i}) then _rep{i} = 0;
  end;
  drop i;
run;

proc sort data = boots out = boots;
  by replicate;
run;

ODS LISTING CLOSE;
ODS OUTPUT statistics=mean_boot;
PROC SURVEYMEANS DATA=boots mean;
  VAR enroll;
  WEIGHT w_r;
  BY Replicate;
RUN;
ODS OUTPUT CLOSE;
ODS LISTING;


ODS LISTING CLOSE;
ODS OUTPUT statistics=mean_sample (rename=(mean=mean_sample));
PROC SURVEYMEANS DATA=sample;
  VAR enroll;
RUN;
ODS OUTPUT CLOSE;
ODS LISTING;


data mean_boot ;
  merge mean_sample mean_boot;
  by VarName;
run;


data std_boot;
  set mean_boot;

  idx = "boot_std_mean";
  std=sqrt(var);
  if first.replicate then var=0;

  var + ((mean_sample-mean)**2)/(&rep-1);

  if replicate=&rep then output;
  keep std var;
run;
  

