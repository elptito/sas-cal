%LET datafile = C:\temp\MU284.xls;


* import testdata;

PROC IMPORT DATAFILE = "&datafile"
            OUT      = testdata
            DBMS     = EXCEL2000
            REPLACE;

            GETNAMES = YES; 
RUN;


* sort;

PROC SORT DATA = testdata;
    BY REG CL;
RUN;


* select a simple random sample;

PROC SURVEYSELECT DATA     = testdata
                  OUT      = sample
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = 32;
RUN; 

/*
* function to be estimated (TOTAL);

%MACRO function(row,col);
    
    %tot(total,REV84,1);
    %estim(total);

%MEND;
*/

/*
* function to be estimated (MEAN);

%MACRO function(row,col);
    
    %tot(total,REV84,1);
    %tot(n,1,1);
    %div(mean,total,n);

    %estim(total);
    %estim(n);
    %estim(mean);

%MEND;
*/

/*
* function to be estimated (RATIO);

%MACRO function(row,col);
    
    %tot(total1,REV84,1);
    %tot(total2,P75,1);
    %div(ratio,total1,total2);

    %estim(total1);
    %estim(total2);
    %estim(ratio);

%MEND;
*/

* Domain Estimation / IF;

%MACRO function(row,col);
    
    %tot(total,REV84,reg=&row);

    %tot(n,1,reg=&row);
    %div(mean,total,n);

    %tot(all,REV84,1);
    %div(perc,total,all);

    %estim(total);
    %estim(n);
    %estim(mean);

    %estim(all);
    %estim(perc);

%MEND;


/*
* Domain Estimation, summing domains;
* -> (post stratified ratio estimator);

%MACRO function(row,col);
    
    %tot(total,REV84,reg=&row);
    %tabsum(table=total,frow=1-4 8,trow=9);

    %estim(total,sum);

%MEND;
*/




* simple clan call to estimate the HT-Estimator;

%CLAN(  DATA     = sample, 
        SAMPUNIT = E,           
        NPOP     = Total, 
        NRESP    = SampleSize, 
        MAXROW   = 9, 
        MAXCOL   = 1
      );

* Note: p<name> in DUT point estimator;
*       s<name> in DUT estimated standard error;


* clean work;

PROC DATASETS;
    DELETE _ds0;
    CHANGE DUT = EST_SRS;
QUIT;


* select a stratified simple random sample;

PROC SURVEYSELECT DATA     = testdata
                  OUT      = sample
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = (3 5 4 4 6 5 2 3);

                  STRATA REG;
RUN; 


* simple clan call to estimate the HT-Estimator;

%CLAN(  DATA     = sample, 
        SAMPUNIT = E,           
        NPOP     = Total, 
        NRESP    = SampleSize, 
        STRATID  = REG,
        MAXROW   = 8, 
        MAXCOL   = 1
      );

* clean work;

PROC DATASETS;
    DELETE _ds0;
    CHANGE DUT = EST_STSRS;
QUIT;


* dataset of clusters;

PROC SQL;
    CREATE TABLE clusters AS
    SELECT DISTINCT REG,CL FROM testdata;
    SELECT REG,N(CL) AS N_Clusters FROM clusters GROUP BY REG;
QUIT; 


* select a stratified simple random sample of clusters;

PROC SURVEYSELECT DATA     = clusters
                  OUT      = sample
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = 2;

                  STRATA REG;
RUN; 

PROC SQL UNDO_POLICY = NONE;

    CREATE TABLE sample AS
    SELECT * FROM testdata,sample
    WHERE testdata.reg = sample.reg AND
          testdata.cl  = sample.cl; 

QUIT;

* simple clan call to estimate the HT-Estimator;

%CLAN(  DATA     = sample, 
        SAMPUNIT = C,           
        NPOP     = Total, 
        NRESP    = SampleSize, 
        STRATID  = REG,
        CLUSTID  = CL,
        MAXROW   = 8, 
        MAXCOL   = 1
      );

* clean work;

PROC DATASETS;
    DELETE _ds0;
    CHANGE DUT = EST_STSRCS;
QUIT;



* RHG;

PROC SURVEYSELECT DATA     = testdata
                  OUT      = sample1
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = 71;
RUN; 


* RHGroups;

DATA sample1;

    SET sample1;
    rhg = 1 + (P75>9) + (P75>15) + (P75>29);

RUN;


PROC SQL UNDO_POLICY=NONE;

    CREATE TABLE temp AS
    SELECT rhg,N(rhg) AS NSAMP FROM sample1 GROUP BY rhg;

    CREATE TABLE sample1 AS
    SELECT sample1.*,temp.NSAMP FROM sample1,temp
    WHERE sample1.rhg = temp.rhg;

QUIT;


DATA sample2;

    SET sample1;
    U01 = RANUNI(0);

    IF U01<0.3 AND rhg=1 THEN DELETE;
    IF U01<0.2 AND rhg=2 THEN DELETE;
    IF U01<0.1 AND rhg=3 THEN DELETE;
    IF U01<0.25 AND rhg=4 THEN DELETE;

    DROP U01;

RUN;

PROC SQL UNDO_POLICY=NONE;

    CREATE TABLE temp AS
    SELECT rhg,N(rhg) AS NRESP FROM sample2 GROUP BY rhg;

    CREATE TABLE sample2 AS
    SELECT sample2.*,temp.NRESP FROM sample2,temp
    WHERE sample2.rhg = temp.rhg;

QUIT;


* RHG call;

%CLAN(  DATA     = sample2, 
        SAMPUNIT = E,           
        NPOP     = Total, 
        NRESP    = nresp, 
        MAXROW   = 1, 
        MAXCOL   = 1,

        RHG      = YES,
        GROUPID  = rhg,
        NGROUP   = nsamp,
        NSAMP    = SampleSize
      );


* GREG;

* select a simple random sample;

PROC SURVEYSELECT DATA     = testdata
                  OUT      = sample
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = 32;
RUN; 


PROC SQL;
    CREATE TABLE metadata AS
    SELECT SUM(S82) AS MAR1
    FROM testdata;
QUIT;

DATA metadata;
    SET metadata;

    VAR   = 'S82';
    N     = 0;
   *XTYPE = .;
RUN;


%MACRO function(row,col);

    %auxvar( DATAX    = metadata, 
             DATAWKUT = sample,
             WKOUT    = gweight, 
             IDENT    = label);

    %greg(greg_total,SS82,&row=1);
    %estim(greg_total);

    %tot(ht_total,SS82,&row=2);
    %estim(ht_total);

%MEND;

* simple clan call to estimate the GREG;

%CLAN(  DATA     = sample, 
        SAMPUNIT = E,           
        NPOP     = Total, 
        NRESP    = SampleSize, 
        MAXROW   = 2, 
        MAXCOL   = 1
      );

PROC SQL;
    SELECT SUM(S82*gweight) AS totalS82
    FROM sample;
QUIT;

PROC SQL;
    SELECT SUM(SS82) AS totalSS82
    FROM testdata;
QUIT;
