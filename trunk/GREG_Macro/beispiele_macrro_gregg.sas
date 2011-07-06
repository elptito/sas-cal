/*BEISPIELE*/

/*Erzeugung von ein Datensatz Universe von library human_cap*/
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


/*******************************BEISPIEL I*********************************************************************/
/*Datensatz TOTALS1, mit Hilfe von PROC FREQ werden die Totals von Datensatz Universe bestimmt*/
ods output onewayfreqs=totals1 ;
proc freq data=universe;
  table  gender_cohort marital_status;
run;
ods output close;


/*alle Totals werden als eine Spalte gespeichert, NOTWENDIG FÜR GREG-MACRO!*/
data totals1;
  set totals1;
  x_ID= coalesce(gender_cohort, marital_status);
  keep frequency x_ID table;
run;


/*Stichprobe SAMPLE, gezogen aus dem Datensatz Univere*/
proc surveyselect data=universe 
                  out=sample	 
                  method=SRS
                  sampsize=1000
                  stats ;         *stats generates weights;
   
run;

options mprint;
/*Macro wird aufgerufen - Model: earnings= gender_cohort + marital_status*/
%gregar(sample = sample                     /*Stichprobe*/
     ,y = earnings                          /*y-Variable*/
     ,X =  gender_cohort marital_status     /*x-variablen*/
     ,sampling_weight = SamplingWeight      /*Spalte Gewichte*/
     ,totals = totals1                      /*Datensatz mit Totals und x-ID*/
     ,class = gender_cohort marital_status  /*Auflistung von diskrete Varibalen*/
     );



/*--------Berechnung von std. Fehler-----------*/
ODS OUTPUT statistics=HT_residuals;
PROC SURVEYMEANS DATA=results SUM ;
  VAR residual_reg;
  WEIGHT samplingweight;
RUN;
ODS OUTPUT CLOSE;

/*---------------------GREG-------------------*/
DATA greg;
  MERGE y_hat_sum ht_residuals ;
  t_greg=y_hat_sum+sum ;
  std_Greg=stddev ;
  KEEP T_Greg std_greg;
RUN; 


/*Ausgabe GREG-Schätzer und standard Fehler*/
TITLE "GREG REGRESSION";
PROC REPORT DATA=greg
            NOWINDOWS HEADLINE;
  DEFINE t_greg / 'Total Value' WIDTH=11;
  DEFINE std_Greg / 'Std.Dev.';
RUN; 


/****************************ENDE BEISPIEL I**********************************************************************/



/*******************************BEISPIEL Ia -stetige Variable******************************************************/

ods output summary=totals1a ;                /*Vektor TOTALS für stetige variable born*/
proc means data=universe sum;
  var born;
run;
ods output close;

%gregar(sample = sample                     /*Stichprobe*/
     ,y = earnings                          /*y-Variable*/
     ,X =  born                             /*x-variablen*/
     ,sampling_weight = SamplingWeight      /*Spalte Gewichte*/
     ,totals = totals1a                     /*Datensatz mit Totals und x-ID*/
     ,name_frq = born_Sum                   /*name der Spalte mit TOTALS*/
     );
/****************************ENDE BEISPIEL Ia**********************************************************************/



/*******************************BEISPIEL Ib - stetige und diskrete Variablen***************************************/

ods output summary=totals1a ;
proc means data=universe sum;
  var born;
run;
ods output close;

data totals1b;                                   /*Vektor TOTALS für Variablen born, gender_cohort, marital_status */                                 
  set  totals1a totals1;
  frequency= coalesce(frequency, born_Sum);
  keep frequency Table x_ID;
run;


%gregar(sample = sample                           /*Stichprobe*/
     ,y = earnings                                /*y-Variable*/
     ,X =  born gender_cohort marital_status      /*x-variablen*/
     ,sampling_weight = SamplingWeight            /*Spalte Gewichte*/
     ,totals = totals1b                           /*Datensatz mit Totals und x-ID*/
     ,class = gender_cohort marital_status        /*Auflistung von diskrete Varibalen*/
     );
/*************************************************ENDE BEISPIEL Ib************************************************/


/*******************************BEISPIEL Ic - Regression mit Intercept********************************************/

DATA count;
  frequency = 13119;
RUN;


data totals1c;                                   /*Vektor TOTALS für intercept. gender_cohort, marital_status */                                 
  set  count totals1;
  keep frequency table x_ID;
run;


%gregar(sample = sample                           /*Stichprobe*/
     ,y = earnings                                /*y-Variable*/
     ,X =  gender_cohort marital_status           /*x-variablen*/
     ,sampling_weight = SamplingWeight            /*Spalte Gewichte*/
     ,totals = totals1c                           /*Datensatz mit Totals und x-ID*/
     ,class = gender_cohort marital_status        /*Auflistung von diskrete Varibalen*/
     ,noint = 0
     );
/*************************************************ENDE BEISPIEL Ic************************************************/




/************************************BEISPIEL II - mit strata*****************************************************/
/*Erzeugung von ein Datensatz universe2 = sortierte nach merital_status universe, notwengig für Stichprobeziehen mit Schichten*/
proc sort data=universe
  out=universe2;
  by marital_status;
run;

/*Geschichtete Stichprobe SAMPLE2, gezogen aus dem Datensatz Universe2*/
proc surveyselect data=universe2 
                  out=sample2	 
                  method=SRS
                  sampsize=100
                  stats ;  * stats generates weights;
                  strata marital_status; /*Schichtung bei merital_status*/
run; 

/*Datensatz TOTALS2, mit Hilfe von PROC FREQ werden die Totals von Datensatz Universe2 bestimmt*/
ods output onewayfreqs=totals2;
proc freq data=universe2;
  table gender_cohort;
run;
ods output close;

data totals2;
  set totals2;
  x_id= coalesce(gender_cohort, marital_status);
  test=cat(scan(table,2),' ', x_id);
  keep frequency test;
run;



/*Macro wird aufgerufen - Model: earnings= gender_cohort, Schichtung per marital_status */
%gregar(sample = sample2                  /*Stichprobe*/
     ,y = earnings                        /*y-Variable*/
     ,X =  gender_cohort                  /*x-variablen*/
     ,sampling_weight = SamplingWeight    /*Spalte Gewichte*/
     ,totals = totals2                    /*Datensatz mit Totals und x-ID*/
     ,strata = marital_status             /*Schichtung per marital_status*/
     );
/*****************************************ENDE BEISPIEL II************************************************************/



/*************************************BEISPIEL III - mit cluster******************************+***********************/
/*Erzeugung von ein Datensatz SAMPLE3 mit clustern marital_status = 1 und 2*/
data universe3_temp;
  set universe ;
  if marital_status = 1 or marital_status = 2;
run;


proc sort data=universe3_temp
  out=universe3;
  by marital_status;
run;

proc surveyselect data=universe 
                  out=gewichte	 
                  method=SRS
                  stats  
                  sampsize=11714;              * stats generates weights;
run; 

DATA gewichte;
  set gewichte;
  keep SelectionProb SamplingWeight;
RUN;


/*Eine Stichprobe mit cluster merital_status wird erschafft*/
data sample3;
  merge universe3 gewichte;
RUN;


/*Datensatz TOTALS3, mit Hilfe von PROC FREQ werden die Totals von Datensatz Universe bestimmt*/
ods output onewayfreqs=totals3;
proc freq data=universe3;
  table gender_cohort;
run;
ods output close;

data totals3;
  set totals3;
  x_id= coalesce(gender_cohort, marital_status);
  test=cat(scan(table,2),' ', x_id);
  keep frequency test;
run;



/*Macro wird aufgerufen - Model: earnings= gender_cohort, Schichtung per marital_status */
%gregar(sample = sample3                    /*Stichprobe*/
     ,y = earnings                        /*y-Variable*/
     ,X =  gender_cohort                  /*x-variablen*/
     ,sampling_weight = SamplingWeight    /*Spalte Gewichte*/
     ,totals = totals3                    /*Datensatz mit Totals und x-ID*/                          
     ,cluster = marital_status
     );

/*********************************************ENDE BEISPIEL III*********************************************************/







*ods trace on/ listing;
*ods trace off;
