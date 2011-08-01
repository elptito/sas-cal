options mprint symbolgen;
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




/*****************************************SIMULATION********************************************/
/*Eine Simulation von Macro Gregar*/
/*In dem Programm wird macro gregar simuliert und die Ergebnisse werden in Boxplot dargestellt*/

%let B = 30; /*Anzahl Simulationen*/
proc surveyselect data=universe noprint
                  out=sample_sim	 
                  method=SRS
                  sampsize=430
                  seed = 5635
                  rep = &B
                  stats ;         *stats generates weights;
   
run;

/*TOTALS für Macro Gregar*/
ODS LISTING CLOSE;
ods output onewayfreqs=totals_sim ;
proc freq data=universe;
  table  gender cohort;
run;
ods output close;
ODS LISTING;


data totals_sim;
  set totals_sim;
  x_ID= coalesce(gender ,cohort);
  parameter= CATX('',SCAN(table,2), x_ID);
  keep frequency parameter x_ID;
run;



/*Hilfs Macro Repeat für durchführung von Simulation*/
 %macro repeat(data = , rep =, result_data_set = );
 %local i;

  %do i = 1 %to &rep;
    
      DATA __sample__;
          SET &data(where = (Replicate eq &i));
      RUN;
     
     %gregar(sample = __sample__                        /*Stichprobe*/
            ,y = earnings                               /*y-Variable*/
            ,X =  gender cohort                         /*x-variablen*/
            ,sampling_weight = SamplingWeight           /*Spalte Gewichte*/
            ,totals = totals_sim                        /*Datensatz mit Totals*/
            ,class = gender cohort                      /*Auflistung von diskrete Varibalen*/
            ,replicate_method = jackknife
            )
    
    %if &i = 1 %then %do;
      data &result_data_set;
         set results;
      run;
    %end;
    %else %do;
      proc append base = &result_data_set 
                  data = results; 
      run;
    %end;

  %end;
 %mend repeat;


/*Aufruf von macro repeat*/
%repeat(data= sample_sim
       ,rep=&B
       ,result_data_set = res
       );


/*Berechnungen von Variablen für Boxplot: MEAN und VARIANZ*/

/******************MEAN**********************/
/*proc means*/

/*calibrirte mean*/
ODS LISTING CLOSE;
ODS OUTPUT statistics=mean;
  PROC SURVEYMEANS DATA=res MEAN;
    VAR earnings;
    WEIGHT wk;
    BY Replicate;
  RUN;
ODS OUTPUT CLOSE;
ODS LISTING;

/*pi-schätzer mean*/
ODS LISTING CLOSE;
ODS OUTPUT summary=mean_pi;
    PROC MEANS DATA=res mean;
    VAR earnings;
    weight samplingweight;
    BY Replicate;
  RUN;
ODS OUTPUT CLOSE;
ODS LISTING;


/*datas mean, daraus wird ein Datensatz für Boxplot erzeugt*/
data  mean_sim;
  set mean;
  idx = "cal_mean";
  KEEP Mean idx ;
run;


data  mean_pi_sim;
  set mean_pi (rename = (earnings_Mean =mean));
  idx = "pi_mean";
  KEEP Mean idx ;
run;


/*Data für Boxplot*/
data for_boxplot;
  set Mean_sim mean_pi_sim;
run;


/*Berechnung des wahres Wertes*/
proc sql;
  create table earnings_pop_mean as
  select mean(earnings) as _ref_
  from universe
  ;
quit;


/*boxplot mean*/
proc boxplot data= for_boxplot;
  plot mean*idx / vref = earnings_pop_mean;
run;



/*******************VAR**********************/
/*proc surveymeans*/
/*calibrirte standard fehler*/
ODS LISTING CLOSE;
ODS OUTPUT statistics=var;
  PROC SURVEYMEANS DATA=res MEAN var;
    VAR earnings;
    WEIGHT wk;
    BY Replicate;
  RUN;
ODS OUTPUT CLOSE;
ODS LISTING;

/*jackknife standard fehler*/
ODS LISTING CLOSE;
ODS OUTPUT statistics=var_jk;
    PROC SURVEYMEANS DATA=res mean var;
    VAR earnings;
    REPWEIGHT RepWt_:;
    BY Replicate;
  RUN;
ODS OUTPUT CLOSE;
ODS LISTING;



/*datas std, daraus wird ein Datensatz für Boxplot erzeugt*/
data var_sim;
  set var;
  idx = "cal_var_mean";
run;


data  var_jk_sim;
  set var_jk;
  idx = "jk_var_mean";
run;


/*Data für Boxplot*/
data for_boxplot2;
  set var_sim var_jk_sim;
run;


/*Berechnung des wahres Wertes*/
proc sql;
  create table earnings_sim_mean_var as
  select var(mean) as _ref_
  from mean_sim
  ;
quit;



/*boxplot std*/
proc boxplot data= for_boxplot2;
  plot var*idx / vref = earnings_sim_mean_var;
run;



/*
PROC DATASETS LIBRARY = work;
    DELETE res results;
  RUN;
QUIT;
*/

