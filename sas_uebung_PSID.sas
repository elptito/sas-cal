/* PSID 2003-2007 

Datenaufbereitung:

1) 	Nur Personen im Alter 21-65 Jahre
2) 	Nur Personen, die in 2003 Respondenten waren (i.e. kein Nonresponse, 
	keine Personen in Institutionen.
3)  

*/

options nofmterr fmtsearch = (work psid.formats) mstored sasmstore = sasuser;

%include "&dataDir\PSID\J114704.sas";
%include "&dataDir\PSID\J114693.sas";

/**
proc contents data = psid.p0107_raw; run;
**/

data psid.p0107;
	set psid.p0107_raw;
	
	array hempl1{3} ER17216 ER17217 ER17218;
	array wempl1{3} ER17786 ER17787 ER17788;
	
	if ER33603 = 10 then
		do;
			if hempl1(1) = 2 or hempl1(2) = 2 or hempl1(2) = 2 then empl_stat1 = 2;
			else 
			if hempl1(1) = 1 or hempl1(2) = 1 or hempl1(2) = 1 then empl_stat1 = 1;
			else 
			if hempl1(1) = 3 or hempl1(2) = 3 or hempl1(2) = 3 then empl_stat1 = 3;
			else
			if hempl1(1) = 4 or hempl1(2) = 4 or hempl1(2) = 4 then empl_stat1 = 4;
			else
			if hempl1(1) = 5 or hempl1(2) = 5 or hempl1(2) = 5 then empl_stat1 = 5;
			else
			if hempl1(1) = 7 or hempl1(2) = 7 or hempl1(2) = 7 then empl_stat1 = 7;
			else
			if hempl1(1) = 6 or hempl1(2) = 6 or hempl1(2) = 6 then empl_stat1 = 6;
			else
			if hempl1(1) = 8 or hempl1(2) = 8 or hempl1(2) = 8 then empl_stat1 = 8;
			else
			if hempl1(1) = 9 or hempl1(2) = 9 or hempl1(2) = 9 then empl_stat1 = 9;
			else
				empl_stat1 = hempl1(1);
		end;
	else if ER33603 in (20, 22) then
		do;
			if wempl1(1) = 2 or wempl1(2) = 2 or wempl1(2) = 2 then empl_stat1 = 2;
			else 
			if wempl1(1) = 1 or wempl1(2) = 1 or wempl1(2) = 1 then empl_stat1 = 1;
			else 
			if wempl1(1) = 3 or wempl1(2) = 3 or wempl1(2) = 3 then empl_stat1 = 3;
			else
			if wempl1(1) = 4 or wempl1(2) = 4 or wempl1(2) = 4 then empl_stat1 = 4;
			else
			if wempl1(1) = 5 or wempl1(2) = 5 or wempl1(2) = 5 then empl_stat1 = 5;
			else
			if wempl1(1) = 7 or wempl1(2) = 7 or wempl1(2) = 7 then empl_stat1 = 7;
			else
			if wempl1(1) = 6 or wempl1(2) = 6 or wempl1(2) = 6 then empl_stat1 = 6;
			else
			if wempl1(1) = 8 or wempl1(2) = 8 or wempl1(2) = 8 then empl_stat1 = 8;
			else
			if wempl1(1) = 9 or wempl1(2) = 9 or wempl1(2) = 9 then empl_stat1 = 9;
			else
				empl_stat1 = ER33612;	
		end;
	else
		empl_stat1 = ER33612;
	
	array hempl7{3} ER36109 ER36110 ER36111;
	array wempl7{3} ER36367 ER36368 ER36369;
	
	if ER33903 = 10 then
		do;
			if hempl7(1) = 2 or hempl7(2) = 2 or hempl7(2) = 2 then empl_stat7 = 2;
			else 
			if hempl7(1) = 1 or hempl7(2) = 1 or hempl7(2) = 1 then empl_stat7 = 1;
			else 
			if hempl7(1) = 3 or hempl7(2) = 3 or hempl7(2) = 3 then empl_stat7 = 3;
			else
			if hempl7(1) = 4 or hempl7(2) = 4 or hempl7(2) = 4 then empl_stat7 = 4;
			else
			if hempl7(1) = 5 or hempl7(2) = 5 or hempl7(2) = 5 then empl_stat7 = 5;
			else
			if hempl7(1) = 7 or hempl7(2) = 7 or hempl7(2) = 7 then empl_stat7 = 7;
			else
			if hempl7(1) = 6 or hempl7(2) = 6 or hempl7(2) = 6 then empl_stat7 = 6;
			else
			if hempl7(1) = 8 or hempl7(2) = 8 or hempl7(2) = 8 then empl_stat7 = 8;
			else
			if hempl7(1) = 9 or hempl7(2) = 9 or hempl7(2) = 9 then empl_stat7 = 9;
			else
				empl_stat7 = hempl7(1);
		end;
	else if ER33903 in (20, 22) then
		do;
			if wempl7(1) = 2 or wempl7(2) = 2 or wempl7(2) = 2 then empl_stat7 = 2;
			else 
			if wempl7(1) = 1 or wempl7(2) = 1 or wempl7(2) = 1 then empl_stat7 = 1;
			else 
			if wempl7(1) = 3 or wempl7(2) = 3 or wempl7(2) = 3 then empl_stat7 = 3;
			else
			if wempl7(1) = 4 or wempl7(2) = 4 or wempl7(2) = 4 then empl_stat7 = 4;
			else
			if wempl7(1) = 5 or wempl7(2) = 5 or wempl7(2) = 5 then empl_stat7 = 5;
			else
			if wempl7(1) = 7 or wempl7(2) = 7 or wempl7(2) = 7 then empl_stat7 = 7;
			else
			if wempl7(1) = 6 or wempl7(2) = 6 or wempl7(2) = 6 then empl_stat7 = 6;
			else
			if wempl7(1) = 8 or wempl7(2) = 8 or wempl7(2) = 8 then empl_stat7 = 8;
			else
			if wempl7(1) = 9 or wempl7(2) = 9 or wempl7(2) = 9 then empl_stat7 = 9;
			else
				empl_stat7 = ER33612;
		end;
	else 
		empl_stat7 = ER33612;
	
	* Set missing values where appropriate;
	
	** House value;
		*** 2001;
	if ER17044 = 9999998 then ER17044 = .D;
	else
	if ER17044 = 9999999 then ER17044 = .R;
		*** 2007;
	if ER36029 = 9999998 then ER36029 = .D;
	else
	if ER36029 = 9999999 then ER36029 = .R;
	
	if ER33604 = 999 then ER33604 = .D;
	
	** Rent variables;
		*** 2001;
	if ER17075 = 9 then ER17075 = .R;
	else 
	if ER17075 = 8 then ER17075 = .D;
		*** 2007;
	if ER36066 = 9 then ER36066 = .R;
	else 
	if ER36066 = 8 then ER36066 = .D;
	
	** Adjust the rent variable to a uniform period of reference;
		*** 2001;
	if ER17075 = 3 then  ER17074 = 4*ER17074;
	else
	if ER17075 = 4 then  ER17074 = 2*ER17074;
	else
	if ER17075 = 6 then  ER17074 = ER17074/12;
	else
	if 	ER17075 = 7 or missing(ER17075) then call missing(ER17074);
		*** 2007;
	if ER36066 = 3 then  ER36065 = 4*ER36065;
	else
	if ER36066 = 4 then  ER36065 = 2*ER36065;
	else
	if ER36066 = 6 then  ER36065 = ER36065/12;
	else
	if 	ER36066 = 7 or missing(ER36066) then call missing(ER36065);
	
	** Stock value;
		*** 2001;
	if ER19203 = 999999998 then ER19203 = .D;
	else
	if ER19203 = 999999999 then ER19203 = .R;
		*** 2007;
	if ER37567 = 999999998 then ER37567 = .D;
	else
	if ER37567 = 999999999 then ER37567 = .R;
	
	** Debt value;
		*** 2001;
	if ER19227 = 999999998 then ER19227 = .D;
	else 
	if ER19227 = 999999999 then ER19227 = .R;
		*** 2007;
	if ER37621 = 999999998 then ER37621 = .D;
	else 
	if ER37621 = 999999999 then ER37621 = .R;
	
	** Cash in accounts;
		*** 2001;
	if ER19216 = 999999998 then ER19216 = .D;
	else 
	if ER19216 = 999999999 then ER19216 = .R;
		*** 2007;
	if ER37595 = 999999998 then ER37595 = .D;
	else 
	if ER37595 = 999999999 then ER37595 = .R;
		
	** Subsetting;
	
	where
		ER33601 > 0 /* Only individuals participating in 2001 */
		and ER33602 in (1:20, 71:80) /* In family in 2001 and mover-outs between 1999 and 2001 */
		and ER33604 in (21:59) /* Age between 21 and 59 years */
		;
	
	** Exclude missing and invalid values;

	if	empl_stat1 ne 0 
		and nmiss(	ER17075, ER17044, ER19203, ER19227, ER19216, ER37595, ER37567,
					ER36066) = 0

		then output; /* No nonresponse in 2001 */
		
	drop
		/** Drop variables pertaining to 2003 and 2005 **/
		ER33701 ER33702 ER33703 ER33704 ER33705 ER33706 ER33707 ER33708 ER33709 ER33710 ER33711 ER33712
		ER33713 ER33714 ER33715 ER33716 ER33717 ER33718 ER33719 ER33720 ER33721 ER33722 ER33723 ER33724
		ER33725 ER33726 ER33727 ER33728 ER33729 ER33730 ER33731 ER33732 ER33733 ER33734 ER33735 ER33736
		ER33737 ER33738 ER33739 ER33740 ER33741 ER33742 ER33801 ER33802 ER33803 ER33804 ER33805 ER33806
		ER33807 ER33808 ER33809 ER33810 ER33811 ER33812 ER33813 ER33814 ER33815 ER33816 ER33817 ER33818
		ER33819 ER33820 ER33821 ER33822 ER33823 ER33824 ER33825 ER33826 ER33827 ER33828 ER33829 ER33830
		ER33831 ER33832 ER33833 ER33834 ER33835 ER33836 ER33837 ER33838 ER33839 ER33840 ER33841 ER33842
		ER33843	ER33844 ER33845 ER33846 ER33847 ER33848
		
		/** Variables from 2001 and 2007 **/
		ER33606 ER33608 ER33613 ER33614 ER33630 ER33631 ER33632 ER33633 ER33634
		ER17216 ER17217 ER17218
		ER17786 ER17787 ER17788 ER33622 ER33623 ER33624 ER33625 ER33627 ER33628 ER33629 
		ER33605 ER33607 ER33609 ER33610 ER33611 ER33612
		
		ER33905 ER33906 ER33909 ER33910 ER33914 ER33915 ER33939 ER33940 ER33941 ER33942 ER33943 
		ER36109 ER36110 ER36111
		ER36367 ER36368 ER36369
		ER33907 ER33913
		ER33924 ER33925 ER33927 ER33928 ER33929 ER33930 ER33931 ER33932 ER33933 ER33934 ER33935
		ER33936 ER33938 ER33950  
		;
	rename
		/** 1968 summary variables **/
		ER30001 = intvw68
		ER30002 = pn68
		
		/** 2001 ind **/
		ER33601 = intvw1
		ER33602 = seq1
		ER33603 = rel2head1
		ER33604 = age1
		ER33616 = educ1
		ER33636 = nr_reason1
		ER33615 = student_p1
		ER33617 = ghealth_p1
		ER33637 = long_wght1
		ER33639 = cross_wght1
		ER33626 = help_or_p1
		ER33635 = type_rec1
		ER33638 = cds_intvw_result1

		/** 2001 fam **/
		ER17016 = children_n1
		ER17024 = head_marst1
		ER17044 = hval1
		ER17074 = rent1
		ER17075 = rent_ref1
		ER19203 = stock_val1
		ER19216 = cash1
		ER19227 = debt_val1
		ER20456 = fam_inc1
		ER33618 = health_ins1_1
		ER33619 = health_ins1_2
		ER33620 = health_ins1_3
		ER33621 = health_ins1_4
				
		/** 2007 ind **/
		ER33901 = intvw7
		ER33902 = seq7
		ER33903 = rel2head7
		ER33904 = age7
		ER33917 = educ7
		ER33949 = nr_reason7
		ER33916 = student_p7
		ER33918 = ghealth_p7
		ER33912 = tanf_pay_p7
		ER33937 = help_or_p7
		ER33944 = eligible_cds_p7
		ER33945 = cds_intvw_result7
		ER33946 = attritor_proj7
		
		/** 2007 fam **/
		ER36020 = children_n7
		ER36023 = head_marst7
		ER36029 = hval7 
		ER36065	= rent7
		ER36066	= rent_ref7
		ER37567 = stock_val7
		ER37595	= cash7
		ER37621	= debt_val7
		ER41027	= fam_inc7
		ER33919 = health_ins7_1
		ER33920 = health_ins7_2
		ER33921 = health_ins7_3
		ER33922 = health_ins7_4
		ER33923 = state_ins_kids_p7
		ER33926 = medicare_nr_p7		
		;
run;

proc datasets library = psid;
	modify sex;
	rename
		ER32000 = sex 
		ER30001 = intvw68
		ER30002 = pn68
		;
run; quit;

proc sort data = psid.p0107; by intvw68 pn68; run;
proc sort data = psid.sex; by intvw68 pn68; run;

data psid.p0107;
	merge psid.p0107(in = in_wave0107) psid.sex;
	by intvw68 pn68;
	if in_wave0107;
run;


proc datasets library = psid;
	modify  p0107;
	format	sex sex.
				rel2head1 relhead.
				rel2head7 relhead.
				empl_stat1 emplst.
				empl_stat7 emplst.
				nr_reason1 whynr.
				nr_reason7 whynr.
		;
	label	empl_stat1 = 'Employment Status 2001'
			empl_stat7 = 'Employment Status 2007'
			;
run; quit;


data psid.p0107 psid.test;
	set psid.p0107;
	
	array var7{*} 	children_n7 age7 educ7 rel2head7 empl_stat7 head_marst7 
						hval7 student_p7 ghealth_p7
						rent7 rent_ref7 stock_val7 cash7 debt_val7 fam_inc7;
						
	if nr_reason7 ne 0 then
		do;
			do i = 1 to dim(var7);
				call missing(var7(i));
			end;
			output psid.test;			
		end;
	output psid.p0107;

	drop 	i long_wght1 rent_ref1 rent_ref7 ER33908 ER33911 ER33947 ER33948 cds_intvw_result1
			cds_intvw_result7 eligible_cds_p7
			ghealth_p1  ghealth_p7

		;
	label
		rent
run;


proc contents data = psid.p0107; run;
