/* Calibrating a cluster sample */

%macro function(i, j);
	%tot(ef25_tot, ef25, 1);
	%tot(pop_size, 1, 1);

	%div(ef25_mean, ef25_tot, pop_size);

	%estim(ef25_mean);
%mend function;

%clan(data = dat.gls01_smpl, sampunit = c, clustid = betr_id,
		stratid = schicht_nr, npop = schicht_gr, nresp = schicht_n, 
		maxrow = 1, maxcol = 1);

proc print data = Dut; run;
