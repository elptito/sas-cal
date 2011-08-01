data universe;
  set mysas.human_cap;
  if svyyear=2000;                            * only observartions from 2000;
  born=svyyear-age;                           * generation of cohorts ;
  if born lt 1930 
    then delete;                              * older than 60 in 1990 ;
  cohort=int((born-1930)/10);                 * 10 year cohorts ;
  gender_cohort=10*gender+cohort;             * geneder*cohort groups ;
  if marital_status ge 5 
    then marital_status=4;                    * combine divorced + separated ;
  keep pid gender born marital_status cohort gender_cohort earnings;
 run;



/*********************BOOTS SIMULATION************************************/
/*Es ist eine Ergenzung für Simulation. 
  Die Varinaz wird mit Bootstrap geschätz und zusammen mit calibrierte Varianz und jackknife varianz in ein Boxplot gezeigt*/
/*Funktioniert NUR mit dem Datensatz res, erzeugt durch simulation*/
/*Schätz die Varinaz mit Hilfe von Bootstrap Methode und Vergleich es mit BRR und Jackknife*/


/*Bestimmung von n-1 für Bootstrap*/
proc sql;
  create table  _nsize_ as
  select replicate as replicate2, count(PID) - 1 as _nsize_
  from res
  group by replicate
;
quit;



%let rep= 300; /*Anzahl Bootstraps*/

/*Datensatz boots*/
proc surveyselect 
  data=res(keep = PID earnings replicate SamplingWeight rename = (SamplingWeight = DesignWeight replicate =replicate2))
  method= urs
  sampsize= _nsize_ 
  rep = &rep
  stats
  out= boots(rename = (SamplingWeight = bootw replicate = boots_sample))
;
strata replicate2;

run;

/*Berechnung von boots Gewichte*/
data boots ;
  merge _nsize_ boots;
  by replicate2;
  w_r= (NumberHits*DesignWeight*_nsize_)/(_nsize_-1) ;
run;

/*
proc sort data = boots out = boots;
  by pid;
run;


data boots;
  merge boots ;
  by pid;
  if MISSING(w_r) then w_r = 0;
run; 

proc sort data = boots out = boots;
  by replicate;
run;
*/

/*datensatz boots2*/
proc transpose data=boots out = boots2 prefix=Rep_wt;
  by replicate2 pid;
  var w_r;
  id boots_sample;
run;

data boots2;
  set boots2;
  if not MISSING(replicate2);
  array _rep{*} rep_wt1-rep_wt&rep ;
  do i=1 to dim(_rep);
     if missing(_rep{i}) then _rep{i} = 0;
  end;
  drop i;
run;


/*Berechnung von boots Varianz*/

/*Hilfs mean*/
ODS LISTING CLOSE;
ODS OUTPUT statistics=mean_boot;
PROC SURVEYMEANS DATA=boots mean;
  VAR earnings;
  WEIGHT w_r;
  BY Replicate2 boots_sample;
RUN;
ODS OUTPUT CLOSE;
ODS LISTING;

ODS LISTING CLOSE;
ODS OUTPUT statistics=mean_sample (rename=(mean=mean_sample));
PROC SURVEYMEANS DATA=boots mean;
  VAR earnings;
  by replicate2;
RUN;
ODS OUTPUT CLOSE;
ODS LISTING;


data mean_boot ;
  merge mean_sample mean_boot;
  by replicate2;
run;

/*Berechnung*/
data var_boot;
  set mean_boot;
  by replicate2;
  idx = "boot_var_mean";
  if first.replicate2 then var=0;
  var + ((mean_sample-mean)**2)/(&rep-1);

  if last.replicate2 then output;

run;
  

/*datansatz für Boxplot*/
data for_boxplot3;
  set var_sim var_jk_sim var_boot;
run;



proc boxplot data= for_boxplot3;
  plot var*idx / vref = earnings_sim_mean_var;
run;

