PROC IMPORT OUT= uk.test 
            DATAFILE= "&dataDir\UK\UKDA-5897-s
tata8\stata8\xs04_matched_mqseq_teaching_dataset.dta" 
            DBMS=DTA REPLACE;

RUN;
