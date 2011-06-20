/* Calibrating a cluster sample */

data ucla.apiclus2;
	infile "&dataDir\ucla\apiclus2.csv" dsd delimiter = ',' missover firstobs = 2;
	input 	cds : $14. stype : $1. name : $50. sname : $50. snum dname : $50. 
			dnum cname : $50. cnum flag
			pcttest api00 api99 target growth sch_wide : $3. comp_imp : $3. both : $3.
			awards : $3. meals ell yr_rnd : $3. mobility acs_k3 acs_46 acs_core pct_resp 
			not_hsg hsg some_col col_grad grad_sch avg_ed full emer 
			enroll api_stu pw fpc1 fpc2;
run; 

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
