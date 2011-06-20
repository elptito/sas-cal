libname dat "p:\proj\dmadata\srvsmpl\share\data\FDZ";

** Laden der Makros;

options nofmterr fmtsearch = (dat work) mstored sasmstore = sasuser;

data soz98;
   set dat.soz98;
   if cmiss(miete, bedarf) then delete;
   if miete = 0 then delete;
   
   age = 1998 - GEB_JAHR;

	%cut(var = age, newvar = ageGr, breaks = 30 40 50 65);

	pid = 10*LFD_HHNR + LFD_P_NR;
   unit = 1;
run;

** 1) Ziehen einer Stichprobe;

proc surveyselect noprint
	data = soz98
	method = SRS
	samprate = 0.05
	stats
	out = soz98_smpl
	seed = 54123
	;
run;

** 2) Ratio-Schaetzer: ;

proc gplot data = soz98_smpl;
	plot bedarf*miete;
run;
	plot bedarf*dauer1;
run;
	plot bedarf*age;
run;
quit;


proc surveymeans
	data = soz98_smpl
	N = 33114
	mean
	;
	var bedarf;
	weight samplingWeight;
run;

** 2a) Schaetzen des Mittelwerts von bedarf, ratio-schaetzer mit miete als Hilfsvariable;

%gregeri(formula = ~c(unit) + c(miete) + c(age), sframe = soz98, aux_out_file = clan_aux_input);


%macro function(i, j);
	%auxvar(datax = clan_aux_input, wkout = cal_gew, datawkut = soz98_smpl, ident = pid);
	
	%tot(bedarf_tot_pi, bedarf, 1);
	%greg(bedarf_tot, bedarf, 1);
	%tot(p_size, 1, 1);
	
	%div(bedarf_mean, bedarf_tot, p_size);
	%div(bedarf_mean_pi, bedarf_tot_pi, p_size);
	
	%estim(bedarf_mean);
	%estim(bedarf_mean_pi);
%mend function;

%clan(data = soz98_smpl, NPOP = 33114, nresp = 1656, maxrow = 1, maxcol = 1);

proc print data = Dut; run;
