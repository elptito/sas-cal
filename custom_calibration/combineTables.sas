
%macro combineTables(tables_lst, out_file=, cont_vars=, debug=0,type=CLAN) /store;
	%local i tab mrgn_tab_n table_dscr table_cont;
		
	%if %isBlank(&out_file) eq 1 %then 
		%do;
			%let out_file = work.__AUX_IN; 
		%end;
	
	%if %isBlank(&tables_lst) eq 1 %then 
		%do;
			%put List of tables: &tables_lst;
			%put @@ ***** ERROR: buildAuxDataTable requires a list of tables as input! *****; 
			%abort; 
		%end;
	
	%let mrgn_tab_n = %wc(&tables_lst);
	%let max_mar_n = 1;
	
	%put @@ ***** &mrgn_tab_n tables read from tables_lst: &tables_lst *****;
	
	/* Create a skeleton data set for use with proc append later... */
	
	proc sql;
		create table &out_file (term char(32), COUNT num);
	quit;
	
	
	%do i = 1 %to &mrgn_tab_n; /** Iterate over the list of tables **/
		
		%let tab = %scan(&tables_lst, &i, %str( ));
			
		%if %sysfunc(exist(&tab)) = 0 %then	/** If the dataset does not exist, clean up and exit **/
			%do;
				%put Table &tab does not exist.., exiting!;
				%goto cleanup;
			%end;
		
		/* Get the names of the margins... */
		%let table_names = %upcase(%names(&tab));
		%let table_cont=%str();
		
				
		%if %isBlank(&cont_vars) = 0 %then
			%do;
				%put Checking table names with the list of continuous variables...;
				
				%let table_cont = %unquote(%match(&table_names, %upcase(&cont_vars)));
				%let table_cont_n = %wc(&table_cont);
				%let table_dscr = %drop(&table_names, &table_cont COUNT);
				%let table_dscr_n = %wc(&table_dscr);
			%end;
		%else
			%do;
				%let table_dscr = %drop(&table_names, COUNT);
				%let table_dscr_n = %wc(&table_dscr);
			%end;
		
		%let table_dscr = %unquote(&table_dscr);
		%let table_dscr_s = %unquote(%encloseEach(&table_dscr,,_s));
		
		%put @@ ***** Table names: &table_names *****;
		%put @@ ***** Continuos variables: &table_cont *****;
		%put @@ ***** Discrete Variables: &table_dscr, Length: &table_dscr_n *****;
		
		%if &table_dscr_n = 0 %then /* Case with cont. variables only... TODO: reorder the conditions... */
			%do; 
				proc transpose data = &tab out = __RED_&tab(rename = (_NAME_ = term COL1 = COUNT)); run;				
				proc append base = &out_file data = __RED_&tab;	run;
			%end; 
		%else /* Case with at least one discrete variable */	
			%do;
						
				%put Table &tab with discrete variables: &table_dscr, &table_dscr_n;
				
				%if &table_cont > 0 %then
					%do;
						%put @@ ***** Stacking dataset *****;
						
						%stack(dat = &tab, var_lst= &table_cont , stacked_varname = COUNT, 
							   source_name = __cont_vname, newdat = __RED_&tab);
						
						data __RED_&tab;
							length term $32.;
							length &table_dscr_s $32.; /* The var list must be ordered according to the model.. */ 
							
							set __RED_&tab;
							
							array __dscrn{&table_dscr_n} &table_dscr;
							array __dscrns{&table_dscr_n} $ &table_dscr_s; 
							
							do i = 1 to &table_dscr_n; 
								__dscrns(i) = cats(vname(__dscrn(i)), __dscrn(i)); 
							end;
							
							term = cats(%chsep(&table_dscr_s), __cont_vname); 
							
							/* Remove the unneccessary variables. Will issue a warning if __cont_vname is not found. */
							
							drop i &table_dscr &table_dscr_s __cont_vname; 
						run;
					
						proc append base = &out_file data = __RED_&tab; run;
					%end; 
				%else
					%do;
				/* TODO: Reorder the table according to the model information... */
						
						data __RED_&tab;
							length term $32.;
							length &table_dscr_s $32.; /* The var list must be ordered according to the model.. */ 
							
							set &tab;
							
							array __dscrn{&table_dscr_n} &table_dscr;
							array __dscrns{&table_dscr_n} $ &table_dscr_s; 
							
							do i = 1 to &table_dscr_n; 
								__dscrns(i) = cats(vname(__dscrn(i)), __dscrn(i)); 
							end;
							
							term = cats(%chsep(&table_dscr_s)); 
							
							/* Remove the unneccessary variables. Will issue a warning if __cont_vname is not found. */
							
							drop i &table_dscr &table_dscr_s; 
						run;

						proc append base = &out_file data = __RED_&tab; run; 
					%end; 
			%end; 
	%end;
	/* If debugging do not delete intermediate data */
		
	%cleanup:

	%if &debug = 0 %then 
		%do;
			proc datasets library = &out_lib;
				delete __RED:;
			run; quit;
		%end;
%mend combineTables;
