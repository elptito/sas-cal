

/* GREGari: Impement Generalized Regression Estimation using a model formula... */

%macro parseModel(	model=,
			   			model_name=M,							
			   			out_file=,
							debug=
					) /store;
	
	%local response m_dat n_terms;
	
	%if %isBlank(&out_file) eq 1 %then
		%do;
			%let out_file = work.&model_name.__terms;
		%end;

	%put @@ ***** Model: &model *****;
	
	%let m_dat = &out_file;
	
	data &m_dat;
		retain i j term_orig term_sas term order type add_intercept;
		length term $ 32.;
		length term_sas $ 32.;
		
		cont_pattern = prxparse("/c\((.+)\)/i");
		cont_repl    = prxparse("s/c\((.+)\)/$1/i");
		add_intercept = 1;
		
		do i = 1 to %wc(&model, '+');
			term_orig = compress(resolve('%qscan(&model,'||i||', +)'));
			
			cont_match = prxmatch(cont_pattern, term);

			if term_orig = '0' then 
				do;
					add_intercept = 0;
					continue;
				end;
					
			term_sas = prxchange(cont_repl, -1, term_orig);
			order = count(term_orig, '*') + 1;
			
			j = 1;
			if order > 0 then
				do j = 1 to order;
					put "***** Processing interaction terms *****";
					term = scan(term_orig, j, '*');
					cont_match = prxmatch(cont_pattern, term);
					
					if not cont_match then
						do;
							type = 1;
							put "A discrete variable";
						end;
					else 
						do;
							call prxposn(cont_pattern, 1, start_var, length_var);
							term = substr(term, start_var, length_var);
							type = 2;
							put "A continuous variable";
						end;
					output;
				end;
			else
				do;
					term = term_orig;
					cont_match = prxmatch(cont_pattern, term);
					
					if not cont_match then
						type = 1;
					else 
						do;
							call prxposn(cont_pattern, 1, start_var, length_var);
							term = substr(term, start_var, length_var);
							type = 2;
						end;
					output;
				end;
		end;

		if add_intercept then
			do;
				put 'Adding an intercept: when using clan a variable with the name _Intercept_ must be included in the data set!';
				term = '_Intercept_';
				term_orig = '_Intercept_';
				call missing(term_sas);
				type = 2;
				discrete = 0;
				i = 0;
				j = 0;
				order = 1;
				output;
			end;
		

		call symput('n_terms', compress(i));
		drop start_var length_var cont_pattern cont_match add_intercept;
		rename i = mod_term_nb j = int_term_nb;
	run;
	
	%put @@ ***** Number of model terms: &n_terms *****;
	
	/** Maybe redundant **/
	proc sort data = &m_dat; by mod_term_nb int_term_nb type; run;
	
	proc sql noprint;
		
		create table &m_dat as
			select mod_term_nb, int_term_nb, term, term_orig, term_sas, type,
					 (max(type) = 1) as discrete
			from &m_dat
			group by mod_term_nb
		;
	quit;
	
	
	%if %isBlank(&debug) = 1 %then
		%do;
			proc datasets library = &out_lib;
				delete __M_terms_;
			run; quit;
		%end;	
%mend parseModel;
