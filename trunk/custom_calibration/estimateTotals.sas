
/* Estimate the the x-totals based on the weighting */

%macro estimateTotals(dat=, weight_var=, mod_dat=, out_lib=work, debug=) /store;
	%local max_i cont_terms term;
	
	%let max_i =;
	
	proc sql noprint;
		select max(mod_term_nb) into :max_i from &mod_dat;
	
	%let terms=;

	/* Can be more efficient when calculating the continuous totals in one pass, 
		TODO: problems with term identification and reordering... of the effects
		... or matching by name with the vector total... */
	
	%do i = 1 %to &max_i;
			
		select term into :terms separated by ',' from &mod_dat
		where discrete = 1 and mod_term_nb = &i;
		
		%put Doing &i: with &terms and &SQLOBS from &dat;
		%if &SQLOBS %then 
			%do;
				create table &out_lib..__est&i as
				select catx(':', &terms) as %qsysfunc(compress(%chsep(%quote(&terms),_,  %quote(,)))), sum(samplingWeight) as EST_COUNT
				from &dat
				group by &terms;
			%end;
		%else
			%do;
				select term into :cont_terms separated by ',' from &mod_dat
						where type = 2 and mod_term_nb = &i;
				
				%put Continuous terms: &cont_terms;
				
				%let cont_func_list = %encloseEach(%quote(&cont_terms), '(', '*samplingWeight)', %quote(,));
				%let cont_func_list = %quote(%encloseEach(&cont_func_list, sum, %quote( as ), %quote(,)));
				%let cont_func_list = %encloseEach(&cont_func_list,,%chsep(&cont_terms, %str( ), %quote(,)), 
																%quote(,));
				
				%put &cont_func_list;
				
				select term into :discr_terms separated by ',' from &mod_dat
				where type = 1 and mod_term_nb = &i;
				
			%if &SQLOBS %then
				%do;
					create table &out_lib..__est&i as
					select &discr_terms,
					&cont_func_list			
					from &dat
					group by &discr_terms;
				%end;
			%else
				%do;
					create table &out_lib..__est&i as
					select &cont_func_list
					from &dat;
				%end;
		%end;
	%end;
	quit;	
%mend estimateTotals;

/*

%estimateTotals(dat = vse6_srs, weight_var = samplingWeight, mod_dat = test_in_m);
*/
