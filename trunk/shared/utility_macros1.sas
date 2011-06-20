
/* Some utility macros */

%macro svyMacrosLib /store;
    %put;
    %put ********************************;
    %put ** Makro-Bibliothek (Advanced Survey Statistics), ist installiert: V 0.7**;
    %put ********************************;
    %put;
%mend svyMacrosLib;


%macro wc(string, delimiter) /store;
    %Local i;
    %let i = 0;

    %if %isBlank(&delimiter) eq 1 %then
        %do;
            %put "Delimiter not specified, using default single blank";
            %let delimiter = %str( );
        %end;

    %do %while( %qscan(&string, %eval(&i + 1), &delimiter) ne %str() );
        %let i = %eval(&i + 1);
    %end;
    &i
%mend wc;


%macro names(dset) /store;
    %local i nobs vlist tmp_name;

    %let fid = %sysfunc(open(&dset, i));

    %if &fid %then
        %do;
            %let nobs = %sysfunc(attrn(&fid, NVARS));
            %let vlist = %str();
            %let sep = %str( );

            %do i = 1 %to &nobs;
                %let tmp_name = %sysfunc(varname(&fid, &i));
                %let vlist =&vlist&sep&tmp_name;
                %put &i.: &tmp_name.: &vlist;
            %end;

            %if not %sysfunc(close(&fid)) %then
                %put Connection with &dset closed successfully;
            %else
                %put Error closing connection with &dset;
        %end;
    %else
        %put Error opening &dset;
    &vlist
%mend names;

%macro ncol(dset) /store;
    %local i nvar vlist tmp_name;

    %let fid = %sysfunc(open(&dset, i));

    %if &fid %then
        %do;
            %let nvar = %sysfunc(attrn(&fid, NVARS));
            %let vlist = %str();
            %let sep = %str( );

            %do i = 1 %to &nvar;
                %let tmp_name = %sysfunc(varname(&fid, &i));
                %let vlist =&vlist&sep&tmp_name;
            %end;

            %if not %sysfunc(close(&fid)) %then
                %put Connection with &dset closed successfully;
            %else
                %put Error closing connection with &dset;
        %end;
    %else
        %put Error opening &dset;
    &nvar
%mend ncol;


%macro nrow(dset) /store;
    %local i nrow vlist tmp_name;

	 
    %let fid = %sysfunc(open(&dset, i));

    %if &fid %then
        %do;
            %let nrow = %sysfunc(attrn(&fid, NOBS));
            %if not %sysfunc(close(&fid)) %then
                %put Connection with &dset closed successfully;
            %else
                %put Error closing connection with &dset;
        %end;
    %else
        %put Error opening &dset;
    &nrow
%mend nrow;


%macro drop(list, drop_list, delimiter) /store;
    %local i new_list tmp;
	
	 %if %isBlank(&delimiter)  eq 1 %then
	 	%do;
			%let delimiter = %str( );
		%end;
	 
	%let new_list = %str();

    %let i = 1;
    %let tmp = %qscan(&list, &i, &delimiter);
	 
    %do %while(&tmp ^= %str());
        %if %sysfunc(indexw(&drop_list, &tmp, &delimiter)) = 0 %then
        	%do;
				%put Element passed test: &tmp;
            	%let new_list = &new_list&delimiter&tmp;
            %end;
			
			%let i = %eval(&i + 1);
        	%let tmp = %qscan(&list,  &i, &delimiter);
    %end;
    %left(&new_list)
%mend drop;

/* Source all files in a directory... */

%macro include_dir(dir) ;

filename shared "&dir";

data _null_;
    dir_id = dopen();
    if dir_id then
        do;
            files_n = dnum(dir_id);

            do i = 1 to files_n;
                file_name = dread(dir_id, i);
                call execute('%include '||'"'||"&dir/"||trim( left( file_name))||'";');
            end;

            dclose(dir_id);
        end;
    else put "Error opening &sharedDir";
run;

filename shared;

%mend include_dir;


%macro chsep(list, to, from) /store;
    %local changed;
	 
    %if %isBlank(&from) eq 1 %then %let from = %str( );
    %if %isBlank(&to) eq 1 %then %let to = %str(,);

    %let changed = %qsysfunc(translate(%qcmpres(&list), &to, &from));
&changed
%mend chsep;


%macro isBlank(param) /store;
    %sysevalf(%superq(param)=,boolean)
%mend isBlank;


%macro mkdir(dir) /store;

    %if %sysfunc(fileexist(&dir)) ^= 1 %then %do;
        /*x "mkdir &dir";*/
        data _null_;
            call system("mkdir &dir");
        run;
    %end;
%mend mkdir;

%macro setPathToCurrent /store;
    %local cdir cFileName cFileBaseName n_cFileName n_pathName cPathName;

    %let cFileName = %sysget(sas_execfilepath);
    %let cFileBaseName = %qscan(&cFileName, -1, '\');
    %let n_cFileBaseName = %length(%quote(&cFileBaseName));
    %let n_cFileName = %length(%quote(&cFileName));
    %let n_pathName = %eval(&n_cFileName - &n_cFileBaseName - 1);
    %let cPathName = %qsubstr(&cFileName, 1, &n_pathName);

    data _null_;
        call system("cd &cPathName");
    run;
%mend setPathToCurrent;


/*************** Deprecated ********************/

%macro quotate_list(list=, double = 0, delimiter = %str( )) /store;	
	%local i list_length list_in_quotes;
	
	%let list_length = %wc(&list);
	%let list_in_quotes=%str();
	
	%do i = 1 %to &list_length;
		%let list_el = %qscan(&list, &i);
		%let list_in_quotes = &list_in_quotes&delimiter.%nrbquote('&list_el.');
	%end;

	&list_in_quotes
%mend quotate_list;



%macro qList(list, double, delimiter) /store;
	%local i list_length list_in_quotes;
	
	%if %isBlank(&double) eq 1 %then %let double = 0;;
	%if %isBlank(&delimiter) eq 1 %then %let delimiter = %str( );;
	
	%let list_length = %wc(&list, delimiter = &delimiter);
	%put list_length = &list_length;

	%let list_in_quotes=%str();
	
	%do i = 1 %to &list_length;
		
		%let list_el = %qscan(&list, &i, &delimiter);

		%put list_in_quotes = &list_in_quotes;
		%put list_el = &list_el;

		%let list_in_quotes = &list_in_quotes&delimiter.%str(%')&list_el%str(%');
	%end;

	&list_in_quotes
%mend qList;



%macro renameAll(lib, dat,pre, suff, except);
	%local i names_old old;

	%if %isBlank(&pre) = 1 %then %let pre = %str();
	%if %isBlank(&suff) = 1 %then %let suff = %str();

	%let names_old = %names(&lib..&dat);

	%if %isBlank(&except) ^= 1 %then %let names_old = %drop(&names_old, &except);
	
	%put &names_old;

	proc datasets library = &lib;
		modify &dat;
		rename
			%do i = 1 %to %wc(&names_old);
				%let old = %scan(&names_old, &i, %str( ));
				&old = &pre&old&suff
			%end;
		;
		run; quit;
	
%mend renameAll;
