

/* GREGeri: Impement Generalized Regression Estimation using a model formula... 
	Erste Versuche fuer ein Kaligbrationsmakro
*/

%macro gregeri(formula=,
			   	design=,
					sample=,
					weight_var=,
					cal_weight_name=cal_weight,
			   	sframe=,
					aux_out_file=,
			   	pop_margins=,
			   	backend=CLAN,
			   	model_name=M,
			   	out_lib=work,
					debug=
				) /store;
	
	%local response covars n_terms class_terms model_descr dat_names i;
	
		/***** PARSE RESPONSE AND COVARIATES *****/
	
	%if %isBlank(&formula) eq 1 %then
		%do; 
			%put @@ ***** ERROR: Gregari needs a formula argument *****;
			%abort;
		%end;
	
	%if %isBlank(&pop_margins) eq 1 %then
		%do;
			%if %isBlank(&sframe) eq 1%then
				%do;
					%put @@ ***** ERROR: At least one of the arguments sframe or pop_margins needs to be specified!;
					%abort;
				%end;
			%put @@ ***** NOTE: No additional population margins specified, using the sampling frame only ****;
		%end;
	
	%if %isBlank(&design) eq 1 %then
		%do;
			%put @@ ***** GREGARI needs a design argument *****;
		%end;

	%if %isBlank(&aux_out_file) eq 1 %then
		%do;
			%let aux_out_file = work.&model_name;
			%put @@ ***** aux_out_file is not specified, results will be output in ;
		%end;

	%if %isBlank(&sample) eq 1 and %isBlank(%upcase(&backend) ^= CLAN) %then
		%do;
			%put @@ ***** Backend is not CLAN, but the sample data set is not specified. This will fail! *****;
			%goto cleanup;
		%end;

	/** SOME ERROR HANDLING ***/

	
	
	%put @@ ***** Running GREGARI using the %UPCASE(&backend) backend. *****;
	%put @@ ***** Results wil be output in: &out_lib, model prefix is: &model_name *****;

	
	/***** PARSE RESPONSE AND COVARIATES *****/
	
	%put @@ ***** Model formula: &formula *****;
	%let response = %qscan(&formula, 1, '~');
	%let covars   = %qscan(&formula, 2, '~');
	
	%put @@ ***** Model response: &response *****;
	%put @@ ***** Regressors: &covars *****;
	
	%if &covars = %str() %then
		%do;
			%let covars = &response;
			%let response = %str();
		%end;
	
	%put @@ ***** Response variable is: &response *****;
	%put @@ ***** Symbolic model description is: &covars *****;
	
	%put @@ ***** Response variable(s): &response *****;
	%put @@ ***** Explanatory variable(s): &covars *****;
	
	%put @@ ***** %wc(%quote(&covars), +);
	
	%parseModel(model = %quote(&covars), model_name = &model_name, out_file = &aux_out_file._&model_name,debug=&debug);
	
	%if %upcase(&backend) = CLAN %then
		%do;
			%buildAuxDataFrame(mod_dat=&aux_out_file._&model_name, sframe=&sframe, out_lib = &out_lib, 
							   aux_out_file=&aux_out_file, debug = &debug, type = &backend);
			%goto cleanup;
		%end;
	%else
		%do;
			%buildTotalsTable(mod_dat=&aux_out_file._&model_name, dat=&sframe, out_lib = &out_lib, 
									 aux_out_file=&aux_out_file, debug = &debug, type = &backend);
	 
			%buildTotalsTable(mod_dat=&aux_out_file._&model_name, dat=&sample, out_lib = &out_lib,
							  weight_var=&weight_var,
							  aux_out_file=&aux_out_file._est, debug = &debug,
							  des_out_file=__X__
							  );
			/* This naming convention for the design matrix has a potential conflicts!!*/
		%end;
	
	/* Run the regression */
	
	proc sql noprint;
		select distinct term into : class_terms separated by ' '
		from &aux_out_file._&model_name
		where type = 1;
		
		select distinct term_sas into : model_descr separated by ' '
		from &aux_out_file._&model_name;		
	quit;
	
	%put Class variables: &class_terms;
	%put Model description: &model_descr;
	
	ods listing close;
	
	proc surveyreg
		data = &sample
		;
		format _all_;
		class &class_terms;
		
		weight &weight_var;
		
		model &response = &model_descr /solution vadjust=none INVERSE ;
		
		ods output
			ParameterEstimates = __RegCoeff InvXPX = __RegXXinv;
	run;
	
	ods listing;
	
	/* Calculate the difference in totals: output from the buildAuxVar macro */
	
	%let des_m_names = %names(__X__);
	%let des_m_names = %drop(%upcase(&des_m_names), %upcase(&weight_var));
	
	proc iml; 
		use &aux_out_file;
		read all var {_TOTAL_} into poptotal;
		use &aux_out_file._est;
		read all var {_TOTAL_} into pi_estimate;

		use __RegXXinv;
		read all into XWXginv;
		
		correction = poptotal - pi_estimate;
		
		use __X__;
		read all var {&des_m_names} into X;
		
		read all var{&weight_var} into W_vec;
		*W = DIAG(W_vec);
		
		g = 1 + t(correction)* XWXginv*t(X);
		*g = 1 + t(correction)*inv(t(X)*W*X)*t(X);
		cal_w = t(g)#W_vec;
		
		create __cal_weight FROM cal_w; 
		append from cal_w; 	
	quit;
	
	/* Check whether we overwrite an existing variable!! */
	
	/**
	%let dat_names = %names(&sample);
	
	%let cal_weight_name_orig = &cal_weight_name;
	
	%let i = 0;
	
	%do %while(%match(&dat_names, &cal_weight_name) ^= %str());
		
		%let cal_weight_name_old = &cal_weight_name;
		%let cal_weight_name = &cal_weight_name_orig&i;
		
		%let i = %eval(&i + 1);
		
		%put @@ ***** &cal_weight_name_old will overwrite an existing variable in &sample, renaming to  &cal_weight_name ****;
	%end;
	
	%put @@ ***** Writing variable &cal_weight_name to &sample *****;

	**/

	data &sample;
		merge &sample __cal_weight(rename = (COL1 = &cal_weight_name));
	run;
	
	%cleanup:;
	
	%if %isBlank(&debug) = 1 %then
		%do;
			proc sql noprint;
				drop table &aux_out_file._&model_name;
			quit;
			
			proc datasets library = &out_lib;
				delete __tab: __tmp: __X__ __RegCoeff __RegXXinv __cal_weight;
			run; quit;
		%end;
	
%mend gregeri;
