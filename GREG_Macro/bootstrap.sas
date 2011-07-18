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





proc surveyselect data=universe noprint
                  out=sample	 
                  method=SRS
                  sampsize=400
                  stats ;         *stats generates weights;
   
run;


data sample ;
  set sample;
  pseudo_strat = 1;
run;


proc sql;
  create table  _nsize_ as
  select replicate as replicate2, count(PID) - 1 as _nsize_
  from res
  group by replicate
;
quit;



%let rep= 10 ;

proc surveyselect 
  data=res(keep = PID earnings replicate SamplingWeight rename = (SamplingWeight = DesignWeight replicate =replicate2))
  method= urs
  sampsize= _nsize_ 
  rep = &rep
  stats
  out= boots(rename = (SamplingWeight = bootw))
;
strata replicate2;

run;

data boots ;
  merge _nsize_ boots;
  by replicate2;
  w_r= NumberHits*DesignWeight*_nsize_/(_nsize_-1) ;
run;




data boots;
  merge boots sample(keep = PID );
  by pid;
  if MISSING(w_r) then w_r = 0;
run; 


proc transpose data=boots out = boots2 prefix=Rep_wt;
  by pid;
  var w_r;
  id replicate;
run;

data boots2;
  set boots2;
  array _rep{*} rep_wt1-rep_wt10 ;
  do i=1 to dim(_rep);
     if missing(_rep{i}) then _rep{i} = 0;
  end;
  drop i;
run;



ODS LISTING CLOSE;
ODS OUTPUT statistics=mean_boot;
PROC SURVEYMEANS DATA=boots mean;
  VAR earnings;
  WEIGHT w_r;
  BY Replicate2 replicate;
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


data std_boot;
  set mean_boot;
  do i = 1 to &B;
    if i = replicate2 then do;
      if replicate eq 1 then s=0;
      s + (mean-mean_sample)**2/(&rep-1); 
    end;
    output;
  end; 
run;
  
