
/*
 Ausschnitt aus SUF files. Gezogen werden Auswahlbezirke. 10%, nach Bundesland geschichtet.
*/

%macro twoStageSampling(dset=, srate=, psu=, strata=, ssu=, out=,
								print=);

	/*proc sort 	data = mc.Mc&YEAR_h_id_hh
				out = mc.mc&YEAR._sorted;
				by h_bula abez_nr h_id;
	run;
	*/

	/*Could differentiate a list of psu's as ... but..*/
	proc sort data = &dset; by &psu; run;
	
	proc sort data = &dset out = &dset._psu nodupkey; by &psu; run;
	
	proc sort data = &dset._psu; by &strata; run;

	proc surveyselect 
		%if %isBlank(&print) eq 1 %then %do; noprint %end;
		data = &dset._psu
		method = srs
		samprate = &srate
		out = &dset._ps(drop = SelectionProb SamplingWeight);
	strata &strata;
	run;
	
	proc sort data =  &dset._ps; by &psu; run;

	data &out;
		merge
			&dset._ps(in = in_sample)
			&dset
			;
		by &psu;
		
		if in_sample;
	run;

	proc sql;
		drop table &dset._psu, &dset._ps;
	quit;
%mend twoStageSampling;
