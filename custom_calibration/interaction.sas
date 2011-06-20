
%macro interaction(var_lst=, newvar=, dat=, newdat=, fmtname=, fmtlib=work, type = clan) /store ;
	%local var_sql_lst var_fmt nofmt var_fmt_tmp var_type var_type_tmp putfmt puttype ;
	
	%if %isBlank(&var_lst) eq 1 %then
		%do;
			%put @@ ***** No variables are specified. This will fail! *****;
			%abort;
		%end;

		%if %isBlank(&newvar) eq 1 %then
			%do;
				%let newvar = %unquote(%chsep(&var_lst, %quote(_), %str( )));
				%put @@ ***** No output variable specified. The result will be output in &newvar *****;
			%end;

		%let nofmt = 0;

		%if %isBlank(&fmtname) eq 1 %then
			%do;
				%let nofmt = 1;
				%let fmtname = &newvar.F;
				%put @@ ***** No format name specified, using &fmtname *****;
			%end;
		
		%if %isBlank(&newdat) eq 1 %then
			%do;
				%let newdat = &dat;
				%put @@ ***** Writing into the existing dataset! May cause inconsistencies! *****;
			%end;
				
			* %encloseEach(%quote(%chsep(&var_lst)), distinct,,%quote(,));
			%let var_sql_lst = %chsep(&var_lst);
	
		/* Need to get the formats of the variables... */
		
		%let fid = %sysfunc(open(&dat));
		%if &fid = 0 %then 
			%do;
				%put ERROR opening &dat: %qsysfunc(sysmsg());
				%abort;
			%end;
		
		%let var_fmt=;
		%let var_type=;

		%let var_length = %wc(&var_lst);
		
		%do i = 1 %to &var_length;
			%let var_name = %qscan(&var_lst, &i);
			%put Variable name: @@&var_name@@;
			%let var_num = %sysfunc(varnum(&fid, &var_name));

			%let var_type_tmp = %sysfunc(vartype(&fid, &var_num));
			%let var_type=&var_type%str( )&var_type_tmp;
			%let var_fmt_tmp = %sysfunc(varfmt(&fid, &var_num));
			
			%if &var_type_tmp = N and &var_fmt_tmp = %str() %then
				%do;
					%let var_fmt_tmp = BEST12.;
				%end;

			%put @@&var_fmt_tmp.@@;
			%let var_fmt=&var_fmt%str( )&var_fmt_tmp;
			%put Variable format: &var_fmt;
		%end;
		
		%put Closing connection &fid: %sysfunc(close(&fid));
				
		proc sql;
			create table __lookup as
				select distinct &var_sql_lst
				from &dat
				order by &var_sql_lst
			;
			create table __lookup as
				select *, catx(":"
					%do i = 1 %to &var_length;
						%let putfmt = %qscan(&var_fmt, &i, %str( ));
						%let puttype = %qscan(&var_type, &i, %str( ));
						
						%if &puttype = C and &putfmt = %str() %then
							%do;
								,%qscan(&var_lst, &i)
							%end;
						%else
							%do;
								,put(%qscan(&var_lst, &i),  &putfmt)
							%end;
					%end;
				) as &newVar.c,
				MONOTONIC() as &newvar, "&fmtname" as fmtname
				from __lookup;
		quit;
		
		%if &nofmt = 0 %then
			%do;
				proc format cntlin = __lookup(rename = (&newvar = start &newVar.c = label)) 
							library = &fmtlib; run;
			%end;

		data &newdat;
			declare AssociativeArray ht();
			
			rc = ht.DefineKey( %unquote(%chsep(%quotate_list(&var_lst))));
			/*rc = ht.DefineData(%unquote(%nrbquote('&newvar')));*/
			rc = ht.DefineData("&newvar");
			rc = ht.DefineDone();
			
			do until(eof_lookup);
				set __lookup(keep = &var_lst &newvar) end = eof_lookup;
				rc = ht.add();
			end;
			
			do until(eof_main);
				set &dat end = eof_main;
				rc = ht.find();
				if rc = 0 then output;
			end;
			
			drop rc;
			stop;
			%if &nofmt = 0 %then
				%do;
					format &newvar &fmtname..;
				%end;
		run;
%mend interaction; 

/** Testing

options mprint mprintnest;
%interaction(var_lst= wzgruppe ef10, newvar = test, dat=vse6, newdat = test);

**/
