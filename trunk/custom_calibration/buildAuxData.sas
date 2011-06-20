
*options mprint nomprintnest nosymbolgen;


%macro buildAuxDataFrame(mod_dat=, sframe=, weight_var=, out_lib=, aux_out_file=, debug=, type = CLAN) /store;
	%local cont_variables terms intercept;
	
	/*sasfile &mod_dat load;*/
	
	%let max_i =;
	
	proc sql noprint;
		select max(mod_term_nb) into :max_i from &mod_dat;
		
	%let terms=;
	%let intercept =%str();
	
	select term into :intercept
	from &mod_dat
	where mod_term_nb = 0;
	
	%if &SQLOBS	%then
		%do;
			
			create table &out_lib..__tab0 as
					%if %isBlank(&weight_var) = 1 %then 
						%do;
							select sum(1) as &intercept
						%end;
					%else
						%do;
							select sum(&weight_var) as &intercept
						%end;
					from &sframe;
		%end; 
	
	%do i = 1 %to &max_i;
		
		select term into :terms separated by ',' from &mod_dat
		where discrete = 1 and mod_term_nb = &i;
		
		%put Doing &i: with &terms and &SQLOBS from &mod_dat;
		%if &SQLOBS %then
			%do;
				create table &out_lib..__tab&i as
				
				%if %isBlank(&weight_var) = 1 %then
					%do;
						select catx(':', &terms) as %qsysfunc(compress(%chsep(%quote(&terms),_,  %quote(,)))), count(*) as COUNT
					%end;
				%else
					%do;
						select catx(':', &terms) as %qsysfunc(compress(%chsep(%quote(&terms),_,  %quote(,)))), sum(&weight_var) as COUNT
					%end;
				from &sframe
				group by &terms;
				/*
				create table &out_lib..__tab&i as 
					select &terms, count(*) as COUNT
					from &sframe
					group by &terms;
				*/
			%end;
		%else
			%do;
				select term into :cont_terms separated by ',' from &mod_dat
						where type = 2 and mod_term_nb = &i;
				
				%put Continuous terms: &cont_terms;
				
				%if %isBlank(&weight_var) = 0 %then
					%do;
						%let cont_func_list = %encloseEach(%quote(&cont_terms),, *&weight_var, %quote(,));
					%end;
				%else
					%do;
						%let cont_func_list = &cont_terms;
					%end;
				
				%let cont_func_list = %encloseEach(%quote(&cont_func_list), %str(%(), %str(%)), %quote(,));
				%let cont_func_list = %encloseEach(%quote(&cont_func_list), sum, %str( as ), %quote(,));
				%let cont_func_list = %encloseEach(%quote(&cont_func_list),, %quote(&cont_terms), %quote(,));
								
				select term into :discr_terms separated by ',' from &mod_dat
				where type = 1 and mod_term_nb = &i;
				
			%if &SQLOBS %then
				%do;
					create table &out_lib..__tab&i as
					select &discr_terms,
					&cont_func_list			
					from &sframe
					group by &discr_terms;
				%end;
			%else
				%do;
					create table &out_lib..__tab&i as
					select &cont_func_list
					from &sframe;
				%end;
		%end;
	%end;
	quit;	

	/* Check whether to include an intercept: with CLAN a Variable Intercept should be included in the sample data! */
		
	%put All tables created: &tabs;
	
	%let cont_variables =%str();

	
	%if &intercept = %str() %then
		%do;
			%let tabs = %encloseEach(%seq(1, &max_i), __tab);
		%end;
	%else
		%do;
			%let tabs = %encloseEach(%seq(0, &max_i), __tab);
		%end;
	
	proc sql noprint;
		select term into :cont_variables separated by ' '
		from &mod_dat
		where type = 2;
	quit;
	
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
%mend buildAuxDataFrame;


%macro buildAuxDataTable(aux_out_file=, population=, cont_vars=, out_lib=work,  margins_lib=, debug=,type=CLAN) /store;
	%local i tab mrgn_tab_n table_discr table_cont;
	
	%if %isBlank(&aux_out_file) eq 1 %then
		%do;
			%let aux_out_file = work.__AUX_IN;
		%end;
	
	%if %isBlank(&population) eq 1 %then
		%do;
			%put Pop Margins: &population;
			%put @@ ***** ERROR: buildAuxDataTable requires a list of tables as input! *****;
			%abort;
		%end;
	
	
	%if %isBlank(&margins_lib) eq 1 %then
			%do;
				%put @@***** No library specified for tables input *****;
			%end;
		%else
			%do;
				%put @@***** Using &margins_lib as input for all tables without explicit libref *****;
			%end;
		
	%let mrgn_tab_n = %wc(&population);
	
	%let max_mar_n = 1;
	
	%put @@ ***** &mrgn_tab_n tables read from population: &population *****;
	
	/* Check whether we are building CLAN or something else... */
	
	%do i = 1 %to &mrgn_tab_n;
		%let tab = %qscan(&population, &i, %str( ));
		%let table_cont=%str();
	
		/** Check if table exists... **/
		
		%if %sysfunc(exist(&tab)) = 0 %then	
			%do;
				%put Table &tab does not exist.., exiting!;
				%goto :cleanup;
			%end;
		
			
		/* Get the names of the margins... */
		%let table_names = %names(&tab);
		%put @@ ***** Table names: &table_names *****;
		
		%put @@ ***** &cont_vars, &table_names;
		
		%if %isBlank(&cont_vars) = 0 %then
			%do;
				%put Matching tables names with the list of continuous variables!;
				%let table_cont = %match(&table_names, &cont_vars);
			%end;
		
		%put Table_cont: &table_cont;

		
		%put @@ ***** Table continuous: &table_cont *****;
		
		%if &table_cont = 0 %then
			%do;
				%put @@ ***** Table cont is empty! *****;
				
				%let margin_names = %drop(%names(&tab), COUNT); 
				%let cells_n = %nrow(&tab);
				%put Names in &tab.: &margin_names with &cells_n cells; 
				
				/* This will not work with input with continuos variables... */
				
				proc transpose data = &tab 
									out = &out_lib..__tmp_tab&i(drop = _NAME_ _LABEL_)
									prefix = MAR;
					var COUNT;
				run;
				
				data &out_lib..__tmp_tab&i;
					retain Var n MAR1-MAR&cells_n xtype xdom;
					length Var $ 32. xdom $ 32.;
						
					set &out_lib..__tmp_tab&i;
					Var = "&margin_names";
					xtype = 'c';
					xdom = .;
					n = &cells_n;
				run;		
			%end;
		%else
			%do;
				%let discr_in_table = %drop(&table_names, &cont_vars);
				%put Discrete Variables in Table: &discr_in_table;
				%let cont_in_table = %drop(&table_names, &discr_in_table);
				%put Continuous Variables in Table: &cont_in_table;
				%let cells_n = %nrow(&tab);
				%put Cells in the table: &cells_n;
				
				/* Can only handle a single variable... as it stands.. */
				proc transpose data = &tab
						out = &out_lib..__tmp_tab&i(drop = _LABEL_ rename = (_NAME_ = Var))
						prefix = MAR;
					var &cont_in_table;
				run;
				
				/* The following will only work with one nested continuos... */
				
				data &out_lib..__tmp_tab&i;
					length Var $ 32. xdom $ 32.;					
					retain Var n MAR1-MAR&cells_n xtype xdom;
					set &out_lib..__tmp_tab&i;
					
					n = %if &cells_n > 1 %then %do; &cells_n %end; %else %do; 0 %end; ;
					xtype = 'n';
					%if &cells_n > 1 %then %do; xdom = "&discr_in_table" %end; 
					%else 
					%do; call missing(xdom) %end; ;
				run;
			%end;
		%end;
		
		data &aux_out_file;
			retain Var n xtype xdom;
			set &out_lib..__tmp_tab1-&out_lib..__tmp_tab&mrgn_tab_n;
		run;

	/* Transform the aux_out_file into a format suitable for surveyreg... */
	/*
	%if not %upcase(&type) = CLAN %then
		%do;
			proc transpose data = &aux_out_file(drop = xtype xdom n) out = &aux_out_file._REG;
				by Var;
			run;
			
			%stack(dat = &aux_out_file._REG, newdat = &aux_out_file._REG, stack_lst = MAR:);
		%end;
	*/

	%if %upcase(&type) ^= CLAN %then
		%do;
	
			data &aux_out_file;
				set &aux_out_file(drop = xtype xdom n);
				
				array __tmp__{*} MAR: ;
				
				i = 1;
				__dim_tmp = dim(__tmp__);
				do until(i > __dim_tmp);
					if not missing(__tmp__(i)) then 
						do;
							_TOTAL_ = __tmp__(i);
							i + 1;
							output;
						end;
					else leave;
				end;
				
				drop i __dim_tmp MAR:;
			run;
			
		%end;
	
	/* If debugging do not delete intermediate data */

	%cleanup:
	
	%if %isBlank(&debug) = 1 %then 
		%do;
			proc datasets library = &out_lib;
				delete __tmp_tab1-__tmp_tab&mrgn_tab_n;
			run; quit;
		%end;
%mend buildAuxDataTable;
