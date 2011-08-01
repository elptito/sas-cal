
%let currentDir=;


%macro setPathToCurrent;
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

  %let currentDir = &cPathName;

%mend setPathToCurrent;

%setPathToCurrent;

libname survey "../data";



options fmtsearch = (work fdz) mstored sasmstore = sasuser;

%include "./macrro_gregg.sas";                /*MACRO GREGAR*/
%include "../CLAN/clan97_313.sas";
%include "../shared/utility_macros1.sas";
%include "../shared/buildAuxData.sas";
%include "../shared/parseModel.sas";
%include "../shared/vec_emu.sas";
%include "../shared/interaction.sas";

/*%include "./shared/stack.sas";*/
%include "../shared/buildTotalsTable.sas";
%include "../shared/combineTables.sas";
