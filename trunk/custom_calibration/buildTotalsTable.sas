
/* Build aux data from a design matrix */

%macro buildTotalsTable(mod_dat=, dat=, weight_var=, out_lib=work, aux_out_file=, 
						des_out_file=, debug=, type = CLAN) /store;
	%local cont_variables terms fid noint;
	
	proc sql noprint;
		select distinct term into : class_terms separated by ' '
		from &mod_dat
		where type = 1;
				
		select distinct term_sas into : model_descr separated by ' '
		from &mod_dat;
		
		/*** Check whether to suppress the intercept when creating the design matrix ***/
		
		select 'NOINT' 
		from &mod_dat
		where mod_term_nb = 0;
		
		%if &SQLOBS %then %let noint = %str();
		%else %let noint = NOINT;
	quit;
	
	%let fid = %sysfunc(open(&dat, i));
	
	%if &fid > 0 %then
		%let response = %sysfunc(varname(&fid, 1));
	%else
		%do;
			%put @@ ***** ERROR opening &dat, aborting! *****;
			%abort;
		%end;

	%if %isBlank(&des_out_file) = 1 %then
		%do;
			%put @@ ***** Will drop the design matrix upon exiting *****;
			%let des = __X__;
		%end;
	%else
		%do;
			%let des = &des_out_file;
		%end;

	%if %sysfunc(close(&fid)) = 0 %then %put Connection with &dat closed!;
	%else 
		%do;
			%put @@ ***** ERROR when closing connection with &dat, aborting! *****;
			%abort; 
		%end;
	

	proc logistic data = &dat outdesign = &des(drop = &response) outdesignonly noprint;
		format _all_;
		class &class_terms / param = glm order = internal;
		/** param = reference ref = last order = internal ; **/
		
		/**
		class &class_terms / param = glm;
		**/
		model &response = &model_descr /  &noint;
	run;

	%if %isBlank(&weight_var) = 0 %then
		%do;
			data &des;
				merge &des
						&dat(keep = &weight_var)
				;
			run;

			proc means noprint
				data = &des
				;
				weight &weight_var;
				output
					out = &aux_out_file(drop = _FREQ_ _TYPE_) sum=
					;
			run;
		%end;
	%else
		%do;
			proc means noprint
				data = &des
				;
				output
					out = &aux_out_file(drop = _FREQ_ _TYPE_) sum=
					;
			run;
		%end;

	proc transpose data = &aux_out_file out = &aux_out_file(rename = (COL1 = _TOTAL_));
	run;

	/** Cleanup **/
	
	%cleanup:
	%if %isBlank(&des_out_file) = 1 %then
		%do; 
			proc sql noprint;
				drop table &des;
			quit;
		%end; 
	/**
	%put @@ ***** With continuous variables: &cont_variables *****;
	
	%if &cont_variables = %str() %then
		%do;
			%put No conttinuos variables in the call to buildAuxDataTable; 
			%buildAuxDataTable(aux_out_file = &aux_out_file, population=&tabs, 
									 out_lib = &out_lib, margins_lib=, type=&type); 
		%end;
	%else 
		%do;
			%buildAuxDataTable(aux_out_file = &aux_out_file, population=&tabs, 
									 cont_vars = &cont_variables, margins_lib=, debug=&debug, type=&type,
									 out_lib = &out_lib); 
		%end;
	**/
%mend buildTotalsTable;
