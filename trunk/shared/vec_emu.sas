

%macro isin(x, list, delimiter) /store;
    %local tmp i contains;
	
	 %if %isBlank(&x) eq 1 or %isBlank(&list) eq 1 %then
	 	%do;
			%put @@***** Arguments x and list must be specified!;
			%abort;
		%end;

	%if %isBlank(&delimiter) eq 1 %then
		%do;
			%let delimiter = %str( );
		%end;
	
    %let contains = 0;
    
	%let i = 1;
    %let tmp = %qscan(&list, &i, &delimiter);

    %do %while(&tmp ne %str());
		%if &tmp = &x %then
			%do;
				%let contains = 1;
				%goto exit;
			%end;
		%else
			%do;
	        %let i = %eval(&i + 1);
   	     %let tmp = %qscan(&list, &i, &delimiter);
			%end;
    %end;
	 %exit:
    &contains
%mend isin;


%macro all(x, value, delimiter) /store;
	%local i el_x all_eq;
	
	%if %isBlank(&x) eq 1 or %isBlank(&value) eq 1 %then
		%do;
			%put @@***** ERROR: x and value must be speficied! *****;
			%abort;
		%end;
	
	%if %isBlank(&delimiter) eq 1 %then
		%do;
			%let delimiter = %str( );
		%end;
	
	%let all_eq = 1;
	
	%let i = 1;
	%let el_x = %qscan(&x, &i, &delimiter);
	
	%do %while(&el_x ne %str());
		%if &el_x = &value %then
			%do;
				%let i = %eval(&i + 1);
				%let el_x = %qscan(&x, &i, &delimiter);
			%end;
		%else
			%do;
				%let all_eq = 0;
				%goto exit;
			%end;
	%end;
	
	%exit:
	&all_eq
%mend all;


%macro match(x, list, return_pos, delimiter) /store;
    %local pos el_x el_list i j;

	 %if %isBlank(&x) eq 1 or %isBlank(&list) eq 1 %then
	 	%do;
			%put @@***** Arguments x and list must be specified!;
			%abort;
		%end;
	%if %isBlank(&delimiter) eq 1 %then
		%do;
			%let delimiter = %str( );
		%end;

	%if %isBlank(&return_pos) eq 1 %then
		%do;
			%let return_pos = 0;
		%end;
	
	%let pos = %str();
	
   	%let i = 1;
	%let el_x = %qscan(&x, &i, &delimiter);
	
	%do %while(&el_x ne %str());
		%let j = 1;
		%let el_list = %qscan(&list, &j, &delimiter);
		
		%do %while(&el_list ne %str());
			%if &el_x eq &el_list %then
				%do;
					%if &return_pos %then
						%let pos = &pos%str( )&j;
					%else
						%let pos = &pos%str( )&el_list;
					
					%goto next_el;
				%end;
			%else
				%do;
					%let j = %eval(&j + 1);
					%let el_list = %qscan(&list, &j, &delimiter);
				%end;
		%end;
		
		%*let result = &pos%str( )0;
		
		%next_el:
	   	%let i = %eval(&i + 1);
      	%let el_x = %qscan(&x, &i, &delimiter);
	%end;
	
	%let pos = %left(&pos);

	%if &pos = %str() %then
		%let pos = 0;
	
	%if &delimiter eq %str( ) or (&pos eq %str()) %then
		%do;
			&pos
		%end;
	%else
		%do;
			%chsep(&pos, &delimiter, %str( ))
		%end;
%mend match;

%macro rep(list=, rep=1, each=0, delimiter=%str( )) / store;
	%local rep_list;

	%let rep_list=%str();

	%if &rep = 0 %then %do; %goto exit; %end;
	
	%if &each = 0 %then
		%do;
			%let rep_list = &list;
			%do i = 2 %to &rep;
				%let rep_list = &rep_list&delimiter&list;
			%end;
		%end;
	%else
		%do;
			%put The -Each- option is not yet implemented!;
			%abort;
		%end;
	
	%exit:
	%quote(&rep_list)
%mend rep;


%macro seq(a, b, by) /store;
	%local s x;

	%if %isBlank(&by) eq 1 %then %do; %let by = 1; %end;
	%put &by;
	
	%let s =; 
	%let x =&a;
	
	%do %while( &x <= &b );
		%let s = &s &x;
		%let x = %eval(&x + &by);
	%end;
	&s
%mend;


%macro realSeq(a, b, by) /store;
	%local s x;
	
	%if %isBlank(&by) eq 1 %then %do; %let by = 1; %end;
	%put &by;
	
	%let s =; 
	%let x =&a;
	
	%do %while( %sysevalf(&x - &b, ceil) < 0);
		%let s = &s &x;
		%let x = %sysevalf(&x + &by);
	%end;
	&s
%mend;


%macro encloseEach(list, pre, post, delimiter) /store;
    %local i encl_list;

    %if %isBlank(&list) eq 1 %then
        %do;
            %put @@ ***** WARNING: encloseEach needs an argument, returning an empty list *****;
            %let encl_list = %str();
			%goto exit;
        %end;
    %if %isBlank(&pre) and %isBlank(&post) eq 1 %then
        %do;
            %put @@ ***** WARNING: both pre and post are missing, returning the list unchanged *****;
            %let encl_list = &list;
            %goto exit;
        %end;
    %if %isBlank(&delimiter) eq 1 %then
        %do;
            %put @@ ***** WARNING: Delimiter Argument is missing, assuming blanks *****;
            %let delimiter = %str( );
        %end;

	%put @@&list@@;
	
    /*Recycling*/
	
    %let length_list = %wc(&list, &delimiter);
	%put Length of list: &length_list;
	
    %if &length_list = 0 %then
        %do;
            %put @@ ***** ERROR: An empty list is not a valid input!;
            %abort;
        %end;
	/*
	%if %isBlank(&pre) eq 1 %then
		%do;
			%let pre = %str();
			%let length_pre = 0;
		%end;
	%if %isBlank(&post) eq 1 %then
		%do;
			%let post = %str();
			%let length_post = 0;
		%end;
	*/
	
	%let length_pre = %wc(&pre, &delimiter);
	%put Length of pre: &length_pre;
	
	%if &length_pre > 0 %then
		%do;
		    %if &length_pre ne &length_list %then
		        %do;
		            %let mod = %sysfunc(mod(&length_list, &length_pre));
		            %if &mod > 0 %then
						%do;
							%put @@ ***** Cannot recycle pre. Length of pre is not a multiple of length of list;
							%abort;
						%end;
					%else
						%do;
							%let numb_copies = %eval(&length_list/&length_pre);
							%let pre = %rep(list = %quote(&pre), rep = &numb_copies, delimiter = &delimiter);
							%put @@ ***** Recycled pre: &pre;
						%end;
		        %end;
			%end;
	%else
		%do;
			%let pre = %rep(list=%str(), rep = &length_list, delimiter = &delimiter);
			%put Empty recycled pre: &pre;
		%end;
	
	%let length_post = %wc(&post, &delimiter);
	%put Length of post: &length_post;

		
	%if &length_post > 0 %then
		%do;
		 	%if &length_post ^= &length_list %then
				%do;
					%put Length post is greater than zero: trying to recycle!;
	         	%let mod = %sysfunc(mod(&length_list, &length_post));

					%if &mod > 0 %then
						%do;
							%put @@ ***** Cannot recycle post. Length of post is not a multiple of length of list;
							%abort;
						%end;
					%else
						%do;
							%let numb_copies = %eval(&length_list/&length_post);
							%let post = %rep(list = %quote(&post), rep = &numb_copies, delimiter = &delimiter);
							%put @@ ***** Recycled post:&post@@;
						%end;
		      %end;
		%end;
	%else /*The case of empty post */
		%do;
			%let post = %rep(list=%str(), rep = &length_list, delimiter = &delimiter);
			%put Empty recycled post: &post;
		%end;

   %let i = 1;
	
	%let pre_el  = %qscan(&pre, &i, &delimiter);
	%let post_el  = %qscan(&post, &i, &delimiter);
   %let encl_list = &pre_el%qscan(&list, &i, &delimiter)&post_el;
	
	 
    %do i = 2 %to &length_list;
      %let element = %qscan(&list, &i, &delimiter);
		%let pre_el  = %qscan(&pre, &i, &delimiter);
		%let post_el = %qscan(&post, &i, &delimiter);
		%let encl_list = &encl_list&delimiter&pre_el.&element.&post_el;
    %end;
	 
    %exit:
    &encl_list
%mend encloseEach;



%macro unique(list, delimiter)  /store;
	
	%local unique_list list_el i;
	
	%if %isBlank(&list) eq 1 %then
		%do;
			%put @@@*** Empty list as argument, aborting...***@@@;
			%abort;
		%end;
	
	%if %isBlank(&delimiter) eq 1 %then %let delimiter = %str( );;
	
	%let i = 1;
	%let list_el = %qscan(&list, &i, &delimiter);
	
	%do %while(&list_el ne %str());
		
		%if %isIn(&list_el, &unique_list, &delimiter) = 0 %then
			%let unique_list = &unique_list&delimiter&list_el;;
		
		%let i = %eval(&i + 1);
		
		%let list_el = %qscan(&list, &i, &delimiter);		
	%end;

	&unique_list
%mend unique;
