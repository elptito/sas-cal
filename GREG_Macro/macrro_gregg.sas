

/*
  Macro für Berechnung von GREG-Schätzer 
  GREG Schätzer (Form: alpha + B_1*x_1 + B_2*x_2+ ... + = y).
  Datensatz mit B_1, B_2,... wird bestimmt und unter ESIMATE gespeichert.
  Datensatz mit Gewichte, Residuen, g_k, w_k, w_k*Residuum wird bestimmt und unter RESULTS gespeichert.
  Datensatz mit total_y wird bestimmt und unter y_hat_sum gespeichert.
*/

option nofmterr;
/*Macro greg wird implementiert, Eingaben werden deklariert*/
%MACRO gregar(sample =               /*Datensatz Stichprobe, muss folgende Spalten beinhalten: y, x1, x2,..., Gewichte*/
           ,y =                      /*Name der y-Spalte/Variable*/ 
           ,X =                      /*Beschreibung des Modells*/
           ,class=                   /*Wenn die deskrete Variable in Modell vorkommen, müssen die hier aufgelistet werden */
           ,sampling_weight =        /*Name der Gewichten-Spalte*/
           ,totals =                 /*Datensatz mit x-totals, Totals müssen in eine Spalte, als "Vektor", gespeicher werden, Reihenfolge: x1, x2, x3, ...
                                       Für den Fall eine Regression mit Intercept, kommt als erstes der Gesamtzahl der Population ("Total" für Intercept)*/
           ,name_frq = frequency     /*Name der Spalte mit x-totals muss angegeben werden, default = frequency*/
           ,strata =                 /*Name der Schichtung-variable, wenn keine Schichtung vorliegt, dann leer lassen*/
           ,cluster =                /*Name der Cluster-variable, wenn keine Clusterung vorliegt, dann leer lassen*/
           ,noint = 1                /*Entscheidung zwischen Modell mit/ohne Intercept (1 = kein Intercept) */
           ,replicate_method =
           ,rep = 100
           )  / minoperator;

%local intercept strata_sql rep;
%if &noint = 0 %then %let intercept = ;
%else %let intercept = noint;

/*************************************************************************/
/************************Prozedur für GREG *******************************/
/*************************************************************************/
/*-------proc survey reg, Berechnung von B_hat------------*/

/*
%IF &replicate_method = brr %THEN %DO;
ODS OUTPUT ONEWAYFREQS=y;
PROC FREQ DATA=&sample;
TABLE &strata;
RUN;
ODS OUTPUT CLOSE;

ODS OUTPUT onewayfreqs=yy;
PROC FREQ DATA =y;
TABLE table;
RUN;
ODS OUTPUT CLOSE;

ODS OUTPUT summary=yyy;
PROC MEANS DATA=yy sum;
VAR frequency;
RUN;
ODS OUTPUT CLOSE;

PROC SQL ;
  SELECT * INTO : rep
  FROM yyy;
QUIT;
%END;
%ELSE %IF &replicate_method = jackknife %THEN %DO;
PROC SQL ;
  SELECT COUNT(&y) INTO : rep
  FROM &sample;
QUIT; */

%if  %UPCASE(&replicate_method) eq JACKKNIFE %THEN
  %DO;
    %let rep_statement =;
  %END;
%ELSE
  %DO;
     %let rep_statement = %quote(rep = &rep);
  %END;

ODS OUTPUT PARAMETERESTIMATES=estimate INVXPX=inverse;
PROC SURVEYREG DATA= &sample 

  
  %IF %UPCASE(&replicate_method) # (BRR, JACKKNIFE) %THEN
    %DO;
      VARMETHOD=&replicate_method(%unquote(&rep_statement) OUTWEIGHTS = &sample._&replicate_method)
    %END;

  ;
  
  STRATA &strata;
  CLUSTER &cluster;
  CLASS  &class;
  MODEL  &y=&x / &intercept SOLUTION INVERSE vadjust=none;
  WEIGHT &sampling_weight;
  OUTPUT OUT=from_reg r=residual_reg p=predicted_reg;
RUN;
ODS OUTPUT CLOSE;

/*Spalte Estimate wird beigehalten, Rest weggeschmissen*/
DATA estimate;
  SET estimate;
  KEEP estimate parameter; 
RUN;


/*Berechnungvon y_hat=B*x */
DATA y_hat;
  MERGE estimate &totals;
  y_hat=&name_frq*estimate;
  KEEP y_hat ;
RUN;


/*Berechnung von t_x'*B_hat= sum(y_hat)*/
ODS OUTPUT summary = y_hat_sum ;  
PROC MEANS DATA= y_hat SUM;
  VAR y_hat;
RUN;
ODS OUTPUT CLOSE;


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
	g = 1+x*lambda ;
  w = g#weight;

  a= w||g;

	CREATE weight FROM a; 
	APPEND FROM a; 
QUIT;


DATA results;
  MERGE from_reg weight(rename = (COL1 = wk COL2 = gk));
  res_gk = gk*residual_reg;
  KEEP residual_reg wk gk res_gk SamplingWeight;
RUN;


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



