

/*
  Macro für Berechnung von GREG-Schätzer 
  GREG Schätzer (Form: alpha + B_1*x_1 + B_2*x_2+ ... + = y).
  Datensatz mit B_1, B_2,... wird bestimmt und unter ESIMATE gespeichert.
  Datensatz mit Gewichte, Residuen, g_k, w_k, w_k*Residuum wird bestimmt und unter RESULTS gespeichert.
  Datensatz mit total_y wird bestimmt und unter y_hat_sum gespeichert.
*/

option nofmterr;
/*Macro greg wird implementiert, Eingaben werden deklariert*/
%MACRO gregar(sample =                 /*Datensatz Stichprobe, muss folgende Spalten beinhalten: y, x1, x2,..., Gewichte*/
             ,y =                      /*Name der y-Spalte/Variable*/ 
             ,X =                      /*Beschreibung des Modells*/
             ,class =                  /*Wenn die deskrete Variable in Modell vorkommen, müssen die hier aufgelistet werden */
             ,sampling_weight =        /*Name der Gewichten-Spalte*/
             ,totals =                 /*Datensatz mit x-totals, Totals müssen in eine Spalte gespeicher werden, Reihenfolge: x1, x2, x3, ...
                                         Für den Fall eine Regression mit Intercept, kommt als erstes der Gesamtzahl der Population ("Total" für Intercept)*/
             ,name_frq = frequency     /*Name der Spalte mit x-totals muss angegeben werden, default = frequency*/
             ,strata =                 /*Name der Schichtung-variable, wenn keine Schichtung vorliegt, dann leer lassen*/
             ,cluster =                /*Name der Cluster-variable, wenn keine Clusterung vorliegt, dann leer lassen*/
             ,noint = 1                /*Entscheidung zwischen Modell mit/ohne Intercept (1 = kein Intercept) */
             ,replicate_method = null  /*default NULL*/
             ,rep = 100
             ,results_name = results
             )  / minoperator;

%local intercept rep_statement;
%if &noint = 0 %then %let intercept = ;
%else %let intercept = noint;

/*************************************************************************/
/************************Prozedur für GREG *******************************/
/*************************************************************************/
/*-------proc survey reg, Berechnung von B_hat------------*/


%if  %upcase(&replicate_method) eq JACKKNIFE %then
  %do;
    %let rep_statement =;
  %end;
%else
  %do;
     %let rep_statement = %quote(rep = &rep);
 %end;

DATA _sample;
  SET &sample;
  KEEP &y &x &strata &cluster &sampling_weight;
RUN;



ODS LISTING CLOSE;
ODS OUTPUT PARAMETERESTIMATES=estimate INVXPX=inverse;
PROC SURVEYREG DATA= _sample 
  %if %upcase(&replicate_method) # (BRR, JACKKNIFE) %then
    %do;
      VARMETHOD=&replicate_method(%unquote(&rep_statement) OUTWEIGHTS = &sample._&replicate_method)
    %end;
  ;
  STRATA &strata;
  CLUSTER &cluster;
  CLASS  &class;
  MODEL  &y=&x / &intercept SOLUTION INVERSE vadjust=none;
  WEIGHT &sampling_weight;
  OUTPUT OUT=from_reg r=residual_reg p=predicted_reg;
RUN;
ODS OUTPUT CLOSE;
ODS LISTING;




/*Spalte Estimate wird beibehalten, Rest weggeschmissen*/
DATA estimate;
  SET estimate;
  KEEP estimate parameter; 
RUN;





/*--------GREG IML, Berechnung von w_k------------*/

/*Erzeugung von Designmatrix*/
PROC LOGISTIC DATA = &sample OUTDESIGN = design_x(DROP = &y) OUTDESIGNONLY NOPRINT;
		CLASS &class  / PARAM = glm ORDER = internal;
		MODEL &y = &x  / &intercept;
    STRATA &strata;
RUN;

/*Proc IML*/
PROC IML;
	USE &totals;
	READ all VAR {&name_frq} INTO poptotal;
	USE inverse;
	READ all INTO XWXginv;
  USE design_x;
  READ all INTO x;
  USE &sample;
  
  READ all VAR {&sampling_weight} INTO weight;

  tot= x#weight;
  t_pi_estimate=t(tot[+,]);

	correction = poptotal - t_pi_estimate;
  lambda= XWXginv*correction;

	g = 1+x*lambda;

  w = g#weight;
  a= w||g;

	CREATE weight FROM a; 
	APPEND FROM a; 
QUIT;


%if %upcase(&replicate_method) # (BRR, JACKKNIFE) %then %do;
    DATA &sample._&replicate_method;
     SET &sample._&replicate_method;
     DROP &y &x &strata &cluster &sampling_weight;
    RUN;

    DATA &results_name;
      MERGE &sample from_reg(KEEP = predicted_reg residual_reg) weight(rename = (COL1 = wk COL2 = gk)) &sample._&replicate_method;
     res_gk = gk*residual_reg;
    RUN;

 %end;
 %else %do;
   DATA &results_name;
    MERGE &sample from_reg(KEEP = predicted_reg residual_reg) weight(rename = (COL1 = wk COL2 = gk));
    res_gk = gk*residual_reg;
  RUN;
%end;
  

/*
PROC DATASETS LIBRARY = work;
    DELETE Design_x From_reg y_hat inverse  weight from_reg _sample ;
  RUN;
QUIT;
*/


/*--------Berechnung von std. Fehler-----------*/
/*
ODS OUTPUT statistics=HT_residuals;
PROC SURVEYMEANS DATA=from_reg SUM;
  *VAR residual_reg;
  VAR res_gk;
  WEIGHT wk;
  *WEIGHT &sampling_weight;
  STRATA &strata;
  CLUSTER &cluster;
RUN;
ODS OUTPUT CLOSE;
*/

/*---------------------GREG-------------------*/
/*
DATA greg;
  MERGE y_hat_sum ht_residuals ;
  t_greg=y_hat_sum+sum ;
  std_Greg=stddev ;
  KEEP T_Greg std_greg;
RUN; 
*/
/*Ausgabe GREG-Schätzer und standard Fehler*/
/*
TITLE "GREG REGRESSION";
PROC REPORT DATA=greg
            NOWINDOWS HEADLINE;
  DEFINE t_greg / 'Total Value' WIDTH=11;
  DEFINE std_Greg / 'Std.Dev.';
RUN; */

%MEND;



