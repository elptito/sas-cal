
/*
 Ausschnitt aus SUF files. Gezogen werden Auswahlbezirke. 10%, nach Bundesland geschichtet.
*/

%macro twoStageSampling(dset=, srate=, psuid=, psu_strata=, ssuid=,
								subsMethod=,
								subsRate=,
								out=,
								print=);

	/*proc sort 	data = mc.Mc&YEAR_h_id_hh
				out = mc.mc&YEAR._sorted;
				by h_bula abez_nr h_id;
	run;
	*/

	/*Could differentiate a list of psuid's as ... but..*/
	proc sort data = &dset; by &psuid; run;
	
	proc sort data = &dset out = &dset._psuid nodupkey; by &psuid; run;
	
	proc sort data = &dset._psuid; by &psu_strata; run;

	proc surveyselect 
		%if %isBlank(&print) eq 1 %then %do; noprint %end;
		data = &dset._psuid
		method = srs
		samprate = &srate
		out = &dset._ps(drop = SelectionProb SamplingWeight);
	%if %isBlank(&psu_strata) ne 1 %then %do; strata &psu_strata; %end;
	run;
	
	proc sort data =  &dset._ps; by &psuid; run;

	data &out;
		merge
			&dset._ps(in = in_sample)
			&dset
			;
		by &psuid;
		
		if in_sample;
	run;

	proc sql;
		drop table &dset._psuid, &dset._ps;
	quit;
%mend twoStageSampling;
