

options nofmterr fmtsearch = (work els.formats) mstored sasmstore = sasuser;



proc contents data = els.Els_02_06_byf1tsch_v1_0 varnum;  run;









/* Keep only the selected variables */
data edat.ELS0206BYF2STUv10100629063219;
   set edat.ELS_02_06_BYF2STU_v1_0(keep=
      BYSEX
      BYRACE
      BYSTLANG
      BYHOMLNG
      BYSTLNG2
      BYDOB_P
      BYFCOMP
      BYSIBSTR
      BYSIBHOM
      BYGNSTAT
      BYPARED
      BYINCOME
      BYSES1
      BYHOMLIT
      BYRISKFC
      BYSTEXP
      BYPARASP
      BYOCCHS
      BYSQSTAT
      BYTXSTAT
      BYPQSTAT
      BYTXCSTD
      BYTXCQU
      BYENGLSE
      BYINSTMO
      BYSTPREP
      BYWRTNGA
      BYBASEBL
      BYSOFTBL
      BYBSKTBL
      BYFOOTBL
      BYSOCCER
      BYTEAMSP
      BYSOLOSP
      BYCHRDRL
      BYWORKSY
      BYURBAN
      BYREGION
      BYREGURB
      BYREGCTL
      BYSCSAF1
      BYSCSAF2
      BYACCLIM
      STU_ID
      SCH_ID
      STRAT_ID
      PSU
      F1SCH_ID
      F1UNIV1
      F1UNIV2A
      F1UNIV2B
      F2UNIV_P
      BYSTUWT
      F1QWT
      F1PNLWT
      F1TRSCWT
      F2QTSCWT
      F2QWT
      F2F1WT
      F2BYWT
   );


run;

/* Display frequencies for the categorical variables */
proc freq data=edat.ELS0206BYF2STUv10100629063219;

   table
      BYSEX
      BYRACE
      BYSTLANG
      BYHOMLNG
      BYSTLNG2
      BYFCOMP
      BYSIBSTR
      BYSIBHOM
      BYGNSTAT
      BYPARED
      BYINCOME
      BYHOMLIT
      BYRISKFC
      BYSTEXP
      BYPARASP
      BYOCCHS
      BYSQSTAT
      BYTXSTAT
      BYPQSTAT
      BYTXCQU
      BYBASEBL
      BYSOFTBL
      BYBSKTBL
      BYFOOTBL
      BYSOCCER
      BYTEAMSP
      BYSOLOSP
      BYCHRDRL
      BYWORKSY
      BYURBAN
      BYREGION
      BYREGURB
      BYREGCTL
      PSU
      F1UNIV1
      F1UNIV2A
      F1UNIV2B
      F2UNIV_P
      ;

run;

/* Display descriptives for the continuous variables */
proc univariate data=edat.ELS0206BYF2STUv10100629063219;

   var
      BYDOB_P
      BYSES1
      BYTXCSTD
      BYENGLSE
      BYINSTMO
      BYSTPREP
      BYWRTNGA
      BYSCSAF1
      BYSCSAF2
      BYACCLIM
      STU_ID
      SCH_ID
      STRAT_ID
      F1SCH_ID
      BYSTUWT
      F1QWT
      F1PNLWT
      F1TRSCWT
      F2QTSCWT
      F2QWT
      F2F1WT
      F2BYWT
      ;

run;

/* Keep only the selected variables */
data edat.ELS0206F2INSTv10100629063219;
   set edat.ELS_02_06_F2INST_v1_0(keep=
      F2ILEVEL
      F2ICNTRL
      F2ISECTR
      STU_ID
      F2IORDER
   );


run;

/* Display frequencies for the categorical variables */
proc freq data=edat.ELS0206F2INSTv10100629063219;

   table
      F2ILEVEL
      F2ICNTRL
      F2ISECTR
      F2IORDER
      ;

run;

/* Display descriptives for the continuous variables */
proc univariate data=edat.ELS0206F2INSTv10100629063219;

   var
      STU_ID
      ;

run;

