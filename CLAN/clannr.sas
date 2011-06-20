%LET datafile = C:\temp\soep.csv;

PROC IMPORT DATAFILE = "&datafile"
            OUT      = soepdata
            DBMS     = CSV
            REPLACE;

            GETNAMES = YES; 
         
RUN;

PROC SORT DATA = soepdata;
    BY bl psu96;
RUN;

DATA soepdata;
    SET soepdata;
    sex = male+1;
RUN;


* Strata: Bundesland, Cluster: PSU96;

PROC SQL;
    CREATE TABLE clusters AS
    SELECT DISTINCT bl,psu96 FROM soepdata;
    SELECT bl,N(psu96) AS N_Clusters FROM clusters GROUP BY bl;
QUIT; 

* select a stratified simple random sample of clusters;

PROC SURVEYSELECT DATA     = clusters
                  OUT      = sample
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = (3 5 8 3 4 5 10 2 2 2 2 2 3);

                  STRATA bl;
RUN; 

* Select the elements from the population;

PROC SQL UNDO_POLICY = NONE;

    CREATE TABLE sample AS
    SELECT * FROM soepdata,sample
    WHERE soepdata.bl = sample.bl AND
          soepdata.psu96  = sample.psu96; 

QUIT;

* create population sizes;

PROC SQL;
    CREATE TABLE temp AS
    SELECT N(agecl96) as agecl96
    FROM soepdata
    GROUP BY agecl96;
QUIT;

PROC TRANSPOSE DATA = temp OUT = metadata (RENAME=(COL1-COL8=MAR1-MAR8 _NAME_=VAR));
RUN;

PROC SQL;
    CREATE TABLE temp AS
    SELECT N(sex) as sex
    FROM soepdata
    GROUP BY sex;
QUIT;


PROC TRANSPOSE DATA = temp OUT = temp(RENAME=(COL1-COL2=MAR1-MAR2 _NAME_=VAR));
RUN;

DATA metadata;
    SET metadata (IN = ina)
        temp (IN = inb);
    IF ina THEN N = 8;
    IF inb THEN N = 2;
RUN;



%MACRO function(row,col);

    %auxvar( DATAX    = metadata, 
             DATAWKUT = sample);

    %greg(greg_total,1,merwerb=&row AND perwerb=&col);
    %estim(greg_total);

    %tot(ht_total,1,merwerb=&row AND perwerb=&col);
    %estim(ht_total);

%MEND;

%MACRO function(row,col);

    %auxvar( DATAX    = metadata, 
             DATAWKUT = sample);

    %greg(nab,1,merwerb=&row AND perwerb=&col);
    *%tabsum(table=nab, fcol=1-3, tcol=4);
    %greg(nb,1, merwerb=&row);
    %div(rab,nab,nb);

    *%estim(nab);
    *%estim(nb);
    %estim(rab);

%MEND;

%CLAN(  DATA     = sample, 
        SAMPUNIT = C,           
        NPOP     = Total, 
        NRESP    = SampleSize,
        STRATID  = bl,
        CLUSTID  = psu96, 
        MAXROW   = 3, 
        MAXCOL   = 4
      );


PROC SURVEYSELECT DATA     = soepdata
                  OUT      = sample
                  STATS
                  OUTSIZE
                  METHOD   = SRS
                  SAMPSIZE = 100;

                  STRATA bl;
RUN; 

%CLAN(  DATA     = sample, 
        SAMPUNIT = E,           
        NPOP     = Total, 
        STRATID  = bl,
        CLUSTID  = psu96, 
        MAXROW   = 3, 
        MAXCOL   = 4,

        NSAMP    = SampleSize,

        CNR      = YES,
        RTOU     = YES,
        SET      = S,
        RESPONSE = R9699=1
      );

%CLAN(  DATA     = sample, 
        SAMPUNIT = E,           
        NPOP     = Total, 
        NRESP    = SampleSize,
        STRATID  = bl,
        CLUSTID  = psu96, 
        MAXROW   = 3, 
        MAXCOL   = 4
      );
