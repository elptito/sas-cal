/*********************
  Date:
  Author: BA
  Descr: Tests
**********************/

options mprint;

%gregeri(formula = earnings ~ gender_cohort + marital_status, sframe = universe, sample = sample, model_name = TESTALTER, backend = DRANDRAN, debug = 1,
          weight_var = SamplingWeight)


proc contents data = sashelp.vcolumn; run;

proc sql;
  create view test_content as
  select * 
  from sashelp.vcolumn
  where libname eq 'WORK' and memname eq 'SAMPLE' and type eq 'num' and name not in ();
quit;
