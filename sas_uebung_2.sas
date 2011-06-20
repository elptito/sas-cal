
/* Uebung 2 (SAS) */

** Pfad anpassen!; 
libname dat "e:\proj\dmadata\srvsmpl\share\data\FDZ";

** Laden der Makros;

options nofmterr fmtsearch = (dat work) mstored sasmstore = sasuser;


data les01;
	set dat.les01;
	rename samplingWeight = gew;
	
	if cmiss(sde, gde, einkommen, zve, est_tarif, est_fest) then delete;
run;

%interaction(var = region ef8, newvar = r_geschl, dat = les01, newdat = les01);


** 1) Ziehen einer Stichprobe;

proc surveyselect noprint
	data = les01
	method = SRS
	samprate = 0.01
	stats
	out = les01_smpl
	seed = 54123
	;
run;

** 2) Ratio-Schaetzer: Wahl zwischen 2 Merkmalen;

proc sort data = les01_smpl; by ef8; run;

proc boxplot data = les01_smpl;
	plot sde*ef8 /clipfactor = 1.5;
run;

proc sort data = les01_smpl; by region; run;
proc boxplot data = les01_smpl;
	plot sde*region /clipfactor = 1.5;
run;


proc sort data = les01_smpl; by r_geschl; run;
proc boxplot data = les01_smpl;
	plot sde*r_geschl /clipfactor = 1.5;
run;



%gregeri(formula = ~r_geschl, sframe = les01, aux_out_file = clan_aux_input);


%macro function(i, j);
	%auxvar(datax = clan_aux_input, wkout = cal_gew, datawkut = les01_smpl, ident = ef0);
	
	%tot(sde_tot_pi, sde, 1);
	%greg(sde_tot, sde, 1);
	%tot(p_size, 1, 1);
	
	%div(bedarf_mean, bedarf_tot, p_size);
	%div(bedarf_mean_pi, bedarf_tot_pi, p_size);
	
	%estim(bedarf_mean);
	%estim(bedarf_mean_pi);
%mend function;

%clan(data = les01_smpl, NPOP = 257158, nresp = 2572, maxrow = 1, maxcol = 1);

proc print data = Dut; run;
