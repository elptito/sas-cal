%macro cut(var=, newvar=, breaks=, levels=, na=, missing=, right=1) /store;
	%local i upper;
	
	%if %isBlank(&breaks) eq 1 %then
		%do;
			%put Breaks must be specified. Exiting...;
			%abort;
		%end;
	
	%if %isBlank(&newvar) eq 1 %then	%put @***** WARNING: will overwrite the original variable! *****;
	%if %isBlank(&na) eq 1 %then	%put @***** No explicit na specified, using system missing value. *****;
	%if %isBlank(&missing) eq 1 %then %put @***** No explicit missing specified, using system missing value. *****;
	
	%if %isBlank(&levels) eq 1 %then
		%do;
			%put @@***** Levels argument is not specified, using a sequence of integers starting from 1. *****;
			%let levels = %seq(1, %eval(%wc(&breaks) + 1));
		%end;
	
	%if &right eq 1 %then 
		%let relop = %quote(<=);
	%else 
		%let relop = %quote(<);
	
	if (missing(&var) or (&var in (. &na &missing)) )  then &newvar = &var;
	else
	
	%let i = 1;
	%let upper = %qscan(&breaks, %eval(&i), %str( ));
	
	%do %while(&upper ne %str());
		
		if &var %unquote(&relop) &upper then &newvar = %qscan(&levels, &i, %str( ));
		else
		%let i = %eval(&i + 1);
		%let upper = %qscan(&breaks, %eval(&i), %str( ));
	%end;
	
	&newvar = %qscan(&levels, &i, %str( ));
%mend cut;
