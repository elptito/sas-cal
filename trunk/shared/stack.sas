

%macro stack(dat=, var_lst=, stack_regxp=, stacked_varname = _stack_, source_name = _source_col_, newdat=) /store;
	%local fid vname vnum lst_n vname_lgth vlgth max_vname_lgth max_lgth i j;
	
	 /* Determine the lenght of the source variable */

	%let lst_n = %wc(&var_lst);
	%let fid = %sysfunc(open(&dat, i));

	%let max_vlgth=0;
	%let max_vname_lgth=0;
	
	%if &fid = 0 %then
		%do;
			%put @@ ***** Cannot open connection to &dat, aborting *****; %abort;
		%end;
	
	%let j = 1;
	
	%if %sysfunc(index(&var_lst, :)) %then
		%do;
			%put Wildcards not yet implemented, aborting!;
			%abort;
		%end;	
	
	%do i = 1 %to &lst_n;
		%let vname = %qscan(&var_lst, &i, %str( ));
		%let vnum = %sysfunc(varnum(&fid, &vname));

		%put Variable name and number: &vname &vnum;
		
		%let vname_lgth = %sysfunc(lengthn(&vname));		
		%let vlgth = %sysfunc(varlen(&fid, &vnum));
		
		%put Variable name variable length: &vname_lgth &vlgth;
		
		%if &vlgth > &max_vlgth %then %let max_vlgth = &vlgth;
		%if &vname_lgth > &max_vname_lgth %then %let max_vname_lgth = &vname_lgth;
	%end;
	
	%if not %sysfunc(close(&fid)) %then %put Closing connection with &dat;

	%put Max varname length is: &max_vname_lgth;
	%put Max length is: &max_vlgth;
	
	data &newdat;
		set &dat;
		length &stacked_varname &max_vlgth;
		length &source_name $ &max_vname_lgth;
		
		array __tmp__{*} &var_lst;
			do __i__ = 1 to dim(__tmp__);
				&stacked_varname = __tmp__(__i__);
				&source_name = vname(__tmp__(__i__));
				output;
			end;
		
		drop __i__ &var_lst;
	run;
%mend;
