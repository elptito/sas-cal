/* Initialise libraries, basic macro variables, etc. for the SAS ASS project... */

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
%mend setPathToCurrent;

%setPathToCurrent;

%let dataDir = ..\..\share\data;
%let reliSysDir = ..\..\share\data\inter;

libname isys "&reliSysDir";
libname fdz "&dataDir\FDZ";
libname crime "&dataDir\crime";
libname uk "&dataDir\UK";
libname ucla "&dataDir\ucla";
libname brfss "&dataDir\BRFSS" COMPRESS = BINARY; 
libname us_pop "&dataDir\us_pop";
libname pus  "&dataDir\PISA\US";
libname els  "&dataDir\ELS02_06";
libname psid  "&dataDir\PSID";
libname cps  "&dataDir\CPS";
libname sipp "&dataDir\SIPP";
libname csfii "&dataDir\CSFII";
libname nhanes "&dataDir\NHANES";


%let iSysDir = %sysfunc(pathname(isys)); 

*libname peas "../../share/data/PEAS"; *TODO: XXX;

%let FDZdataDir =  %sysfunc(pathname(fdz));

%let sTablesDir = ..\script\tables;
%let sGraphsDir = ..\script\graph;

options fmtsearch = (work fdz) mstored sasmstore = sasuser;

%include "./CLAN/clan97_313.sas";
%include "./custom_macros/utility_macros1.sas";
%include "./custom_macros/buildAuxData.sas";
%include "./custom_macros/twoStageSampling.sas";
%include "./custom_macros/parseModel.sas";
%include "./custom_macros/gregeri.sas";
%include "./custom_macros/vec_emu.sas";
%include "./custom_macros/interaction.sas";
%include "./custom_macros/stack.sas";
%include "./custom_macros/buildTotalsTable.sas";
%include "./custom_macros/combineTables.sas";
%include "./custom_macros/cut.sas";
