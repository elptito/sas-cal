%macro _AUXV1 /store;

 /* Generera XV och XV2 */

 DATA _DATAX; %let _sets=&_sets _DATAX;
  set &DATAX end=_eof;
  retain _nmax 0;
  if n > _nmax then
  _nmax=int(n)*(1-(n<0));
  if _eof then call symput('nmax',left(put(_nmax,4.)));
 RUN;
 %if &nmax=0 %then %let nmax=1;

 PROC CONTENTS noprint data=_DATAX
                out=__MARVAR(keep=name type); %let _sets=&_sets __MARVAR;

 DATA _NULL_;
  set __MARVAR end=_eof;
  _marset+left(upcase(name))="XTYPE";
  _marset+left(upcase(name))="XDOM";
  %if &_strtgi=3 or &_strtgi=4 or &_strtgi=6 %then %do;
   _vlvl+left(upcase(name))="VLEVEL";
  %end;
  %else _vlvl=0;;
  %if &BLOCK ne %then %do;
   if left(upcase(name))="BLOCKID" then do;
     CALL SYMPUT('_blktype',left(put(type,1.)));
     _block+1;
   end;
  %end;
  if substr(left(upcase(name)),1,3)="TSX" then _tsx+1;
  if substr(left(upcase(name)),1,3)="MAR" then _tux+1; 
  if _eof then do;
    CALL SYMPUT('vlvl',left(put(_vlvl,1.)));
    if _marset=0 or _marset=2 then
      CALL SYMPUT('marset',left(put(_marset,1.)));
    else do;
     put /"******CLAN******";
     put "E R R O R.. wrong number of variables in %upcase(&DATAX)!";
     CALL SYMPUT('_fel','1');
    end;
   %if &BLOCK ne %then %do;
    if _block=0 then do;
     put /"******CLAN******";
     put "E R R O R.. BLOCKID is missing in %upcase(&DATAX)!";
     CALL SYMPUT('_fel','1');
    end;
   %end;
   %if &RTOU=Y %then %do;
    if _tux=0 then do;
     put /"******CLAN******";
     put "E R R O R.. the margins MAR are missing in %upcase(&DATAX)!";
     CALL SYMPUT('_fel','1');
    end;
   %end; 
   %if &CNR=Y and &SET=R %then %do;
    if _tsx=0 then do;
     put /"******CLAN******";
     put "E R R O R.. the margins TSX are missing in %upcase(&DATAX)!";
     put '            (CNR=Yes and SET=R).';
     CALL SYMPUT('_fel','1');
    end;
   %end;     
  end;
 RUN;
 %if &_fel=1 %then %goto _AUXEND1;

   /* marset=0 om CALMAR-stil på DATAX =2 om spridningsvariabel
      och typ finns för de numeriska variablerna
      vlvl=0 om VLEVEL inte finns eller saknar mening            */

 DATA __MAR1; %let _sets=&_sets __MAR1;
  set _DATAX end=_eof;
  var=left(upcase(var));
  n=int(n)*(1-(n<0));
  %if &marset=0 %then %do;
   type="C";                        /*  kategorisk variabel  */
   if n=0 then do;                  /*  numerisk variabel    */
    type="N";
    xdom='_ETT';
   end;
  %end;
  %else %do;
   if xtype=' ' and n<2 then xtype='N';
   if xdom=' ' and n<2 then xdom='_ETT';
   type=left(upcase(xtype));
   xdom=left(upcase(xdom));
  %end;
  if type='N' and xdom=' ' then do;
   put /'******CLAN******';
   put 'E R R O R.. no XDOM-var in &DATAX !';
   CALL SYMPUT('_fel','1');
  end;
  %if &BLOCK= %then %do;
   %let _BLOCK=_ETT;
   blockid=1;
   %let _blktype=1;
  %end;
  %else %do;
    %let _BLOCK=&BLOCK;
    %if &_blktype=2 %then blockid=LEFT(UPCASE(blockid));;
  %end;  
  n=max(1,n);
  %if &vlvl=0 %then VLEVEL=&__mdlvl;;
   if not (VLEVEL IN(1,2)) then VLEVEL=&__mdlvl;
   if VLEVEL lt &__mdlvl then do;
    put /'******CLAN******';
    put 'E R R O R.. ' var "has lower value than MLEVEL (=&__mdlvl)!";
    CALL SYMPUT('_fel','1');
   end;

   /*  Om marginalerna är uttryckta i %...  */

  %if %upcase(%substr(&PCT,1,1))=Y and &RTOU=Y %then
  %do;
    if type="C" then
    do;
      array marge  mar1-mar&nmax;
      do over marge;
        marge=marge/100*&effpop;
      end;
    end;
  %end;

  keep var n %if &RTOU=Y %then mar1-mar&nmax;
       %if &CNR=Y and &SET=R %then tsx1-tsx&nmax;
       type vlevel xdom blockid;
 RUN;
 %if &_fel=1 %then %goto _AUXEND1;

   /*   Tag reda på innehållet i DATA */

 PROC CONTENTS noprint data=_ds0
                out=__NUMVAR(keep=name type rename=(name=var));
 %let _sets=&_sets __NUMVAR;
 DATA __NUMVAR; set __NUMVAR; var=upcase(var); run; /* fix för V8 */
 PROC SORT; BY var;

 PROC SORT data=__MAR1;
  BY var;

 DATA __MAR1;
  merge __NUMVAR(rename=(type=typesas) in=in1)
        __MAR1(in=in2) end=_eof;
  by var;
  if in2;
  if not in1 then do;
   put /"******CLAN******";
   put 'E R R O R.. ' var "is missing in &DATA !";
   CALL SYMPUT('_fel','1');
  end;
  keep var n %if &RTOU=Y %then mar1-mar&nmax;
       %if &CNR=Y and &SET=R %then tsx1-tsx&nmax;
       type vlevel xdom blockid typesas;
 RUN;
 %if &_fel=1 %then %goto _AUXEND1;

 /* Konstruera macro-variabler med namn, antal kategorier etc*/

 PROC FREQ data=__MAR1;
  tables blockid/ out=__TMP1 noprint; %let _sets=&_sets __TMP1;

 DATA _NULL_;
  set __TMP1 end=_eof;
  _n+1;
  if _eof then call symput('__nblk',left(put(_n,4.)));
  RUN;

 DATA __BLKS(keep=_blks1-_blks&__nblk); %let _sets=&_sets __BLKS;
  set __TMP1 end=_eof;
  array _blks(&__nblk) $;   /* vilka block finns?*/
  retain _blks;
  if _n_=1 then call symput('_blk1',%if &_blktype=1 %then left(put(blockid,8.));
  %else blockid;);
  %if &_blktype=1 %then _blks(_n_)=left(put(blockid,8.));
  %else _blks(_n_)=blockid;
  ;
  if _eof then output;
 RUN;

 %if &_BLOCK ne _ETT %then %do;
 /* kontrollera att alla block ser likadana ut */
  PROC SORT DATA=__MAR1;BY var n type xdom vlevel typesas blockid;
  DATA __MAR2;
  %let _sets=&_sets __MAR2;
   set __MAR1;
   %if &_blktype=1 %then if blockid=&_blk1; %else if blockid=SYMGET('_blk1');
    then output;

  DATA _NULL_;
  merge __MAR1(in=in1) __MAR2(in=in2);
  BY var n type xdom vlevel typesas;
  if not (in1 and in2) then goto ERR&_auxvar;
  return;
  ERR&_auxvar: put /"******CLAN******";
      put 'E R R O R.. Different auxvars in different blocks, blockid='
        blockid;
      CALL SYMPUT('_fel','1');
  RUN;
 %if &_fel=1 %then %goto _AUXEND1;
 %end;

 PROC FREQ data=__MAR1;
  tables type/out=__TMP1 noprint;

 DATA _NULL_;
  set __TMP1;
  %let jj=0;  /* antal kategoriska var */
  %let ll=0;  /* antal numeriska var   */
  if type='C' then call symput('jj',left(put(count/&__nblk,9.)));
  if type='N' then call symput('ll',left(put(count/&__nblk,9.)));
 RUN;

 /*Sortera marginalerna efter block, type och variabel*/

 PROC SORT data=__MAR1;
  BY blockid type var;

 DATA _NULL_;
  set __MAR1 end=_eof; by blockid;
  length mac mae maf mal $ 8;
  if type='C' then do;
   kc+1;
   j=left(put(kc,4.));
   if kc=1 then nn=n; else nn=n-1;
   mac="vc"!!j; /* vcj =namn på kateg. var.  */
   mae="n"!!j;  /* nj = M1, M2-1, M3-1,....,Mjj-1  */
   maf="t"!!j;  /* tj = 1 om num.lagr, =2 om char.lagr  */
   mal="lc"!!j; /* lcj =1 (klust.nivå), =2 (elem.nivå)*/
   call symput(mac,trim(var));
   call symput(mae,left(put(nn,4.)));
   call symput(maf,left(put(typesas,1.)));
   call symput(mal,left(put(vlevel,1.)));
   xsz+nn;
  end;
  if type='N' then do;
   kn+1;
   j=left(put(kn,4.));
   mac="vn"!!j; /* vnj = namn på num var */
   mal="ln"!!j; /* lnj = 1 (klust.nivå), =2 (elem.nivå) */
   mad="vd"!!j; /* vdj = namn på xdom      */
   mae="mn"!!j; /* mnj = antal nivåer för XDOM   */
   call symput(mac,trim(var));
   call symput(mal,left(put(vlevel,1.)));
   call symput(mad,trim(xdom));
   call symput(mae,left(put(n,4.)));
   xsz+n;
  end;
  if last.blockid then do;
   call symput('__xmax',left(put(xsz,4.)));
   stop;
  end;
 RUN;

 %if &_calmar=0 or &RTOU=Y or &SET=R %then %do;
 DATA %if &RTOU=Y %then
   __TUX(keep=_tu1-_tu%eval(&__xmax*&__nblk))  %let _sets=&_sets __TUX;
  %if &CNR=Y and &SET=R %then __TSX(keep=_ts1-_ts%eval(&__xmax*&__nblk))
   %let _sets=&_sets __TSX;;
  set __MAR1 end=_eof; BY blockid;
  %if &CNR=Y and &SET=R %then %do;
   array _ts(%eval(&__xmax*&__nblk));
   array tsx(&nmax);
   retain _ts;
  %end;
  %if &RTOU=Y %then %do;
   array mar(&nmax);
   array _tu(%eval(&__xmax*&__nblk));
   retain _tu;
  %end;
  if type='C' and not first.blockid then n=n-1;
  if n ge 1 then do _i=1 to n;
   _d+1;
   %if &RTOU=Y %then _tu(_d)=mar(_i);;
   %if &CNR=Y and &SET=R %then _ts(_d)=tsx(_i);;
  end;
  if _eof then output;
 RUN;
 %end;

 %if &_sorted=0 %then %do;
 PROC SORT data=_DS0;
 BY &STRATID &GROUPID &CLUSTID %if &_BLOCK ne _ETT %then &_BLOCK; _ide;
 %end;

 DATA _XV&_auxvar(keep=&STRATID &GROUPID &CLUSTID _pos&_auxvar _val&_auxvar _qk&_auxvar
        _q1 %if &CNR=Y %then _vsk&_auxvar _vuk&_auxvar _q0 _ph; _gk&_auxvar
       %if &_strtgi=6 and &MLEVEL=2 %then _qi&_auxvar; 
       %if &WKOUT ne %then &IDENT _kvikt; _num&_auxvar _ak _id&_auxvar _ide)
     %if &_BLOCK ne _ETT %then _err1(keep=_block_);
     _err2(keep=_vnam_ _vval_);
  set _ds0 end=_eof;
   BY &STRATID &GROUPID &CLUSTID %if &_BLOCK ne _ETT %then &_BLOCK;;
   retain _q0 _q1 0;
   retain _diag _ak _gk&_auxvar %if &CNR=Y %then _vsk&_auxvar _vuk&_auxvar; 1;
  %if &_strtgi eq 1 or &_strtgi eq 3 %then %do;
   %if &_ppps=0 %then %do;
    if first.&STRATID then do;
     if &NRESP>0 then _q1=&NPOP/&NRESP; else _q1=0;
     %if &NCHECK=Y %then %do;
     if _q1<1 then do;
      ERROR /'******CLAN******'/
      'E R R O R.. NRESP > NPOP or NRESP=0';
      CALL SYMPUT('_fel','1');STOP;
     end;
     %end;
    end;
   %end;
   %else %do;
     %if &NCHECK=Y %then %do;
     if &NRESP>&NSAMP then do;
      ERROR /'******CLAN******'/
      'E R R O R.. NRESP > NSAMP';
      CALL SYMPUT('_fel','1');STOP;
     end;
     %end;
    if &NRESP>0 and &LAMBDA>0 then _q1=&NSAMP/&NRESP/&LAMBDA; else _q1=0;
   %end;
  %end;

  %if &_strtgi eq 2 or &_strtgi ge 4 %then %do;
   %if &_ppps=0 %then %do;
    if first.&STRATID then do;
     if &NSAMP>0 then _q0=&NPOP/&NSAMP;else _q0=0;
    end;
    %if &_strtgi eq 2 or &_strtgi eq 4 %then %do;
     if first.&STRATID or first.&groupid then do;
     if &NRESP>0 then _q1=_q0*&NGROUP/&NRESP; else _q1=0;
     %if &NCHECK=Y %then %do;
      if _q1<1 then do;
       ERROR /'******CLAN******'/
       'E R R O R.. NSAMP > NPOP or NSAMP=0'
       /'and/or NRESP > NGROUP or NRESP=0!'/;
       CALL SYMPUT('_fel','1');STOP;
      end;
     %end;
     end;
    %end;
   %end;
   %else %do;
    if &LAMBDA>0 then _q0=1/&LAMBDA;
    _q1=_q0;
   %end;
  %end;
  _kvikt=&WEIGHT;
  length _vnam_ $ 8 _vval_ 8;
  array __x&_auxvar._(&__xmax);
  %if &__mdlvl=1 %then retain __x&_auxvar._ 0;;

 %if &_BLOCK ne _ETT %then %do;
  %if &_strtgi=1 or &_strtgi=5 %then 
   if first.&STRATID then ;
  %if &_strtgi=2 %then
   if first.&GROUPID then ;
  %if (&_strtgi=3 or &_strtgi=4 or &_strtgi=6) %then
   if first.&CLUSTID then ;
   _num&_auxvar=0;
  array _blks(&__nblk) $;
  length _blk&_auxvar _word $ 8;
  retain _blk&_auxvar _word;
  if _n_=1 then set __BLKS;
  if first.&_BLOCK then do;
  %if &_blktype=1 %then _blk&_auxvar=left(put(&_BLOCK,8.));
  %else _blk&_auxvar=LEFT(UPCASE(&_BLOCK));
  ;
   if _num&_auxvar=0 then do;
    _num&_auxvar=1;
    _word=_blks(1);
   end;
   do while(_word ne _blk&_auxvar and _word ne ' ');
     _num&_auxvar+1;
     if _num&_auxvar le &__nblk then _word=_blks(_num&_auxvar);
     else _word=' ';
   end;
   if _word=' ' then do;
    _block_=_blk&_auxvar;
    output _err1;
    _berr_+1;
    _num&_auxvar=0;
   end;
   %if &__mdlvl=1 %then %do;
    if not first.&CLUSTID then do;
     ERROR '******CLAN******'/
     "E R R O R , Different blockids in cluster!";
     CALL SYMPUT('_fel','1'); STOP;
    end;
   %end;
  end;
  if _num&_auxvar=0 then goto L1&_auxvar;
 %end;
 %else %do; _num&_auxvar=1; %end;
  _k=0;

    /* Skapa x-vektorn för de kategoriska variablerna */

  %do _j=1 %to &jj;
   %if &&t&_j=2 %then &&vc&_j=input(&&vc&_j,9.);;
   %if &__mdlvl=1 and &&lc&_j=1 %then
   if last.&CLUSTID or last.&STRATID then;
    if &&vc&_j gt 0 and &&vc&_j le &&n&_j then
    %if &__mdlvl=1 and &&lc&_j=2 %then
          __x&_auxvar._(_k+&&vc&_j)+_kvikt;
    %else __x&_auxvar._(_k+&&vc&_j)=_kvikt;
    ;
    else %if &_j>1 %then if not(&&vc&_j gt 0 and &&vc&_j le &&n&_j+1) then;
   do;
    _vnam_="&&vc&_j"; _vval_=&&vc&_j; _verr_+1;
    output _err2;
   end;
   _k+&&n&_j;
  %end;

  /* Skapa x-vektorn för de numeriska variablerna       */

  %do _l=1 %to &ll;
   %if &__mdlvl=1 and &&ln&_l=1 %then
   if last.&CLUSTID or last.&STRATID then;
    if (&&vd&_l) gt 0 and (&&vd&_l) le &&mn&_l then
    %if &__mdlvl=1 and &&ln&_l=2 %then
          __x&_auxvar._(_k+(&&vd&_l))+(&&vn&_l)*_kvikt;
    %else __x&_auxvar._(_k+(&&vd&_l))=(&&vn&_l)*_kvikt;
    ;
    else do;
    _vnam_="&&vd&_l"; _vval_=&&vd&_l; _verr_+1;
    output _err2;
   end;
   _k+&&mn&_l;
  %end;
 %if &_BLOCK ne _ETT %then L1&_auxvar:;
  %if &_calmar=1 %then _gk&_auxvar=(&WKIN)/_q1/_kvikt;;
  if &_qk>0 then _qk&_auxvar=&_qk;
  %if &_strtgi=6 and &MLEVEL=2 %then if &_qi>0 then _qi&_auxvar=&_qi;;
  %if &CNR=Y %then _ph=1+(%QUOTE(&RESPONSE));;
  %if &__mdlvl=2 %then _id&_auxvar=_ide;;	/*** 2002-07-05 ***/
  %if &__mdlvl=1 %then %do;
  if last.&CLUSTID or last.&STRATID then do;
  _id&_auxvar+1;
  %end;		/*** 2002-07-05 ***/
  __is_=0;
  do _i=1 to &__xmax;
   if __x&_auxvar._(_i) then do;
    _pos&_auxvar=_i;
    _val&_auxvar=__x&_auxvar._(_i);
    __is_=1;
    output _XV&_auxvar;
   end;
  end;
  if not __is_ then do;
   _pos&_auxvar=0;
   _val&_auxvar=.;
   output _XV&_auxvar;
  end;
  if _diag then do;
    _dsum=0;
    do _i=1 to &__xmax;
     _dsum+__x&_auxvar._(_i) and 1;
    end;
    _diag=_dsum<2;
  end;
  %if &__mdlvl=1 %then %do;
   do _i=1 to &__xmax;
    __x&_auxvar._(_i)=0;
   end;
  end;
  %end;
  if _eof then do;
    %if &_BLOCK eq _ETT %then _berr_=0;; 
    call symput('__diag',left(put(_diag,1.)));
    call symput('_berr_',left(put(_berr_,8.)));
    call symput('_verr_',left(put(_verr_,8.)));
  end;
  RUN;
 %if &_fel=1 %then %goto _AUXEND1;

 %if &_berr_>0 %then %do;
  proc freq data=_err1; table _block_/out=__tmp1 noprint;run;
  data _null_;
   if _n_=1 then put /"******CLAN******";
   set __tmp1;
   put 'W A R N I N G.. BLOCK ' _block_ $ 8. ' is not in DATAX! ( ' count 5. ' cases)';
  run;
 %end;
 %if &_verr_>0 %then %do;
  proc freq data=_err2;table _vnam_*_vval_/out=__tmp1 noprint; run;
  data _null_;
   if _n_=1 then put /"******CLAN******";
   set __tmp1;
   put "W A R N I N G.. Variable " _vnam_ $ 8. " (value:" _vval_ 4. ") out of range! ( " count 5. " cases)";
  run;
 %end;
 
 %if &__diag=0 %then %let __xxmax=%eval(&__xmax*(&__xmax+1)/2);
              %else %let __xxmax=&__xmax;
 %let _xxsize=%eval(&__nblk*&__xxmax);
 %let __csets=%eval(&_xxsize /&_bmax);
 %if %eval(&__csets*&_bmax) lt &_xxsize %then %let __csets=%eval(&__csets+1);
 
 %let _csets=&_csets &__csets;
 %let _diag=&_diag &__diag;
 %let _xxmax=&_xxmax &__xxmax;
 %let _nblk=&_nblk &__nblk;
 %let _xmax=&_xmax &__xmax;
 %let _mdlvl=&_mdlvl &__mdlvl;
 
 %if &_strtgi=6 and &__mdlvl=2 %then %do;
  DATA _XV2&_auxvar(keep=&STRATID &GROUPID &CLUSTID _pos&_auxvar _val&_auxvar _qk&_auxvar
        _q1 _vsk&_auxvar _vuk&_auxvar _q0 _ph _gk&_auxvar _qi&_auxvar
       %if &WKOUT ne %then &IDENT _kvikt; _num&_auxvar _ak _id&_auxvar _ide);
   array _x(&__xmax) _temporary_;
   retain _diag 1;
   do until(last._id&_auxvar);
    set _XV&_auxvar end=_eof;
     BY &STRATID &GROUPID &CLUSTID _id&_auxvar NOTSORTED;
    if _num&_auxvar>0 and _pos&_auxvar>0 then
    _x(_pos&_auxvar)+_val&_auxvar;
   end;
   if last.&CLUSTID or last.&STRATID then do;
    _id&_auxvar+1;	/*** 2002-07-05 ***/
    __is_=0;
    do _i=1 to &__xmax;
     if _x(_i) then do;
      _pos&_auxvar=_i;
      _val&_auxvar=_x(_i);
      __is_=1;
      output;
     end;
    end;
    if not __is_ then do;
     _pos&_auxvar=0;
     _val&_auxvar=.;
     output;
    end;
    if _diag then do;
     _dsum=0;
     do _i=1 to &__xmax;
      _dsum+_x(_i) and 1;
     end;
     _diag=_dsum<2;
    end;
    do _i=1 to &__xmax;
     _x(_i)=0;
    end;
   end;
   if _eof then call symput('__diag2',left(put(_diag,1.)));
  RUN;
  %if &__diag2=0 %then %let __xxmax2=%eval(&__xmax*(&__xmax+1)/2);
              %else %let __xxmax2=&__xmax;
  %let _xxsize=%eval(&__nblk*&__xxmax2);
  %let __csets2=%eval(&_xxsize /&_bmax);
  %if %eval(&__csets2*&_bmax) lt &_xxsize %then %let __csets2=%eval(&__csets2+1);
  
  %let _csets2=&_csets2 &__csets2;
  %let _diag2=&_diag2 &__diag2;
  %let _xxmax2=&_xxmax2 &__xxmax2;
 %end;
 
 %_AUXEND1:
%mend _AUXV1;

%macro _AUXV2(_XDAT=,_TDAT=, _TNAME=, _WHERE=, _XVIKT=1) /store;
/* Skatta totalerna för x */ 
  
 DATA &_TDAT(keep=&_TNAME.1-&_TNAME%eval(&__xmax*&__nblk)); 
  set &_XDAT&_auxvar&_WHERE end=_eof;
  array &_TNAME(%eval(&__xmax*&__nblk));
  if _num&_auxvar=0 or _pos&_auxvar=0 then goto L1&_auxvar;
  %if %upcase(&_TDAT)=__TRX %then if _ak then &_XVIKT=1;;
  %if &_strtgi>4 %then __g=_q0*&_XVIKT; %else __g=_q1*&_XVIKT;;
  &_TNAME((_num&_auxvar-1)*&__xmax+_pos&_auxvar)+_val&_auxvar*__g;
 L1&_auxvar:
  if _eof then output;
 RUN;
%mend _AUXV2;

%macro _AUXV3(_XDAT=,_CDAT=, _CNAME=, _WHERE=, _DIAG=, _XXVIKT=1) /store;
 /* beräkna inversen av X'X */
%_IC3:
 DATA
  %let _v1=&_bmax;
  %if &_xxsize lt &_v1 %then %let _v1=&_xxsize;
  &_CDAT&_auxvar._(keep=&_CNAME&_auxvar._1-&_CNAME&_auxvar._&_v1);
  %if &_DIAG=0 %then %do;
   array _p_(&__xmax) _temporary_;
   array _x_(&__xmax) _temporary_;
  %end;
  array _txx(&_xxsize) _temporary_;
  array &_CNAME&_auxvar._(&_v1);
  %if &_ppps=0 %then %do;
   array _tmp(&_xxsize) _temporary_;
   retain _tmp 0;
  %end;
  retain _txx 0;
  retain _XXA;

 do until(last._id&_auxvar);
  set &_XDAT&_auxvar&_WHERE end=_eof;
   BY &STRATID &GROUPID &CLUSTID _id&_auxvar NOTSORTED;
  if _num&_auxvar=0 or _pos&_auxvar=0 then goto L1&_auxvar;
  _XXA=(_num&_auxvar-1)*&__xxmax;
   %if &_DIAG=0 %then %do;
    _i_+1;
    _p_(_i_)=_pos&_auxvar;
    _x_(_i_)=_val&_auxvar;
    _idx=(_pos&_auxvar-1)*_pos&_auxvar/2;
     %if &__ic=1 %then if _ak then;
     do _j=1 to _i_;
      _idxx=_idx+_p_(_j);
      %if &_ppps=0 %then _tmp(_XXA+_idxx)+(_x_(_j)*_val&_auxvar*(&_XXVIKT));
      %else _txx(_XXA+_idxx)+(_x_(_j)*_val&_auxvar*(&_XXVIKT)*_q1);;
     end;
   %end;
   %else %do;
    %if &__ic=1 %then if _ak then;
      %if &_ppps=0 %then _tmp(_XXA+_pos&_auxvar)+(_val&_auxvar*_val&_auxvar*&_XXVIKT);
      %else _txx(_XXA+_pos&_auxvar)+(_val&_auxvar*_val&_auxvar*&_XXVIKT*_q1);;
   %end;
 end;
L1&_auxvar:
  _i_=0;
  %if &_ppps=0 %then %do;
   %if &_strtgi eq 1 or &_strtgi eq 3 or &_strtgi=5 or &_strtgi=6 %then 
    if last.&STRATID then;
   %if &_strtgi eq 2 or &_strtgi eq 4 %then
    if last.&STRATID or last.&GROUPID then;
      do _i=1 to &_xxsize;
      _txx(_i)+_tmp(_i)*%if &_strtgi<5 %then _q1;%else _q0;;
      _tmp(_i)=0;
     end;
  %end;
  if _eof then do;
   %if &_DIAG=1 %then %do;
    do _i=1 to &_xxsize;
     if _txx(_i) then _txx(_i)=1/_txx(_i);
    end;
   %end;
   %else %do; /* ej diagonalmatris, Cholesky-invers*/
   do _j=1 to &__nblk;
    _XXA=(_j-1)*&__xxmax;
    _d=0;
    do _i=1 to &__xmax;
     _d+_i;
     if not _txx(_XXA+_d) then _txx(_XXA+_d)=1;
    end;
    do __l=1 to &__xmax;
     __f=_txx(_XXA+1);
     if __f<1.E-7 then
     do; /* Ej positivt definit matris */
      CALL SYMPUT('__f',left(put(__f,best12.)));
      CALL SYMPUT('__l',left(put(__l,4.)));
      CALL SYMPUT('_block',left(put(_j,4.)));
      CALL SYMPUT('_fel','1'); STOP;
     end;
     __f=1/__f;
     __na=1;
     do __i=1 to &__xmax;
      _x_(__i)=_txx(_XXA+__na);
      __na+__i;
     end;
     __nu=0; __nv=0;
     do __i=2 to &__xmax;
      __nu+(__i-2);
      __nv+(__i-1);
      __h=_x_(__i)*__f;
      __na=__nu;
      __nb=__nv+1;
      do __j=2 to __i;
       __na+1;
       __nb+1;
       _txx(_XXA+__na)=_txx(_XXA+__nb)-_x_(__j)*__h;
      end;
     end;
     __na=__nv;
     do __j=2 to &__xmax;
      __na+1;
      _txx(_XXA+__na)=-_x_(__j)*__f;
     end;
     __nn=__na+1;
     _txx(_XXA+__nn)=-__f;
    end;
    do __i=1 to __nn;
     _txx(_XXA+__i)=-_txx(_XXA+__i);
    end;                 /* Slut på inverteringen*/
   end;
  %end;
  _k=0;
  do _i=1 to &__csets;
  do _j=1 to &_v1;
   _k+1;
   if _k le &_xxsize then &_CNAME&_auxvar._(_j)=_txx(_k);
   else &_CNAME&_auxvar._(_j)=0;
  end;
  output;
  end;
 end;
 RUN;
 %if &_fel=1 %then %do;
   %put; %put ******CLAN******;
   %put E R R O R..;
   %put %str(The X%'X-matrix is not positive definite!);
   %put In AUXVAR number &_auxvar., identified by MODELID=&MODELID;
   %put BLOCK: &_block;
   %put Pivot-element nr= &__l is &__f!;
   %put Variable nr &__l will be eliminated!;
   %let _fel=0;
   DATA &_XDAT&_auxvar;
    set &_XDAT&_auxvar;
    if _num&_auxvar=&_block and _pos&_auxvar=&__l then _val&_auxvar=0;
   RUN;
   %goto _IC3;
 %end;
%mend _AUXV3;

%macro _AUXV4(_XDAT=,_CDAT=, _CNAME=,_T1=, _T2=, _RSPNS=, _DIAG=, _GXVIKT=,_U=,_L=) /store;
/* Beräkna gk=1+(tx-thatx)X'X(-1)X' */

 DATA &_XDAT&_auxvar;
 %let _v1=&_bmax;
 %if &_xxsize lt &_v1 %then %let _v1=&_xxsize;
 if _n_=1 then do;
 /* läs in XX */
  array &_CNAME&_auxvar._(&_v1);
  array _txx(&_xxsize) _temporary_;
  _k=0;
  do _i=1 to &__csets;
   set &_CDAT&_auxvar._;
   do _j=1 to &_v1;
    _k+1;
    if _k le &_xxsize then _txx(_k)=&_CNAME&_auxvar._(_j);
   end;
  end;
  set &_T1;
  set &_T2;
  %let __t1=%SUBSTR(&_T1,2,%LENGTH(&_T1)-2);
  %let __t2=%SUBSTR(&_T2,2,%LENGTH(&_T2)-2);
  %let _xsize=%eval(&__xmax*&__nblk);
  array &__t1(&_xsize);
  array &__t2(&_xsize);
  array __lda(&_xsize) _temporary_;
  %if &_DIAG=1 %then %do;
  do _i=1 to &_xsize;
   __lda(_i)=(&__t1(_i)-&__t2(_i))*_txx(_i);
  end;
  %end;
  %else %do;
  do __i=1 to &__nblk;
   _XA=(__i-1)*&__xmax;
   _XXA=(__i-1)*&__xxmax;
   do _i=1 to &__xmax;
    _sum=0;
    do _j=1 to &__xmax;
     _k=max(_i,_j);
     _l=(_k*(_k-1))/2+min(_i,_j);
     _sum+_txx(_XXA+_l)*(&__t1(_XA+_j)-&__t2(_XA+_j));
    end;
    __lda(_XA+_i)=_sum;
   end;
  end;
  %end;
 end;
  _i_=0;  _sum=0;
 retain _i_;
 do until(last._id&_auxvar); 
  set &_XDAT&_auxvar end=_eof;
   BY _id&_auxvar NOTSORTED;
  array _p_(&__xmax) _temporary_;
  array _x_(&__xmax) _temporary_;
  _i_+1;
  _p_(_i_)=_pos&_auxvar;
  _x_(_i_)=_val&_auxvar;
 end;
 retain _maxd _antU _antL 0;
 __g=&_gvikt;
 if _ak then do;
  if _num&_auxvar>0 then do;
   _XA=(_num&_auxvar-1)*&__xmax;
   do _i=1 to _i_;
    if _p_(_i) then do;
     _sum+__lda(_XA+_p_(_i))*_x_(_i);
    end;
   end;
  end;
  __g=1+_sum*&_GXVIKT;
 
 %if (&_U ne or &_L ne) %then %do;
  %if &_U ne %then %do;
   retain _maxU;
   if __g>&_U and (&_RSPNS) then do;
     _antU+1;
     _maxU=max(_maxU, __g);
     __g=&_U;
     _ak=0;
   end;
  %end;
  %if &_L ne %then %do;
   retain _minL;
   if __g<&_L and (&_RSPNS) then do;
     _antL+1;
     _minL=min(_minL, __g);
     __g=&_L;
     _ak=0;
   end;
  %end;
   if &_GXVIKT>0 then do;
    dFdG=((__g-1)/&_GXVIKT-_sum)*%if &CNR=N %then _q1;%else _q0;;
    _maxd=max(_maxd,abs(dFdG));
   end;
  end;
  &_gvikt=__g;
  do _j=1 to _i_;
   _pos&_auxvar=_p_(_j);
   _val&_auxvar=_x_(_j);
   output;
  end;
  _i_=0; _sum=0;
  if _eof then do;
   call symput('_maxd',left(put(_maxd,best12.)));
   if _maxd <=.0001 then call symput('__ic','0');
   else do;
    call symput('__ic','1');
    %if &_U ne %then %do;
     call symput('_antU',left(put(_antU,6.)));
     call symput('_maxU',left(put(_maxU,best12.)));
    %end;
    %if &_L ne %then %do;
     call symput('_antL',left(put(_antL,6.)));
     call symput('_minL',left(put(_minL,best12.)));
    %end;
   end;
  end;
 %end;
 %else %do;
   if __g<0 and (&_RSPNS) then _antL+1;
 end;
 &_gvikt=__g;
  do _j=1 to _i_;
   _pos&_auxvar=_p_(_j);
   _val&_auxvar=_x_(_j);
   output;
  end;
  _i_=0; _sum=0;
   if _eof then do;
    put /'*****CLAN*****';
    put "N. of weights (%SUBSTR(&_gvikt,2,%eval(%LENGTH(&_gvikt)-1))) < 0: " _antL;
   end;
 %end;
 %if %upcase(&_gvikt)=%upcase(_vsk&_auxvar) %then %do;
  retain _antvsk1 _antvsk0 0;
  _antvsk1+(_vsk&_auxvar<1);
  _antvsk0+(_vsk&_auxvar<0);
  if _eof then do;
    put 'N. of vsk < 1: ' _antvsk1 '   N. of vsk < 0: ' _antvsk0;
    _antvsk0=_antvsk0>0;
    call symput('__vskneg',left(put(_antvsk0,1.)));
  end;
 %end;
  keep  &STRATID &GROUPID &CLUSTID _pos&_auxvar _val&_auxvar _qk&_auxvar _q1 
        %if &CNR=Y %then _vsk&_auxvar _vuk&_auxvar _q0 _ph; _gk&_auxvar
        %if &_strtgi=6 and &MLEVEL=2 %then _qi&_auxvar; 
        %if &WKOUT ne %then &IDENT _kvikt; _num&_auxvar _ak _id&_auxvar _ide;
  run;

 %if &__ic=1 %then %do;
  %let _niter=%eval(&_niter+1);
  %put; %put *****CLAN*****;
  %put *** Iteration number: &_niter ***;
  %put Max Derivative: &_maxd;
  %if &_U ne %then %do;
    %put N. of %SUBSTR(&_gvikt,2,%eval(%LENGTH(&_gvikt)-1)) > &_U:  &_antU;
    %if &_antU ne 0 %then %put Largest %SUBSTR(&_gvikt,2,%eval(%LENGTH(&_gvikt)-1)):     &_maxU;
  %end;
  %if &_L ne %then %do;
    %put N. of %SUBSTR(&_gvikt,2,%eval(%LENGTH(&_gvikt)-1)) < &_L:  &_antL;
    %if &_antL ne 0 %then %put Smallest %SUBSTR(&_gvikt,2,%eval(%LENGTH(&_gvikt)-1)):    &_minL;
  %end;
  %if &_niter <= &MAXITER %then %goto _AUXV4;
  %else %do;
   %put; %put *****CLAN*****;
   %put *********No convergence***********;
   %let __ic=0;
  %end;
 %end;
 %else %if &_niter >0 %then %do;
  %let _niter=%eval(&_niter+1);
  %put; %put *****CLAN*****;
  %put *** Iteration number: &_niter ***;
  %put *********CONVERGENCE***********;
  %put Max Derivative: &_maxd;
  %let _niter=0;
 %end;
 %_AUXV4:
%mend _AUXV4;

%macro _exists(_data,_xist) /store;
   DATA _NULL_;
    if 0 then set &_data;
    stop;
   RUN;
   %if &syserr=0 %then %let &_xist=1;
%MEND _exists;
%macro _in(_parm) /store;      /*_parm =fcol eller frow*/
%local _i _b _c _d1 _d2 _j _strng;
%let _i=%index(&_parm,%str(  ));
%do %while(&_i^=0);  /* rensa bort multipla blanka från _parm*/
 %let _b=%qsubstr(&_parm,1,&_i-1);
 %let _parm=&_b%qsubstr(&_parm,&_i+1);
 %let _i=%index(&_parm,%str(  ));
%end;
%let _i=%index(&_parm,%str( -));      /* rensa bort ' -' från _parm*/
%do %while(&_i^=0);
 %let _b=%qsubstr(&_parm,1,&_i-1);
 %let _parm=&_b%qsubstr(&_parm,&_i+1);
 %let _i=%index(&_parm,%str( -));
%end;
%let _i=%index(&_parm,%str(- ));     /* rensa bort '- ' blanka från _parm*/
%do %while(&_i^=0);
 %let _b=%qsubstr(&_parm,1,&_i);
 %let _parm=&_b%qsubstr(&_parm,&_i+2);
 %let _i=%index(&_parm,%str(- ));
%end;
%let _strng=;
%let _i=1;
%let _b=%qscan(&_parm,&_i,%str( ));
%do %while (&_b^=);
 %let _c=%index(&_b,-);
 %if &_c ne 0 %then %do;  /*expandera t ex 2-5 till 2,3,4,5 */
  %let _d1=%substr(&_b,1,&_c-1);
  %let _d2=%substr(&_b,&_c+1);
  %do _j=&_d1 %to &_d2;
   %let _strng=&_strng,&_j; /* byt alla  blanka mot ,*/
  %end;
 %end;
 %else %let _strng=&_strng,&_b;
 %let _i=%eval(&_i+1);
 %let _b=%qscan(&_parm,&_i,%str( ));
%end;
%substr(%quote(&_strng),2)
%mend _in;
%macro _ssasign(a,idx,b) /store;
%local _i _r _a;
%if &idx=1 %then %do;
  %let _r=&b;
  %goto L1;
%end;
%else %do;
  %let _r=;
  %do _i=1 %to %eval(&idx-1);
    %let _r=&_r %scan(&a,&_i,%str( ));
  %end;
  %let _r=&_r &b;
%end;
%L1: %let _i=%eval(&idx+1);
%let _a=%scan(&a,&_i,%str( ));
%do %while(&_a^=);
  %let _r=&_r &_a;
  %let _i=%eval(&_i+1);
  %let _a=%scan(&a,&_i,%str( ));
%end;
%SLUT: &_r
%mend _ssasign;
%macro _STRGI13 /store;
 if _eof then do;
   link _summera;
   _sista=1;
 end;
 else link _summera;
 if last.&STRATID then do;
   if &NRESP <2 then _qv1=0; else
    %if &_ppps=0 %then _qv1=((&NPOP*&NPOP/&NRESP)-&NPOP)/(&NRESP-1);
    %else _qv1=&NRESP/(&NRESP-1);;
   do _i=1 to %eval(&_size*&_maxut);
    if _zss(_i) gt 0 then do;
     if _qv1 ne 0 then
      _v(_i)+_qv1*(_zss(_i)-_zs(_i)*_zs(_i)/%if &_ppps=0 %then &NRESP; %else _cz;);
     _zss(_i)=0;
     _zs(_i)=0;
    end;
   end;
   _cz=0;
 end;
 if _sista=0 then return;
 _SUMMERA:
  %let ind=2;
  %let _ut=0;
  %let _ntot=0;
  %let _sntot=0;
  %let _skolnr=0;
  _rk=0;
  do _irad=1 to &maxrow;
  do _ikol=1 to &maxcol;
   _rk+1;
   %FUNCTION(_irad,_ikol)
   if _sista then output;
  end;
  end;
  return;
%mend _STRGI13;
%macro _STRGI24 /store;
 if _eof then do;
   link _summera;
   _sista=1;
 end;
 else link _summera;
  if last.&STRATID or last.&GROUPID then do;
   if &NRESP <2 or &NSAMP <2 then _q1=0; else
    _q1=&NPOP*(&NPOP-1)*(&NGROUP/&NSAMP)*
         ((&NGROUP-1)/(&NSAMP-1)-(&NRESP-1)/(&NPOP-1))/(&NRESP*(&NRESP-1));
   do _i=1 to %eval(&_size*&_maxut);
     if _zss(_i) gt 0 then do;
      if _q1 ne 0 then
       _v(_i)+_q1*(_zss(_i)-(_zs(_i)*_zs(_i)/&NRESP));
      _gs(_i)+_zs(_i)*&NGROUP/&NRESP;
      _gss(_i)+&NGROUP*_zs(_i)/&NRESP*_zs(_i)/&NRESP;
      _zss(_i)=0;
      _zs(_i)=0;
     end;
   end;
  end;
 if last.&STRATID then do;
  if &NSAMP < 2 then _q2=0;
  else _q2=(&NPOP-1)/(&NSAMP-1)*(&NPOP/&NSAMP-1);
  do _i=1 to %eval(&_size*&_maxut);
    if _gss(_i) gt 0 then do;
      if _q2 ne 0 then
       _v(_i)+_q2*(_gss(_i)-(_gs(_i)*_gs(_i)/&NSAMP));
      _gss(_i)=0;
      _gs(_i)=0;
    end;
  end;
 end;
 if _sista=0 then return;
 _SUMMERA:
  %let ind=2;
  %let _ut=0;
  %let _ntot=0;
  %let _sntot=0;
  %let _skolnr=0;
  _rk=0;
  do _irad=1 to &maxrow;
  do _ikol=1 to &maxcol;
   _rk+1;
   %FUNCTION(_irad,_ikol)
   if _sista then output dut;
  end;
  end;
 return;
%mend _STRGI24;

%macro _STRGI56 /store;
 if _eof then do;
   link _summera;
   _sista=1;
 end;
 else link _summera;
  if last.&STRATID then do;
   if &NSAMP <2 then _qv1=0; else
    %if &_ppps=0 %then _qv1=&NPOP*(&NPOP/&NSAMP-1)/(&NSAMP-1);
    %else _qv1=&NSAMP/(&NSAMP-1);; 
    do _i=1 to %eval(&_size*&_maxut);
     if _qv1 ne 0 then
      _v(_i)+_qv1*(_zss(_i)-_zs(_i)*_zs(_i)/%if &_ppps=0 %then &NSAMP; %else _cz;);
     _v(_i)+_2zss(_i)%if &_ppps=0 %then *&NPOP*&NPOP/&NSAMP/&NSAMP;;
     _zss(_i)=0;
     _zs(_i)=0;
     _2zss(_i)=0;
   end;
   _cz=0;
  end;
 if _sista=0 then return;
 _SUMMERA:
  %let ind=2;
  %let _ut=0;
  %let _ntot=0;
  %let _sntot=0;
  %let _skolnr=0;
  _rk=0;
  do _irad=1 to &maxrow;
  do _ikol=1 to &maxcol;
   _rk+1;
   %FUNCTION(_irad,_ikol)
   if _sista then output dut;
  end;
  end;
 return;
%mend _STRGI56;

%macro ADD(_id,a,b) /store;
 %if &ind eq 2 %then %do;
  %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi=6 %then
  if last.&CLUSTID or last.&STRATID or _sista  then;
  do;
  %if %QUOTE(&b) ne %then %do;
   _p&_id=(_p&a)+(_p&b);
   __&_id=(__&a)+(__&b);
   %if &CNR=Y %then %do;
    _1&_id=(_1&a)+(_1&b);
    _2&_id=(_2&a)+(_2&b);
    %if &_nauxvar>1 %then %do;
     _3&_id=(_3&a)+(_3&b);
     _4&_id=(_4&a)+(_4&b);
    %end;
   %end;
  %end;
  %else %do;
   _p&_id=_p&a;
   __&_id=__&a;
   %if &CNR=Y %then %do;
    _1&_id=(_1&a);
    _2&_id=(_2&a);
    %if &_nauxvar>1 %then %do;
     _3&_id=(_3&a);
     _4&_id=(_4&a);
    %end;
   %end;
  %end;
 end;
 %end;
%mend ADD;
%macro AUXVAR   (
        DATAX     =       , /* Dataset med marginalerna               */
        WKIN      =       , /* Vikter Wk (om kalibrering skett)       */
        QK        =       , /* Vikter Qk                              */
        QI        =       , /* Vikter Qi när MLEVEL=1	              */
        MLEVEL    = 2     , /* Modellnivå 1=kluster, 2=element        */
        PCT       = NO    , /* =YES om marginalerna är uttryckta i %  */
        EFFPOP    =       , /* Populationsstorlek (om PCT=YES)        */

        WKOUT     =       , /* Namn på Wk-vikten om den skall sparas  */
        DATAWKUT  =       , /* Namn på utdatset för WKOUT             */
        IDENT     =       , /* Variabelnamn för identifikation        */

        BLOCK     =       , /* Variabelnamn för blockvariabel         */
        MODELID   = __#   , /* Identitet för hjälpinformationen       */

        L         =       ,
        U         =       ,
        MAXITER   = 20
        ) /store;

%if &ind eq 0 %then
%do;
 run; %if &NOTES=Y %then %do; options notes; %end;
 %let _auxvar=%eval(&_auxvar+1);
 %let _gntot&_auxvar=0;
 %if &_auxvar=1 %then %do;
   %let _xmax=;%let _xxmax=;%let _mdlvl=;
   %let _mdlid=;%let _nblk=;%let _diag=;%let _csets=;
   %if &_strtgi=6 and &MLEVEL=2 and &RTOU=Y %then %do;
    %let _xxmax2=;%let _diag2=; %let _csets2=;
   %end;
 %end;
 %if &_auxvar>9 %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. Number of AUXVARs>9!;
   %let _fel=1;
 %end;
 %if &WKOUT ne %then %do;
  %if &DATAWKUT eq %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. No outfile name (DATAWKUT)!;
   %let _fel=1;
  %end;
  %if &IDENT eq %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. Identification variabel name missing (IDENT)!;
   %let _fel=1;
  %end;
  %if %index(&DATAWKUT,.) ne 0 %then %do;
   %let _base=%scan(&DATAWKUT,1,.);
   PROC CONTENTS noprint data=&_base.._all_;
   run; 
   %if &syserr ne 0 %then %do;
    %put; %put ******CLAN******;
    %put E R R O R.. Library &_base does not exist!;
    %let _fel=1;
   %end;
  %end;
 %end;
 %let _useold=0;
 %if %quote(&DATAX)= %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. DATAX must refer to a SAS data set!;
   %let _fel=1;
 %end;
 %else %do;
  %_exists(&DATAX,_useold)
  %if &_useold=1 %then %let _useold=2;
 %end;
 %if &_useold=1 and &_fel=0 %then %goto SLUT;

 %if %quote(&WKIN)=  %then %let _calmar=0; %else %do;
  %let _calmar=1;
  %if &CNR=Y %then %do;
   %let _calmar=0;
   %put; %put ******CLAN******;
   %put NOTE.. WKIN is not allowed when CNR=Y, WKIN will be ignored!;
  %end;
 %end;
 %if %quote(&DATAX) ne and &_useold ne 2 %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. &DATAX does not exist!;
  %let _fel=1;
 %end;

 %if (&_strtgi=3 or &_strtgi=4 or (&_strtgi=6 and &RTOU=Y)) and &MLEVEL= %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. Model level (MLEVEL) missing!;
  %let _fel=1;
 %end;
 %if &PCT= %then %let PCT=NO;
 %if &EFFPOP= and %upcase(%substr(&PCT,1,1))=Y %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. PCT=YES and population size (EFFPOP) is missing!;
  %let _fel=1;
 %end;
 %if &BLOCK ne and %upcase(%substr(&PCT,1,1))=Y %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. PCT is not allowed when a BLOCK variable exists!;
  %let _fel=1;
 %end;
 %if &MODELID= %then %let MODELID=__#;
 %if %INDEX(&_mdlid,&MODELID) ne 0 %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. &MODELID is already used!;
  %let _fel=1;
 %end;
 %else %let _mdlid=&_mdlid &MODELID;
 %if &L ne and &U ne and &L>&U %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. L>U!;
  %let _fel=1;
 %end;
 %if &_fel=1 %then %goto AUXEND;
 
 %if &MAXITER= %then %let MAXITER=0;
 %let __mdlvl=&MLEVEL;
 %if &_strtgi=6 and &RTOU=N and &MLEVEL ne 1 %then %do;
  %put; %put ******CLAN******;
  %put NOTE.. Model level 1 (=cluster) is used!;
  %let __mdlvl=1;
 %end; 
 %let _qk=1;
 %if %QUOTE(&QK) ne %then %let _qk=%QUOTE(&QK);
 %if &_strtgi=6 and &MLEVEL=2 %then %do;
  %let _qi=1;
  %if %QUOTE(&QI) ne %then %let _qi=%QUOTE(&QI);
 %end;
 %if &_strtgi=1 or &_strtgi=2 or &_strtgi=5 %then %let __mdlvl=2;
 
 %_AUXV1 /* skapa XV (och XV2 om strategi=6 och mlevel=2) */
 %if &_fel>0 %then %goto AUXEND;
 
 %if &_strtgi<=4 %then %do; /* Strategi 1-4 */
  %let __ic=0; %let _niter=0; %let __xxmax=%SCAN(&_xxmax,&_auxvar);
  %let __nblk=%SCAN(&_nblk,&_auxvar); %let _xxsize=%eval(&__nblk*&__xxmax);
  %let __diag=%scan(&_diag,&_auxvar); %let __csets=%SCAN(&_csets,&_auxvar);
  %let __xmax=%SCAN(&_xmax,&_auxvar);
  %if &_calmar=0 %then %let _sets=&_sets __TRX; 
  
 %IC1:
  %if &_calmar=0 %then %do;
   %_AUXV2(_XDAT=_XV,_TDAT=__TRX, _TNAME=_tr, _WHERE=, _XVIKT=_gk&_auxvar)
  %end;

  %_AUXV3(_XDAT=_XV,_CDAT=_C, _CNAME=_C, _WHERE=, _DIAG=&__diag, _XXVIKT=_qk&_auxvar)
  %if &__ic=0 and &_niter>0 %then %goto IC0;  
  %let _gvikt=_gk&_auxvar;
  %if &_calmar=0 %then %do; /*2003-11-04 */
   %_AUXV4(_XDAT=_XV,_CDAT=_C, _CNAME=_C,_T1=__TUX, _T2=__TRX,
          _RSPNS=1, _DIAG=&__diag, _GXVIKT=_qk&_auxvar,_U=&U,_L=&L)
  %end; /* 2003-11-04 */
  %if &_niter>0 %then %goto IC1;         
 %end;
 
 %if &_strtgi=5 or (&_strtgi=6 and (&MLEVEL=1 or &RTOU=N)) %then %do;
  /* Strategi 5 o 6(-)*/
  %let __ic=0; %let _niter=0; %let __xxmax=%SCAN(&_xxmax,&_auxvar);
  %let __nblk=%SCAN(&_nblk,&_auxvar); %let _xxsize=%eval(&__nblk*&__xxmax);
  %let __diag=%scan(&_diag,&_auxvar); %let __csets=%SCAN(&_csets,&_auxvar);
  %let __xmax=%SCAN(&_xmax,&_auxvar); %let __whr=;
  %let _sets=&_sets __TRX;  
  %if &SET=S %then %do;
   %let __whr=(WHERE=(_ph=2)); %let _sets=&_sets __TSX __TRX;
   %_AUXV2(_XDAT=_XV,_TDAT=__TSX, _TNAME=_ts, _WHERE=)
  %end;
  %if &RTOU=N %then %let _gvikt=_vsk&_auxvar; %else %let _gvikt=_vuk&_auxvar;
 %IC2:
  %_AUXV2(_XDAT=_XV,_TDAT=__TRX, _TNAME=_tr, _WHERE=&__whr, _XVIKT=&_gvikt)

  %_AUXV3(_XDAT=_XV,_CDAT=_C, _CNAME=_C, _WHERE=&__whr, _DIAG=&__diag,
          _XXVIKT=_qk&_auxvar)
 
  %let _gvikt=_vsk&_auxvar;
  %if &RTOU=N or &_niter=0 %then %do;
   %let __u=; %let __l=;
   %if &RTOU=N %then %do; %let __u=&U; %let __l=&L; %end;
   %_AUXV4(_XDAT=_XV, _CDAT=_C, _CNAME=_C, _T1=__TSX, _T2=__TRX,
           _RSPNS=_ph=2, _DIAG=&__diag, _GXVIKT=_qk&_auxvar,_U=&__u,_L=&__l)
   %if &__ic=1 %then %goto IC2;  
  %end;
  %if &RTOU=Y %then %do;
   %let _gvikt=_vuk&_auxvar;
   %_AUXV4(_XDAT=_XV, _CDAT=_C, _CNAME=_C, _T1=__TUX, _T2=__TRX,
           _RSPNS=_ph=2, _DIAG=&__diag, _GXVIKT=_qk&_auxvar, _U=&U, _L=&L)
   %if &__ic=1 %then %goto IC2;
  %end;

  %_AUXV3(_XDAT=_XV,_CDAT=_C, _CNAME=_C, _WHERE=&__whr, _DIAG=&__diag,
          _XXVIKT=_qk&_auxvar*_vsk&_auxvar)

  %if &RTOU=Y %then %do;
   %if &SET=R %then %do; %let _sets=&_sets __TVX;
    %_AUXV2(_XDAT=_XV,_TDAT=__TVX, _TNAME=_tv, _WHERE=, _XVIKT=_vsk&_auxvar)
    %let _gvikt=_gk&_auxvar;
    %_AUXV4(_XDAT=_XV, _CDAT=_C, _CNAME=_C, _T1=__TUX, _T2=__TVX,
            _RSPNS=1, _DIAG=&__diag, _GXVIKT=_qk&_auxvar, _U=, _L=)
   %end;
   %if &SET=S %then %do;
    %_AUXV3(_XDAT=_XV,_CDAT=_C3, _CNAME=_C3, _WHERE=, _DIAG=&__diag,
            _XXVIKT=_qk&_auxvar)
    %let _sets=&_sets _C3&_auxvar._;
    %let _gvikt=_gk&_auxvar;
    %_AUXV4(_XDAT=_XV, _CDAT=_C3, _CNAME=_C3, _T1=__TUX, _T2=__TSX,
           _RSPNS=1, _DIAG=&__diag, _GXVIKT=_qk&_auxvar, _U=, _L=)  
   %end;
  %end;
 %end;
 
 %if &_strtgi=6 and &MLEVEL=2 and &RTOU=Y %then %do; /* Strategi 6 (-) */
  %let __ic=0; %let _niter=0; %let __xxmax=%SCAN(&_xxmax2,&_auxvar);
  %let __nblk=%SCAN(&_nblk,&_auxvar); %let _xxsize=%eval(&__nblk*&__xxmax);
  %let __diag=%scan(&_diag2,&_auxvar); %let __csets=%SCAN(&_csets2,&_auxvar);
  %let __xmax=%SCAN(&_xmax,&_auxvar); %let __whr=;
  %if &SET=S %then %do;
   %let __whr=(WHERE=(_ph=2)); %let _sets=&_sets __TSX __TRX;
   %_AUXV2(_XDAT=_XV2,_TDAT=__TSX, _TNAME=_ts, _WHERE=)
  %end;
  %_AUXV2(_XDAT=_XV2,_TDAT=__TRX, _TNAME=_tr, _WHERE=&__whr, _XVIKT=_vsk&_auxvar)

  %_AUXV3(_XDAT=_XV2,_CDAT=_C, _CNAME=_C, _WHERE=&__whr, _DIAG=&__diag,
          _XXVIKT=_qi&_auxvar)
  
  %let _gvikt=_vsk&_auxvar;
   %_AUXV4(_XDAT=_XV2, _CDAT=_C, _CNAME=_C, _T1=__TSX, _T2=__TRX,
           _RSPNS=_ph=2, _DIAG=&__diag, _GXVIKT=_qi&_auxvar,_U=,_L=)
  %_AUXV3(_XDAT=_XV2,_CDAT=_C2, _CNAME=_C2, _WHERE=&__whr, _DIAG=&__diag,
          _XXVIKT=_qi&_auxvar*_vsk&_auxvar)
          
  /* matcha på vsk på XV */
  DATA __VSI; %let _sets=&_sets __VSI;
   set _XV2&_auxvar(keep=&STRATID &GROUPID &CLUSTID _vsk&_auxvar);
    by &STRATID &GROUPID &CLUSTID;
   if first.&CLUSTID;
  RUN;
  DATA _XV&_auxvar;
   merge _XV&_auxvar(drop=_vsk&_auxvar) __VSI;
    by &STRATID &GROUPID &CLUSTID;
  RUN;
          
  %let __xxmax=%SCAN(&_xxmax,&_auxvar); %let _xxsize=%eval(&__nblk*&__xxmax);
  %let __diag=%scan(&_diag,&_auxvar); %let __csets=%SCAN(&_csets,&_auxvar); 
  %IC3:
  %if &_niter>0 %then %do;
   %_AUXV2(_XDAT=_XV,_TDAT=__TRX, _TNAME=_tr, _WHERE=&__whr, _XVIKT=_vuk&_auxvar)
  %end;      
  %_AUXV3(_XDAT=_XV,_CDAT=_C, _CNAME=_C, _WHERE=&__whr, _DIAG=&__diag,
          _XXVIKT=_qk&_auxvar)        
  %let _gvikt=_vuk&_auxvar; 
  %_AUXV4(_XDAT=_XV, _CDAT=_C, _CNAME=_C, _T1=__TUX, _T2=__TRX,
           _RSPNS=_ph=2, _DIAG=&__diag, _GXVIKT=_qk&_auxvar, _U=&U, _L=&L)
  %if &__ic=1 %then %goto IC3;
  %_AUXV3(_XDAT=_XV,_CDAT=_C, _CNAME=_C, _WHERE=&__whr, _DIAG=&__diag,
          _XXVIKT=_qk&_auxvar*_vsk&_auxvar)

  %if &SET=R %then %do; %let _sets=&_sets __TVX;
   %_AUXV2(_XDAT=_XV,_TDAT=__TVX, _TNAME=_tv, _WHERE=, _XVIKT=_vsk&_auxvar)
   %let _gvikt=_gk&_auxvar;
   %_AUXV4(_XDAT=_XV, _CDAT=_C, _CNAME=_C, _T1=__TUX, _T2=__TVX,
           _RSPNS=1, _DIAG=&__diag, _GXVIKT=_qk&_auxvar, _U=, _L=)
  %end;
  
  %if &SET=S %then %do; %let _sets=&_sets _C3&_auxvar._;
   %_AUXV3(_XDAT=_XV,_CDAT=_C3, _CNAME=_C3, _WHERE=, _DIAG=&__diag,
           _XXVIKT=_qk&_auxvar)

   %let _gvikt=_gk&_auxvar;
   %_AUXV4(_XDAT=_XV, _CDAT=_C3, _CNAME=_C3, _T1=__TUX, _T2=__TSX,
           _RSPNS=1, _DIAG=&__diag, _GXVIKT=_qk&_auxvar, _U=, _L=)  
  %end;
 %end;
 %IC0:
 
 PROC SORT DATA=_XV&_auxvar;BY &STRATID &GROUPID &CLUSTID _id&_auxvar; RUN;
 %if &_strtgi=6 and &MLEVEL=2 and &RTOU=Y %then %do;
  PROC SORT DATA=_XV2&_auxvar;BY &STRATID &GROUPID &CLUSTID _id&_auxvar; RUN;
 %end;
 
 %SLUT:
  %if &_sets ne %then %do;
   PROC DATASETS nolist; delete &_sets; quit;
   %let _sets=;
  %end;

 %if &WKOUT ne %then %do;
  DATA _tmp(keep=&wkout &ident);  %let _sets=&_sets _tmp;
   set _XV&_auxvar; by _ide NOTSORTED;
   if first._ide;
   %if &CNR=N %then &wkout=_gk&_auxvar*_q1*_kvikt;
   	%else %if &RTOU=Y %then &wkout=_vuk&_auxvar*_q0*_kvikt;
         	%else &wkout=_vsk&_auxvar*_q0*_kvikt;;   
  RUN;
  %let _exist=0;
  %if %index(&DATAWKUT,.) ne 0 %then %do;
   %let _base=%scan(&DATAWKUT,1,.);
   %let _table=%scan(&DATAWKUT,2,.);
  %end;
  %else %do;
   %let _base=work;
   %let _table=&DATAWKUT;
  %end;
  PROC CONTENTS noprint data=&_base.._all_ out=_membr;  %let _sets=&_sets _membr;
  DATA _NULL_;
   set _membr;
   if memname="%upcase(&_table)" then call symput('_exist','1');
  RUN;
  %if &_exist=1 %then %do;
   PROC SORT DATA=_tmp;BY &IDENT;
   PROC SORT DATA=&DATAWKUT; BY &IDENT;
   DATA &DATAWKUT;
    merge &DATAWKUT _tmp;
     BY &IDENT;
   RUN;
  %end;
  %else %do;
   DATA &DATAWKUT;
    set _tmp;
   RUN;
  %end;
 %end;
  
%AUXEND:
 %if &_sets ne %then %do;
  PROC DATASETS nolist; delete &_sets; quit;
  %let _sets=;
 %end;
 options nonotes;
 DATA _NULL_;
%end;
%mend AUXVAR;

%macro CLAN  (  DATA=,
                STRATEGI=, SAMPUNIT=, RHG=,
                STRATUM=, STRATID=,
                GRUPP=, GROUPID=, GROUP=,
                NSVAR=, NRESP=,
                NPOP=,
                NURV=, NSAMP=,
                NGRUPP=, NGROUP=,
                CLUSTID=,
                MAXRAD=, MAXROW=,
                MAXKOL=, MAXCOL=,
                KVIKT=, WEIGHT=,
                NCHECK=YES,
		NOTES=YES,
		
		CNR=NO,		/* Calibration for NonResponse */
		RTOU=YES,	/* kalibrering r->U (YES) eller r->s (NO) */
		SET=R,		/* DATA innehåller sample set, S or response set, R*/
		RESPONSE=1,	/* Anger vilka obs som tillhör responsmängden r om SET=R*/
		
		LAMBDA=		/* Variabel med lambda- (pi-) värdet. Vid ParetoPiPS*/
            ) /store;
/*options nomprint nomlogic nomfile;*/
 %let _ver=3.1.3;
 %put; %put ******CLAN******;
 %put CLAN97 version &_ver;
 %local _skolnr _xmax _xxmax _mdlvl _mdlid _nblk _diag _csets __block _gntot1 _gntot2
	_gntot3 _gntot4 _gntot5 _gntot6 _gntot7 _gntot8 _gntot9 _namn _sv _keep
	_xxmax2 _diag2 _csets2;
 %let _notes=%sysfunc(getoption(notes,keyword));	 
 %if &NOTES= %then %if %upcase(&_notes)=NOTES %then %let NOTES=YES;%else %let NOTES=NO;
 %let NOTES=%upcase(%substr(&NOTES,1,1));
 %if &NOTES=Y %then %do; options notes; %end;
   %else %do; options nonotes; %end;
 %let ind=0; %let _sets=; %let _ds0=0;
 %if %quote(&DATA)= %then %do; %let DATA=_ds0; %let _ds0=1; %end;
 %let _tmp=0; %let _fel=0;
 %_exists(&DATA,_tmp)
 %if &_tmp=0 %then %do;
  %put; %put ******CLAN******;
  %put E R R O R  Data set &DATA does NOT EXISTS!!;
  %let _fel=1;
 %end;
 %if &STRATID= %then %let STRATID=&stratum;
 %if &GROUPID= %then %let GROUPID=&group;
 %if &GROUPID= %then %let GROUPID=&grupp;
 %if &NRESP= %then %let NRESP=&nsvar;
 %if &NSAMP= %then %let NSAMP=&nurv;
 %if &NGROUP= %then %let NGROUP=&ngrupp;
 %if &MAXROW= %then %let MAXROW=&maxrad;
 %if &MAXCOL= %then %let MAXCOL=&maxkol;
 %if %QUOTE(&WEIGHT)= %then %let WEIGHT=&kvikt;
 %if &NCHECK= %then %let NCHECK=NO;
 %if &CNR= %then %let CNR=N;
 %if &LAMBDA= %then %let _ppps=0; %else %let _ppps=1;
 %let CNR=%UPCASE(%SUBSTR(&CNR,1,1));
 %if &SAMPUNIT= or &RHG= %then %do;
  %if &STRATEGI= %then %do;
    %if &SAMPUNIT= %then %do;
     %let SAMPUNIT=E;
     %put; %put ******CLAN******;
     %put NOTE.. SAMPUNIT is missing, Element is assumed;
    %end;
    %if &RHG= %then %do;
     %let RHG=NO;
     %if &CNR=N and &_ppps=0 %then %do;
      %put; %put ******CLAN******;
      %put NOTE.. RHG is missing, NO is assumed;
     %end;
    %end;
  %end;
  %else %do;
    %if &SAMPUNIT= %then %do;
      %if &strategi=3 or &strategi=4 %then %let SAMPUNIT=C;
      %else %let SAMPUNIT=E;
    %end;
    %if &RHG= %then %do;
      %if (&strategi=2 or &strategi=4) %then %let RHG=YES;
      %else %let RHG=NO;
    %end;
  %end;
 %end;
 %let SAMPUNIT=%UPCASE(%substr(&SAMPUNIT,1,1)); %let RHG=%UPCASE(%substr(&RHG,1,1));
 %if &SAMPUNIT=E %then %if &RHG=N %then %let _strtgi=1;
 %else %let _strtgi=2;
 %if &SAMPUNIT=C %then %if &RHG=N %then %let _strtgi=3;
 %else %let _strtgi=4;
 
 %if &_ppps=1 and &RHG=Y %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. No RHG:s are allowed when PiPS is used!;
   %let _fel=1;
 %end;
 %if &CNR=Y %then %do;
  %if &RHG=Y %then %do; 
    %put; %put ******CLAN******;
    %put E R R O R.. No RHG:s are allowed when CNR=Yes!;
    %let _fel=1;
  %end;
  %if &NSAMP= %then %do;
    %put; %put ******CLAN******;
    %put E R R O R.. NSAMP is MISSING (and CNR=Yes)!;
    %let _fel=1;
  %end;
  %let RTOU=%UPCASE(%SUBSTR(&RTOU,1,1));
  %if not (&RTOU=Y or &RTOU=N) %then %do;
    %put; %put ******CLAN******;
    %put E R R O R.. RTOU is MISSING (RTOU must be Yes or No)!;
    %let _fel=1;
  %end;
  %let SET=%UPCASE(%SUBSTR(&SET,1,1));
  %if not (&SET=S or &SET=R) %then %do;
    %put; %put ******CLAN******;
    %put E R R O R.. SET is MISSING (SET must be S or R)!;
    %let _fel=1;
  %end;
  %if &SET=S and %QUOTE(&RESPONSE)= %then %do;
    %put; %put ******CLAN******;
    %put E R R O R..  RESPONSE is MISSING!;
    %let _fel=1;
  %end;
  %let _strtgi=5;
  %if %UPCASE(&SAMPUNIT)=C %then %let _strtgi=6;
  %let _vskneg=0;
 %end;
 %else %do;
  %let RTOU=Y;
  %let RESPONSE=1;
  %let SET=R;
 %end;
  
 %if &STRATID eq %then %do;
  %put; %put ******CLAN******;
  %put NOTE.. STRATID  is missing, no stratfication is assumed!;
  %let STRATID=_ett;
 %end;
 %if &npop eq and &_ppps=0 %then %do;
  %put; %put ******CLAN******;
  %put E R R O R..  NPOP is missing!;
  %let _fel=1;
 %end;
 %if not (&_strtgi=5 or &_strtgi=6) and &nresp eq %then %do;
  %put; %put ******CLAN******;
  %put E R R O R..  NRESP is missing!;
  %let _fel=1;
 %end;
 %if &maxcol eq %then %do;
  %put; %put ******CLAN******;
  %put E R R O R..  MAXCOL is missing!;
  %let _fel=1;
 %end;
 %if &maxrow eq %then %do;
  %put; %put ******CLAN******;
  %put E R R O R..  MAXROW is missing!;
  %let _fel=1;
 %end;
 %if (&_strtgi eq 2 or &_strtgi eq 4) %then %do;
  %if &GROUPID eq %then %do;
   %put; %put ******CLAN******;
   %put WARNING.. GROUPID is missing, no groups are assumed !;
   %let GROUPID=&STRATID; %let NGROUP=&NSAMP;
  %end;
  %if &NGROUP eq %then %do;
   %put; %put ******CLAN******;
   %put E R R O R..  NGROUP is missing!;
   %let _fel=1;
  %end;
  %if &NSAMP eq %then %do;
   %put; %put ******CLAN******;
   %put E R R O R..  NSAMP is missing!;
   %let _fel=1;
  %end;  
 %end;
 %if (&_strtgi eq 3 or &_strtgi eq 4 or &_strtgi eq 6) and &CLUSTID eq %then %do;
  %put; %put ******CLAN******;
  %put E R R O R..  CLUSTID is missing!;
  %let _fel=1;
 %end;
 %if &_ppps=1 and &CNR=N and &NSAMP= %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. NSAMP is missing (PiPS)!;
   %let _fel=1;
 %end;
 %if %quote(&WEIGHT)= %then %let WEIGHT=1;
 %let maxkol=&MAXCOL; %let maxrad=&MAXROW; 
 %let NCHECK=%upcase(%substr(&NCHECK,1,1));
 %if &_fel eq 1 %then %goto SLUTA;
 %if &_ds0 ^=1 %then %do;
  data _ds0;
   set &data;
   _ett=1;
   _IDE+1; /* identifiera alla poster */
   %if &_ppps=1 %then %do;
    if &LAMBDA>1 or &LAMBDA<=0 then do;
     put; put "******CLAN******";
     put "E R R O R .. LAMBDA<=0 OR LAMBDA>1, LAMBDA=" &LAMBDA " , OBS NR " _IDE;
     call symput('_fel','1');
    end;
   %end;
  run;
 %end;
 %if &_fel eq 1 %then %goto SLUTA;
 %if &_strtgi=1 or &_strtgi=3 or &_strtgi=5 or &_strtgi=6 %then %let GROUPID=;
 %if &_strtgi=1 or &_strtgi=2 or &_strtgi=5 %then %let CLUSTID=;

 %let _size=%eval(&MAXROW*&MAXCOL);
 %let _ut=0;
 %let _ntot=0;
 %let _summa=0;
 %let _sntot=0;
 %let _sorted=0;
 %let _bmax=7500;
 %let _auxvar=0;

 %if &NOTES=Y %then %do; options nonotes; %end;
 DATA _NULL_;
  %FUNCTION(0,0)
  ;
 RUN;
 %if &NOTES=Y %then %do; options notes; %end;
 %if &_ut=0 or &_ntot=0 %then %do;
  %put; %put ******CLAN******;
  %put NOTE.. No estimates calculated;
  %let _fel=2; 
 %end;
 %if &syserr ne 0 and &syserr ne 4 %then %let _fel=1;
 %if &CNR=Y %then %do;
  %if &_auxvar=0 %then %do;
   %put; %put ******CLAN******;
   %put E R R O R.. CNR=YES and no AUXVAR in FUNCTION!;
   %let _fel=1;
  %end;
  %if &_auxvar>1 and &_vskneg=1 %then %do;
   %put; %put ******CLAN******;
   %put WARNING.. CNR=YES, N. of AUXVAR > 1 and at least one vsk < 0.;
   %put           This may give incorrect variance estimates!;
  %end;
 %end;
 %if &_fel ge 1 %then %goto SLUTA;
 
 %if &_sorted=0 %then %do;
   proc sort data=_ds0; by &STRATID &GROUPID &CLUSTID _ide;
 %end;

 %let _maxut=&_ut;
 %let _maxtot=%eval(&_ntot*&_size);
 %let _smaxtot=&_sntot;
 %let _nauxvar=&_auxvar;
 
 data _DS1(keep=__T)
 %let _sets=&_sets _DS1;
 %if &_nauxvar>0 %then %do _ia=1 %to &_nauxvar;
  %if &&_gntot&_ia>0 %then %do;
   %let __xmax=%scan(&_xmax,&_ia);
   %let __nblk=%scan(&_nblk,&_ia);
   %let __bsize=%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk);
   %let __bsets=%eval(&__bsize/&_bmax);
   %if %eval(&__bsets*&_bmax) lt &__bsize %then %let __bsets=%eval(&__bsets+1);
   %if &_ia=1 %then %let _bsets=&__bsets; %else %let _bsets=&_bsets &__bsets;
   %let _v1=&_bmax;
   %if &__bsize lt &_v1 %then %let _v1=&__bsize;
   _DB&_ia._(keep=_&_ia.B1-_&_ia.B&_v1)
   %if &_strtgi=6 and %scan(&_mdlvl,&_ia)=2 and &RTOU=Y %then
    _DB2&_ia._(keep=_2&_ia.B1-_2&_ia.B&_v1);
  %end;
 %end;;

 set _ds0%if &SET=S %then (where=(%QUOTE(&RESPONSE))); end=_eof;
 BY &STRATID &GROUPID &CLUSTID; 
 %if &_nauxvar>0 %then %do _ia=1 %to &_nauxvar;
  %if &&_gntot&_ia>0 %then %do;
   %let __mdlvl=%scan(&_mdlvl,&_ia);
   %let __nblk=%scan(&_nblk,&_ia);
   %let __xmax=%scan(&_xmax,&_ia);
   %let __xxmax=%scan(&_xxmax,&_ia);
   %if &__mdlvl=1 %then
    if first.&CLUSTID or first.&STRATID then;
   do; _i_&_ia=0;
    do until(last._id&_ia);
     set _XV&_ia%if &SET=S %then (where=(_ph=2));; 
      BY _id&_ia NOTSORTED;
     array _p&_ia._(&__xmax) _temporary_;
     array _x&_ia._(&__xmax) _temporary_;
     _i_&_ia+1;
     _p&_ia._(_i_&_ia)=_pos&_ia;
     _x&_ia._(_i_&_ia)=_val&_ia;
    end;
    _XA&_ia=(_num&_ia-1)*&__xmax;
   end;
   array __&_ia.B(%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk)) _temporary_;
   array _&_ia.btmp(%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk)) _temporary_;
   retain __&_ia.B _&_ia.btmp _i_&_ia _XA&_ia 0;
   
   %if &_strtgi=6 and &__mdlvl=2 and &RTOU=Y %then %do;
    if first.&CLUSTID or first.&STRATID then do;
     _2i_&_ia=0;
     do until(last._id&_ia);
      set _XV2&_ia%if &SET=S %then (where=(_ph=2));; 
       BY _id&_ia NOTSORTED;
      array _2p&_ia._(&__xmax) _temporary_;
      array _2x&_ia._(&__xmax) _temporary_;
      _2i_&_ia+1;
      _2p&_ia._(_2i_&_ia)=_pos&_ia;
      _2x&_ia._(_2i_&_ia)=_val&_ia;
     end;
    end;
    array __2&_ia.B(%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk)) _temporary_;
    array _2&_ia.btmp(%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk)) _temporary_;
    retain __2&_ia.B _2&_ia.btmp _2i_&_ia 0;
   %end;
   
   %let _gntot&_ia=0;
   %if &CNR=N %then __wk&_ia=_gk&_ia;
   %else %if &RTOU=Y %then __wk&_ia=_vuk&_ia; %else __wk&_ia=_vsk&_ia;;
   retain __wk&_ia 1;  
  %end;
 %end;

 array _T(&_maxtot) _temporary_;
 array _tmp(&_maxtot) _temporary_;
 retain _T 0;
 retain _tmp 0;
 retain _q1 0;
 %if &_strtgi=3 or &_strtgi=4 or &_strtgi=6 %then %do;
  array _cs(&_maxtot) _temporary_;
  retain _cs 0;
 %end;
 %if &_strtgi eq 2 or &_strtgi ge 4 %then %do;
  retain _q0 0;
 %end;

 %if &_strtgi eq 1 or &_strtgi eq 3 %then %do;
  %if &_ppps=0 %then %do;
   if first.&STRATID then do;
    if &NRESP>0 then _q1=&NPOP/&NRESP; else _q1=0;
    %if &NCHECK=Y %then %do;
    if _q1<1 then do;
     ERROR /'******CLAN******'/
     'E R R O R.. NRESP > NPOP or NRESP=0';
     CALL SYMPUT('_fel', '1');STOP;
    end;
    %end;
   end;
  %end;
  %else %do;
     %if &NCHECK=Y %then %do;
     if &NRESP>&NSAMP then do;
      ERROR /'******CLAN******'/
      'E R R O R.. NRESP > NSAMP';
      CALL SYMPUT('_fel','1');STOP;
     end;
     %end;
    if &NRESP>0 and &LAMBDA>0 then _q1=&NSAMP/&NRESP/&LAMBDA; else _q1=0;
  %end; 
 %end;

 %if &_strtgi eq 2 or &_strtgi ge 4 %then %do;
  %if &_ppps=0 %then %do;
   if first.&STRATID then do;
    if &NSAMP>0 then _q0=&NPOP/&NSAMP; else _q0=0;
   end;
   %if &_strtgi eq 2 or &_strtgi eq 4 %then %do;
   if first.&GROUPID or first.&STRATID then do;
    if &NRESP>0 then _q1=_q0*&NGROUP/&NRESP; else _q1=0;
    %if &NCHECK=Y %then %do;
     if _q1<1 then do;
      ERROR /'******CLAN******'/
      'E R R O R.. NSAMP > NPOP or NSAMP=0'
      /'and/or NRESP > NGROUP or NRESP=0'/;
      CALL SYMPUT('_fel', '1');STOP;
     end;
    %end;
    end;
   %end; 
  %end;
  %else %do;
    if &LAMBDA>0 then _q0=1/&LAMBDA;
    _q1=_q0;
  %end;
 %end;

 _rk=0;
 do _irad=1 to &MAXROW;
 do _ikol=1 to &MAXCOL;
  _rk+1;
 %let ind=1;
 %let _ut=0;
 %let _ntot=0;
  %FUNCTION(_irad,_ikol)
 end;
 end;
 %if &_strtgi eq 1 or &_strtgi eq 3 or &_strtgi=5 or &_strtgi=6 %then
 if last.&STRATID then do;
 %if &_strtgi eq 2 or &_strtgi eq 4 %then
 if last.&STRATID or last.&GROUPID then do;;
  do _rk=1 to &_maxtot;
   _T(_rk)+_tmp(_rk)%if &_ppps=0 %then %if &CNR=N %then *_q1;%else *_q0;;;
   _tmp(_rk)=0;
  end;
  %if &_nauxvar>0 %then %do _ia=1 %to &_nauxvar;
   %if &&_gntot&_ia>0 %then %do; 
    %let __nblk=%scan(&_nblk,&_ia);
    %let __xmax=%scan(&_xmax,&_ia);
    do _rk=1 to %eval(&_size*&&_gntot&_ia*&__xmax*&__nblk);
     __&_ia.B(_rk)+_&_ia.btmp(_rk)%if &_ppps=0 %then %if &CNR=N %then *_q1;%else *_q0;;;
     _&_ia.btmp(_rk)=0;
     %if &_strtgi=6 and %scan(&_mdlvl,&_ia)=2 and &RTOU=Y %then %do;
      __2&_ia.B(_rk)+_2&_ia.btmp(_rk)%if &_ppps=0 %then *_q0;;
      _2&_ia.btmp(_rk)=0;
     %end;
    end;
   %end;
  %end;
 end;

if _eof then do;
 do _i=1 to &_maxtot;
  __T=_T(_i); 
  output _DS1;
 end; 
 %if &_nauxvar>0 %then %do _ia=1 %to &_nauxvar;
  %if &&_gntot&_ia>0 %then %do;
   %let __csets=%scan(&_csets,&_ia);
   %let __nblk=%scan(&_nblk,&_ia);
   %let __xmax=%scan(&_xmax,&_ia);
   %let __diag=%scan(&_diag,&_ia);
   %let __xxmax=%scan(&_xxmax,&_ia);
   %let __xxsize=%eval(&__xxmax*&__nblk);
   %let _v1=&_bmax;
   %if &__xxsize<&_v1 %then %let _v1=&__xxsize;
   array _txx&_ia(&__xxsize) _temporary_;
   array _C&_ia._(&_v1);
   _k=0;
   do _i=1 to &__csets;
    set _C&_ia._;
    do _j=1 to &_v1;
     _k+1;
     if _k le &__xxsize then _txx&_ia(_k)=_C&_ia._(_j);
    end;
   end;
   do _ii=1 to %eval(&_size*&&_gntot&_ia);
    _kx=(_ii-1)*&__xmax*&__nblk;
    %if &__diag=1 %then %do;
     do _i=1 to %eval(&__nblk*&__xmax);
      __&_ia.B(_i+_kx)=_txx&_ia(_i)*__&_ia.B(_i+_kx);
     end;
    %end;
    %else %do;
     do _jj=1 to &__nblk;
      _XA=(_jj-1)*&__xmax;
      _XXA=(_jj-1)*&__xxmax;
      do _i=1 to &__xmax;
       _sum=0;
       do _j=1 to &__xmax;
        _k=max(_i,_j);
        _l=(_k*(_k-1))/2+min(_i,_j);
        _sum+_txx&_ia(_XXA+_l)*__&_ia.B(_XA+_j+_kx);
       end;
       _&_ia.btmp(_i)=_sum;
      end;
      do _i=1 to &__xmax;
       __&_ia.B(_XA+_i+_kx)=_&_ia.btmp(_i);
      end;
     end;
    %end;
   end;
   %let __bsets=%scan(&_bsets,&_ia);
   %let _v1=&_bmax;
   %let __bsize=%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk);
   %if &_v1 gt &__bsize %then %let _v1=&__bsize;
   array _&_ia.B(&_v1);
   _k=0;
   do _i=1 to &__bsets;
   do _j=1 to &_v1;
    _k+1;
    if _k le %eval(&_size*&&_gntot&_ia*&__xmax*&__nblk) then _&_ia.B(_j)=__&_ia.B(_k);
    else _&_ia.B(_j)=0;
   end;
   output _DB&_ia._;
   end;
   
   %if &_strtgi=6 and %scan(&_mdlvl,&_ia)=2 and &RTOU=Y %then %do;
    %let __csets2=%scan(&_csets2,&_ia);
    %let __diag=%scan(&_diag2,&_ia);
    %let __xxmax=%scan(&_xxmax2,&_ia);
    %let __xxsize=%eval(&__xxmax*&__nblk);
    %let _v1=&_bmax;
    %if &__xxsize<&_v1 %then %let _v1=&__xxsize;
    array _txx2&_ia(&__xxsize) _temporary_;
    array _C2&_ia._(&_v1);
    _k=0;
    do _i=1 to &__csets;
     set _C2&_ia._;
     do _j=1 to &_v1;
      _k+1;
      if _k le &__xxsize then _txx2&_ia(_k)=_C2&_ia._(_j);
     end;
    end;
    do _ii=1 to %eval(&_size*&&_gntot&_ia);
     _kx=(_ii-1)*&__xmax*&__nblk;
     %if &__diag=1 %then %do;
      do _i=1 to %eval(&__nblk*&__xmax);
       __2&_ia.B(_i+_kx)=_txx2&_ia(_i)*__2&_ia.B(_i+_kx);
      end;
     %end;
     %else %do;
      do _jj=1 to &__nblk;
       _XA=(_jj-1)*&__xmax;
       _XXA=(_jj-1)*&__xxmax;
       do _i=1 to &__xmax;
        _sum=0;
        do _j=1 to &__xmax;
         _k=max(_i,_j);
         _l=(_k*(_k-1))/2+min(_i,_j);
         _sum+_txx2&_ia(_XXA+_l)*__2&_ia.B(_XA+_j+_kx);
        end;
        _2&_ia.btmp(_i)=_sum;
       end;
       do _i=1 to &__xmax;
        __2&_ia.B(_XA+_i+_kx)=_2&_ia.btmp(_i);
       end;
      end;
     %end;
    end;
    %let __bsets=%scan(&_bsets,&_ia);
    %let _v1=&_bmax;
    %let __bsize=%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk);
    %if &_v1 gt &__bsize %then %let _v1=&__bsize;
    array _2&_ia.B(&_v1);
    _k=0;
    do _i=1 to &__bsets;
    do _j=1 to &_v1;
     _k+1;
     if _k le %eval(&_size*&&_gntot&_ia*&__xmax*&__nblk) then _2&_ia.B(_j)=__2&_ia.B(_k);
     else _2&_ia.B(_j)=0;
    end;
    output _DB2&_ia._;
    end;
   %end;
   
  %end;
 %end;
 end;
 RUN;
 %if &_fel=1 %then %goto SLUTA;

 DATA dut(keep=row col &_keep);
 if _n_=1 then do;
  array _T(&_maxtot) _temporary_;
  do _i=1 to &_maxtot;
    set _DS1;
    _T(_i)=__T;
  end;
   
 %if &_nauxvar>0 %then %do _ia=1 %to &_nauxvar;
  %if &&_gntot&_ia>0 %then %do;
   %let __bsets=%scan(&_bsets,&_ia);
   %let __nblk=%scan(&_nblk,&_ia);
   %let __xmax=%scan(&_xmax,&_ia);
   %let _v1=&_bmax;
   %let __bsize=%eval(&_size*&&_gntot&_ia*&__xmax*&__nblk);
   %if &_v1 gt &__bsize %then %let _v1=&__bsize;
   array _&_ia.B(&_v1);
   array __&_ia.B(&__bsize) _temporary_;
   retain __&_ia.B 0;
   _k=0;
   do _i=1 to &__bsets;
    set _DB&_ia._;
   do _j=1 to &_v1;
    _k+1;
    if _k le %eval(&_size*&&_gntot&_ia*&__xmax*&__nblk) then __&_ia.B(_k)=_&_ia.B(_j);
   end;
   end;
   
   %if &_strtgi=6 and %scan(&_mdlvl,&_ia)=2 and &RTOU=Y %then %do;
    array _2&_ia.B(&_v1);
    array __2&_ia.B(&__bsize) _temporary_;
    retain __2&_ia.B 0;
    _k=0;
    do _i=1 to &__bsets;
     set _DB2&_ia._;
    do _j=1 to &_v1;
     _k+1;
     if _k le %eval(&_size*&&_gntot&_ia*&__xmax*&__nblk) then __2&_ia.B(_k)=_2&_ia.B(_j);
    end;
    end;
   %end;
   
  %end;
 %end;
 end;

 set _ds0%if &SET=S %then (where=(%QUOTE(&RESPONSE))); end=_eof;
  BY &STRATID &GROUPID &CLUSTID;

 %if &_nauxvar>0 %then %do _ia=1 %to &_nauxvar;
  %if &&_gntot&_ia>0 %then %do;
   %let __mdlvl=%scan(&_mdlvl,&_ia);
   %let __nblk=%scan(&_nblk,&_ia);
   %let __xmax=%scan(&_xmax,&_ia);
   %let __xxmax=%scan(&_xxmax,&_ia);
   %if &__mdlvl=1 %then 
    if first.&CLUSTID or first.&STRATID then;
   do; _i_&_ia=0;
    do until(last._id&_ia);
     set _XV&_ia%if &SET=S %then (where=(_ph=2));; 
      BY _id&_ia NOTSORTED;
     array _p&_ia._(&__xmax) _temporary_;
     array _x&_ia._(&__xmax) _temporary_;
     _i_&_ia+1;
     _p&_ia._(_i_&_ia)=_pos&_ia;
     _x&_ia._(_i_&_ia)=_val&_ia;
    end;
    _XA&_ia=(_num&_ia-1)*&__xmax;
   end;
   
   %if &_strtgi=6 and &__mdlvl=2 and &RTOU=Y %then %do;
    if first.&CLUSTID or first.&STRATID then do;
     _2i_&_ia=0;
     do until(last._id&_ia);
      set _XV2&_ia%if &SET=S %then (where=(_ph=2));; 
       BY _id&_ia NOTSORTED;
      array _2p&_ia._(&__xmax) _temporary_;
      array _2x&_ia._(&__xmax) _temporary_;
      _2i_&_ia+1;
      _2p&_ia._(_2i_&_ia)=_pos&_ia;
      _2x&_ia._(_2i_&_ia)=_val&_ia;
     end;
    end;
    retain _2i_&_ia 0;
   %end;
   
   %let _gntot&_ia=0;
   retain _i_&_ia _XA&_ia 0;
  %end;
 %end;

 %if &_summa=1 and &_smaxtot ne 0 %then %do;
  %if &CNR=N %then array _rsum(%eval(2*&_smaxtot*&MAXCOL)) _temporary_;
   %else %if &_nauxvar=1 %then array _rsum(%eval(4*&_smaxtot*&MAXCOL)) _temporary_;
    %else array _rsum(%eval(6*&_smaxtot*&MAXCOL)) _temporary_;;
 %end;

 array _zs(%eval(&_size*&_maxut)) _temporary_;
 array _zss(%eval(&_size*&_maxut)) _temporary_;
 %if &CNR=Y %then %do;
  array _2zss(%eval(&_size*&_maxut)) _temporary_;
  retain _2zss 0;
 %end;
 array _v(%eval(&_size*&_maxut)) _temporary_;
 %if &_strtgi=3 or &_strtgi=4 %then %do;
  array _cs(&_maxtot) _temporary_;
  retain _cs 0;
 %end;
 %if &_strtgi=6 %then %do;
  array _cs(&_maxtot) _temporary_;
  retain _cs 0;
  %if &RTOU=Y %then %do;
   array _2cs(&_maxtot) _temporary_;
   retain _2cs 0;
  %end;
 %end;
 %if &_strtgi=2 or &_strtgi=4 %then %do;
  array _gs(%eval(&_size*&_maxut)) _temporary_;
  array _gss(%eval(&_size*&_maxut)) _temporary_;
  retain _gs 0;
  retain _gss 0;
 %end;
 retain _sista 0;
 retain _zs 0;
 retain _zss 0;
 retain _v 0;
 %if &_ppps=1 %then %do;
  %if &_strtgi eq 1 or &_strtgi eq 3 %then %do;
   if &NRESP>0 and &LAMBDA>0 then _q1=&NSAMP/&NRESP/&LAMBDA; else _q1=0;
  %end;
  %if &_strtgi>4 %then %do;
   if &LAMBDA>0 then _q1=1/&LAMBDA; else _q1=0;
  %end;
  if _q1 %if &_strtgi eq 3 or &_strtgi=6 %then
  and (last.&CLUSTID or last.&STRATID); then _cz+(1-1/_q1);
 %end;

 %if &_strtgi=1 or &_strtgi=3 %then %do;
  %_STRGI13
 %end;

 %if &_strtgi=2 or &_strtgi=4 %then %do;
  %_STRGI24
 %end;
 
 %if &_strtgi=5 or &_strtgi=6 %then %do;
  %_STRGI56
 %end;
 run;
 %SLUTA:
 %if &_sets ne %then %do; PROC DATASETS nolist; delete &_sets; quit; %end;
 %if &_fel=1 %then %do; data _null_; ABORT; %end;
 RUN;
 options &_notes;
%mend CLAN;
%macro  DIV(_id,a,b) /store;
 %if &ind eq 2 %then %do;
  %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi eq 6 %then
  if last.&CLUSTID or last.&STRATID or _sista then;
  do;
   if _p&b then do;
    _p&_id=(_p&a)/(_p&b);   
    __&_id=(__&a)/(_p&b)-_p&_id*(__&b)/(_p&b);
    %if &CNR=Y %then %do;
     _1&_id=(_1&a)/(_p&b)-_p&_id*(_1&b)/(_p&b);
     _2&_id=(_2&a)/(_p&b)-_p&_id*(_2&b)/(_p&b);
     %if &_nauxvar>1 %then %do;
      _3&_id=(_3&a)/(_p&b)-_p&_id*(_3&b)/(_p&b);
      _4&_id=(_4&a)/(_p&b)-_p&_id*(_4&b)/(_p&b);
     %end;
	%end;
   end;
   else do;
    _p&_id=0;
    __&_id=0;
    %if &CNR=Y %then %do;
     _1&_id=0;
     _2&_id=0;
     %if &_nauxvar>1 %then %do;
      _3&_id=0;
      _4&_id=0;
     %end;
    %end;
   end;
  end;
 %end;
%mend DIV;
%macro ESTIM(_id,namn,SV) /store;
%local _idx;
 %let _ut=%eval(&_ut+1); %let _idx=%eval(&_size*(&_ut-1));
 %if &SV= %then %let SV=S;
 %if &ind=1 %then %do;
  %if &_ut=1 %then %let _keep=;
  %if &namn= %then %let namn=&_id;
  %let _keep=&_keep p&namn s&namn;
 %end;
 %if &ind eq 2 %then %do;
  %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi=6 %then
  if (last.&CLUSTID or last.&STRATID) then;
  do;
   if __&_id then do;
     _zs(_rk %if &_idx gt 0 %then +&_idx;)+
         (__&_id%if &_ppps=1 and _q1>0 %then *_q1*(1-1/_q1););
     _zss(_rk %if &_idx gt 0 %then +&_idx;)+
         (__&_id*__&_id%if &_ppps=1 and _q1>0 %then *_q1*_q1*(1-1/_q1););
   end;
  %if &CNR=Y %then %do;
   _1=0;
   _2=0;
   %if &_nauxvar=1 %then %do;
    if _vsk&_auxvar then do;
     if _1&_id then _1=
       _1&_id*_1&_id*(1/_vsk&_auxvar-1)%if &_ppps=1 and _q1>0 %then *_q1*_q1*(1-1/_q1);;
     if _2&_id then _2=
       _2&_id*_2&_id*(1-1/_vsk&_auxvar)%if &_ppps=1 %then *_q1*_q1;;
    end;
   %end;
   %else %do;
    if _1&_id or _2&_id then _1=_2&_id*_2&_id-_1&_id*_1&_id;
    if _3&_id or _4&_id then _2=_3&_id*_3&_id-_4&_id*_4&_id;
    %if &_ppps=1 %then %do;
     _1=_1*_q1*_q1*(1-1/_q1);
     _2=_2*_q1*_q1;
    %end;
   %end; 
   if &NSAMP>1 and _1 then
     _zss(_rk %if &_idx gt 0 %then +&_idx;)+_1%if &_ppps=0 %then*(&NSAMP-1)/&NSAMP;;
   if _2 then _2zss(_rk %if &_idx gt 0 %then +&_idx;)+_2;
  %end;
  end;
 if _sista then do;
    row=_irad; col=_ikol;
  %if &namn= %then %let namn=&_id;
    p&namn=_p&_id;
  %if %UPCASE(%substr(&SV,1,1))=V %then %do;
    s&namn=_v(_rk %if &_idx gt 0 %then +&_idx;);
  %end;
  %else %do;
    if _v(_rk %if &_idx gt 0 %then +&_idx;)>0 then
    s&namn=sqrt(_v(_rk %if &_idx gt 0 %then +&_idx;));
    else s&namn=0;
  %end;
 end;
 %end;
%mend ESTIM;
%macro function(_i,_j) /store;
 %put; %put ******CLAN******;
 %put E R R O R..  You have forgotten the MACRO FUNCTION or placed it wrong!;
 %put Maybe it was spelled FUNKTION?;
 %let _fel=1;
%mend function;
%macro GREG(x)/parmbuff store;
%local _idx _id _a _b _c _au _i __mdlvl __xmax __nblk;
 %if &ind eq 0 and &_auxvar=0 %then %do;
  %put ******CLAN******;
  %put E R R O R, no AUXVAR is present;
  %let _fel=1;
 %end;
 %let _ntot=%eval(&_ntot+1); %let _idx=%eval(&_size*(&_ntot-1));
 %let syspbuff=%qsubstr(&syspbuff,2,%length(&syspbuff)-2);
 %let _id=%scan(&syspbuff,1,%str(,));
 %let _a=%scan(&syspbuff,2,%str(,));
 %let _b=%scan(&syspbuff,3,%str(,));
 %let _c=%scan(&syspbuff,4,%str(,));
 %if &_c= %then %let _c=__#;
 %let _au=;
 %if &_auxvar>0 %then %do _i=1 %to &_auxvar;
   %if &_c=%scan(&_mdlid,&_i) %then %let _au=&_i;
 %end;
 %if &_au= %then %do;
  %put; %put ******CLAN******;
  %put E R R O R.. MODELID: &_c does not exists!;
  %put CHECK AUXVAR!;
  %let _fel=1;
 %end; 
 %if &_fel=0 %then %let _gntot&_au=%eval(&&_gntot&_au+1);
 %if &ind>0 %then %do;  
  %let __mdlvl=%scan(&_mdlvl,&_au);
  %let __xmax=%scan(&_xmax,&_au); 
  %let __nblk=%scan(&_nblk,&_au);
 do;
 %end;
 %if &ind eq 1 %then %do;
  %if &__mdlvl=1 %then %do;  /* klusternivå */
   if (&_b) then _cs(_rk %if &_idx gt 0 %then +&_idx;)+(&_a)*(&WEIGHT);
  %end;

  %if &__mdlvl=2 %then %do;  /* elementnivå */
   if (&_b) then do;
    _tmp(_rk %if &_idx gt 0 %then +&_idx;)+
        (&_a)*(&WEIGHT)*__wk&_au%if &_ppps=1 %then *_q1;;
    _kx=((&&_gntot&_au-1)*&_size+(_rk-1))*&__xmax*&__nblk;
    do _i=1 to _i_&_au;
     if (&_a) and _p&_au._(_i) then
      _&_au.btmp(_XA&_au+_p&_au._(_i)+_kx)+
             (_x&_au._(_i)*(&_a)*(&WEIGHT)*_qk&_au%if &CNR=Y %then *_vsk&_au;
             %if &_ppps=1 %then *_q1;);
    end;
   end;
   %if &_strtgi=6 and &RTOU=Y %then %do;
    if (&_b) then _cs(_rk %if &_idx gt 0 %then +&_idx;)+(&_a)*(&WEIGHT);
    if last.&CLUSTID or last.&STRATID then do;
     __aa=_cs(_rk %if &_idx gt 0 %then +&_idx;);
     _cs(_rk %if &_idx gt 0 %then +&_idx;)=0;
     _kx=((&&_gntot&_au-1)*&_size+(_rk-1))*&__xmax*&__nblk;
     do _i=1 to _2i_&_au;
      if __aa and _2p&_au._(_i) then _2&_au.btmp(_XA&_au+_2p&_au._(_i)+_kx)+
               (_2x&_au._(_i)*__aa*_qi&_au*_vsk&_au%if &_ppps=1 %then *_q1;);
     end;
    end;
   %end;
   
  %end;
 end;
  %if &__mdlvl=1 %then %do;  /* klusternivå */
   if last.&CLUSTID or last.&STRATID then do;
    __aa=_cs(_rk %if &_idx gt 0 %then +&_idx;);
    _tmp(_rk %if &_idx gt 0 %then +&_idx;)+__aa*__wk&_au%if &_ppps=1 %then *_q1;;
    _cs(_rk %if &_idx gt 0 %then +&_idx;)=0;
    _kx=((&&_gntot&_au-1)*&_size+(_rk-1))*&__xmax*&__nblk;
    do _i=1 to _i_&_au;
     if __aa and _p&_au._(_i) then _&_au.btmp(_XA&_au+_p&_au._(_i)+_kx)+
               (_x&_au._(_i)*__aa*_qk&_au%if &CNR=Y %then *_vsk&_au;
               %if &_ppps=1 %then *_q1;);
    end;
   end;
  %end;
 %end;

 %if &ind eq 2 %then %do;
  %if &__mdlvl=1 %then %do;  /* klusternivå */
   if (&_b) then _cs(_rk %if &_idx gt 0 %then +&_idx;)+(&_a)*(&WEIGHT);
  end;
  %end;

  %if &__mdlvl=2 %then %do;  /* elementnivå */
   _0=0;
   if (&_b) then _0=(&_a)*(&WEIGHT); 
  end;
    _kx=((&&_gntot&_au-1)*&_size+(_rk-1))*&__xmax*&__nblk;
    __bb=0;
    do _i=1 to _i_&_au;
     if _p&_au._(_i) then __bb+(_x&_au._(_i)*__&_au.B(_XA&_au+_p&_au._(_i)+_kx));
    end;
   %if &RTOU=Y %then __&_id=(_0-__bb)*_gk&_au;
   %else __&_id=_0;%if &CNR=Y %then *_vsk&_au;;
   %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi=6 %then %do;
    _cs(_rk %if &_idx gt 0 %then +&_idx;)+__&_id;
    %if &_strtgi=6 and &RTOU=Y %then %do;
     _2cs(_rk %if &_idx gt 0 %then +&_idx;)+_0;
    %end;
   %end;
   %if not(&_strtgi=6 and &RTOU=Y) %then %do;
    %if &CNR=Y %then %do;
     _1&_id=__&_id;
     %if &_nauxvar=1 %then %do;    
      _2&_id=(_0-__bb)*_vsk&_au;
     %end;
     %else %do;
      _3&_id=(_0-__bb)*_vsk&_au;
      if _vsk&_au>0 then do;
       _2&_id=__&_id/sqrt(_vsk&_au);
       _4&_id=_3&_id/sqrt(_vsk&_au);
      end;
      else do;
       _2&_id=0;
       _4&_id=0;
      end;
     %end;
    %end;
   %end;
   _0=.;
  %end;
  _p&_id=_T(_rk %if &_idx gt 0 %then +&_idx;);
  %if &__mdlvl=1 %then %do;  /* klusternivå */
  if last.&CLUSTID or last.&STRATID then do;
    __aa=_cs(_rk %if &_idx gt 0 %then +&_idx;);
    _cs(_rk %if &_idx gt 0 %then +&_idx;)=0;
    _kx=((&&_gntot&_au-1)*&_size+(_rk-1))*&__xmax*&__nblk;
    __bb=0;
    do _i=1 to _i_&_au;
     if _p&_au._(_i) then __bb+(_x&_au._(_i)*__&_au.B(_XA&_au+_p&_au._(_i)+_kx));
    end;
   %if &RTOU=Y %then __&_id=(__aa-__bb)*_gk&_au;
   %else __&_id=__aa;%if &CNR=Y %then *_vsk&_au;;
   %if &CNR=Y %then %do;
    _1&_id=__&_id;
    %if &_nauxvar=1 %then %do;
     _2&_id=(__aa-__bb)*_vsk&_au;
    %end;
    %else %do;
     _3&_id=(__aa-__bb)*_vsk&_au;
     if _vsk&_au>0 then do;
      _2&_id=__&_id/sqrt(_vsk&_au);
      _4&_id=_3&_id/sqrt(_vsk&_au);
     end;
     else do;
      _2&_id=0;
      _4&_id=0;
     end;
    %end;
   %end;
  end;
   %if &CNR=Y %then %do;
    else do; _1&_id=0; _2&_id=0;
    %if &_nauxvar>1 %then %do; _3&_id=0; _4&_id=0; %end;
    end;
   %end; 
  %end;
  %if &__mdlvl=2 %then %do;  /* elementnivå */
   %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi=6 %then %do;
    if last.&CLUSTID or last.&STRATID then do;
     __&_id=_cs(_rk %if &_idx gt 0 %then +&_idx;);
     _cs(_rk %if &_idx gt 0 %then +&_idx;)=0;
     %if &_strtgi=6 and &RTOU=Y %then %do;
      __aa=_2cs(_rk %if &_idx gt 0 %then +&_idx;);
      _2cs(_rk %if &_idx gt 0 %then +&_idx;)=0;
      _kx=((&&_gntot&_au-1)*&_size+(_rk-1))*&__xmax*&__nblk;
      __bb=0;
      do _i=1 to _2i_&_au;
       if _2p&_au._(_i) then __bb+(_2x&_au._(_i)*__2&_au.B(_XA&_au+_2p&_au._(_i)+_kx));
      end;
      %if &_nauxvar=1 %then %do;
       _1&_id=__&_id;
       _2&_id=(__aa-__bb)*_vsk&_au;
      %end;
      %else %do;
       _1&_id=__&_id;
       _3&_id=(__aa-__bb)*_vsk&_au;
       if _vsk&_au>0 then do;
        _2&_id=_1&_id/sqrt(_vsk&_au);
        _4&_id=_3&_id/sqrt(_vsk&_au); 
       end;
       else do;
        _2&_id=0;
        _4&_id=0;
       end;
      %end;
     %end;
    end;
   %end;
  %end;
 %end;
%mend GREG;
%macro MULT(_id,a,b) /store;
 %if &ind eq 2 %then %do;
  %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi eq 6 %then
  if last.&CLUSTID or last.&STRATID or _sista then;
  do;
   __&_id=(__&a)*(_p&b)+(__&b)*(_p&a);
   %if &CNR=Y %then %do;
    _1&_id=(_1&a)*(_p&b)+(_1&b)*(_p&a);
    _2&_id=(_2&a)*(_p&b)+(_2&b)*(_p&a);
    %if &_nauxvar>1 %then %do;
     _3&_id=(_3&a)*(_p&b)+(_3&b)*(_p&a);
     _4&_id=(_4&a)*(_p&b)+(_4&b)*(_p&a);
    %end;
   %end;
   _p&_id=(_p&a)*(_p&b);	
  end;
 %end;
%mend MULT;
%macro  SUB(_id,a,b) /store;
 %if &ind eq 2 %then %do;
  %if &_strtgi eq 3 or &_strtgi eq 4 or &_strtgi eq 6 %then
  if last.&CLUSTID or last.&STRATID or _sista then;
  do;
   __&_id=(__&a)-(__&b);
   %if &CNR=Y %then %do;
    _1&_id=(_1&a)-(_1&b);
    _2&_id=(_2&a)-(_2&b);
    %if &_nauxvar>1 %then %do;
     _3&_id=(_3&a)-(_3&b);
     _4&_id=(_4&a)-(_4&b);
    %end;
   %end;
   _p&_id=(_p&a)-(_p&b);
  end;
 %end;
%mend SUB;
%macro TABSUM(TABLE=,
      FRAD=, FROW=,
      FKOL=, FCOL=,
      TRAD=, TROW=,
      TKOL=, TCOL=) /store;
%local _idrad;
 %if %QUOTE(&FROW)= %then %let FROW=%QUOTE(&frad); 
 %if &TROW= %then %let TROW=&trad;
 %if %QUOTE(&FCOL)= %then %let FCOL=%QUOTE(&fkol); 
 %if &TCOL= %then %let TCOL=&tkol;
 %if &ind=0 %then %do;
  %let _summa=1;
  %if &TABLE= %then %do;
     %put; %put ******CLAN******;
     %put E R R O R.. TABLE is missing!;
     %let _fel=1;
  %end;
  %if %QUOTE(&frow) ne and %QUOTE(&fcol) eq %then
      %let _sntot=%eval(&_sntot+1);
  %if %QUOTE(&frow) ne %then %do;
    %if %QUOTE(&trow) eq %then %do;
     %put; %put ******CLAN******;
     %put E R R O R.. TROW is missing!;
     %let _fel=1;
    %end;
    if MAX(0, %_in(&frow)) gt &MAXROW then do;
     put /'******CLAN******';
     put 'E R R O R.. Max value in FROW is greater than MAXROW!'/;
     CALL SYMPUT('_fel','1');
    end;
    %if %QUOTE(&trow) ne %then %do;
     %if %INDEX(%QUOTE(%_in(&trow)),%STR(,))>0 %then %do;
      %put; %put ******CLAN******;
      %put E R R O R.. TROW has an invalid argument!;
      %let _fel=1;
     %end;
     %if &_fel ne 1 %then %do;
      %if &trow gt &MAXROW %then %do;
       %put; %put ******CLAN******;
       %put E R R O R.. TROW is greater than MAXROW;
       %let _fel=1;
      %end;
     if MAX(0, %_in(&frow)) gt &trow then do;
      put /'******CLAN******';
      put 'E R R O R.. Max value in FROW is greater than TROW'/;
      CALL SYMPUT('_fel','1');
     end;
     %end;
    %end;
  %end;
  %if %QUOTE(&fcol) ne %then %do;
    %if %QUOTE(&tcol) eq %then %do;
     %put; %put ******CLAN******;
     %put E R R O R.. TCOL is missing;
     %let _fel=1;
    %end;
    if MAX(0, %_in(&fcol)) gt &MAXCOL then do;
     put /'******CLAN******';
     put 'E R R O R.. Max value in FCOL is greater than MAXCOL'/;
     CALL SYMPUT('_fel','1');
    end;
    %if %QUOTE(&tcol) ne %then %do;
     %if %INDEX(%QUOTE(%_in(&tcol)),%STR(,))>0 %then %do;
      %put; %put ******CLAN******;
      %put E R R O R.. TCOL has an invalid argument!;
      %let _fel=1;
     %end;
     %if &_fel ne 1 %then %do;
      %if &tcol gt &MAXCOL %then %do;
       %put; %put ******CLAN******;
       %put E R R O R.. TCOL is greater than MAXCOL!;
       %let _fel=1;
      %end;
     if MAX(0, %_in(&fcol)) gt &tcol then do;
      put /'******CLAN******';
      put 'E R R O R.. Max value in FCOL is greater than TCOL'/;
      CALL SYMPUT('_fel','1');
     end;
    %end;
   %end;
  %end;
 %end;
 %if &ind=2 %then %do;
 %if &_strtgi=3 or &_strtgi=4 or &_strtgi=6 %then
  if last.&CLUSTID or last.&STRATID or _sista then;
   do;
   %if %QUOTE(&frow) ne and %QUOTE(&fcol) ne %then %do;
    if _irad IN(%_in(&frow)) and _ikol IN(%_in(&fcol)) then
    do;
     _a&table+_p&table;
     _b&table+__&table;
     %if &CNR=Y %then %do;
      _c&table+_1&table;
      _d&table+_2&table;
      %if &_nauxvar>1 %then %do;
       _e&table+_3&table;
       _f&table+_4&table;
      %end;
     %end;
    end;
   %end;
   %if %QUOTE(&frow) ne and %QUOTE(&fcol) eq %then %do;
    %let _sntot=%eval(&_sntot+1);
    %if &CNR=N %then %let _idrad=%eval(2*(&_sntot-1)*&MAXCOL);
      %else %if &_nauxvar=1 %then %let _idrad=%eval(4*(&_sntot-1)*&MAXCOL);
        %else %let _idrad=%eval(6*(&_sntot-1)*&MAXCOL);
    if _irad IN(%_in(&frow)) then
    do;
     _rsum(_ikol%if &_idrad>0 %then +&_idrad;)+_p&table;
     _rsum(_ikol+%eval(&_idrad+&MAXCOL))+__&table;
     %if &CNR=Y %then %do;
      _rsum(_ikol+%eval(&_idrad+2*&MAXCOL))+_1&table;
      _rsum(_ikol+%eval(&_idrad+3*&MAXCOL))+_2&table;
      %if &_nauxvar>1 %then %do;
       _rsum(_ikol+%eval(&_idrad+4*&MAXCOL))+_3&table;
       _rsum(_ikol+%eval(&_idrad+5*&MAXCOL))+_4&table;
      %end;
     %end;
    end;
   %end;
   %if %QUOTE(&fcol) ne and %QUOTE(&frow) eq %then %do;
    %let _skolnr=%eval(&_skolnr+1);
    if _ikol IN(%_in(&fcol)) then
    do;
     _k&_skolnr+_p&table;
     _l&_skolnr+__&table;
     %if &CNR=Y %then %do;
      _m&_skolnr+_1&table;
      _n&_skolnr+_2&table;
      %if &_nauxvar>1 %then %do;
       _o&_skolnr+_3&table;
       _p&_skolnr+_4&table;
      %end;
     %end;
    end;
   %end;
   %if %QUOTE(&frow) ne and %QUOTE(&fcol) ne %then %do;
    if _irad=&trow and _ikol=&tcol then
    do;
     _p&table=_a&table; _a&table=0;
     __&table=_b&table; _b&table=0;   
     %if &CNR=Y %then %do;
      _1&table=_c&table; _c&table=0;
      _2&table=_d&table; _d&table=0;
      %if &_nauxvar>1 %then %do;
       _3&table=_e&table; _e&table=0;
       _4&table=_f&table; _f&table=0;
      %end;
     %end; 
    end;
   %end;
   %if %QUOTE(&frow) ne and %QUOTE(&fcol) eq %then %do;
    if _irad=&trow then
    do;
     _p&table=_rsum(_ikol%if &_idrad>0 %then +&_idrad;);
     __&table=_rsum(_ikol+%eval(&_idrad+&MAXCOL));
     _rsum(_ikol%if &_idrad>0 %then +&_idrad;)=0;
     _rsum(_ikol+%eval(&_idrad+&MAXCOL))=0;        
     %if &CNR=Y %then %do;
      _1&table=_rsum(_ikol+%eval(&_idrad+2*&MAXCOL));
      _rsum(_ikol+%eval(&_idrad+2*&MAXCOL))=0;
      _2&table=_rsum(_ikol+%eval(&_idrad+3*&MAXCOL));
      _rsum(_ikol+%eval(&_idrad+3*&MAXCOL))=0;
      %if &_nauxvar>1 %then %do;
       _3&table=_rsum(_ikol+%eval(&_idrad+4*&MAXCOL));
       _rsum(_ikol+%eval(&_idrad+4*&MAXCOL))=0;
       _4&table=_rsum(_ikol+%eval(&_idrad+5*&MAXCOL));
       _rsum(_ikol+%eval(&_idrad+5*&MAXCOL))=0;
      %end;
     %end;
    end;
   %end;
   %if %QUOTE(&fcol) ne and %QUOTE(&frow) eq %then %do;
    if _ikol=&tcol then
    do;
     _p&table=_k&_skolnr;  _k&_skolnr=0;
     __&table=_l&_skolnr;  _l&_skolnr=0;        
     %if &CNR=Y %then %do;
      _1&table=_m&_skolnr;  _m&_skolnr=0;
      _2&table=_n&_skolnr;  _n&_skolnr=0;
      %if &_nauxvar>1 %then %do;
       _3&table=_o&_skolnr;  _o&_skolnr=0;
       _4&table=_p&_skolnr;  _p&_skolnr=0;
      %end;
     %end;
    end;
   %end;
   end;
%end;
%mend TABSUM;
%macro TOT(x)/parmbuff store;
%local _idx _id _a _b;
 %let _ntot=%eval(&_ntot+1); %let _idx=%eval(&_size*(&_ntot-1));
 %let syspbuff=%qsubstr(&syspbuff,2,%length(&syspbuff)-2);
 %let _id=%scan(&syspbuff,1,%str(,));
 %let _a=%scan(&syspbuff,2,%str(,));
 %let _b=%scan(&syspbuff,3,%str(,));
 %if &ind eq 0 %then %do;
  %if &CNR=Y %then %do;
    %put; %put ******CLAN******;
    %put E R R O R..  TOT must not be used when Calibration for Non-Response (CNR) is used!;
    %put Use GREG instead!;
    %let _fel=1;
  %end;  
 %end;  
 %if &ind eq 1 %then %do;
 do;
  if (&_b) then _tmp(_rk %if &_idx gt 0 %then +&_idx;)+
                (&_a)*(&WEIGHT)%if &_ppps=1 %then *_q1;;
 end;
 %end;
 %if &ind eq 2 %then %do;
 do;
  %if &_strtgi le 2 %then %do;
    _0=0;
    if (&_b) then _0=(&_a)*(&WEIGHT);
  %end;
  %if &_strtgi eq 3 or &_strtgi eq 4 %then %do;
    if (&_b) then _cs(_rk %if &_idx gt 0 %then +&_idx;)+(&_a)*(&WEIGHT);
  %end;
 end;
  %if &_strtgi le 2 %then %do;
   if _0 then __&_id=_0; else __&_id=0; _0=.;
  %end;
  _p&_id=_T(_rk %if &_idx gt 0 %then +&_idx;);
  %if &_strtgi eq 3 or &_strtgi eq 4 %then %do;
    if last.&CLUSTID or last.&STRATID then do;
     __&_id=_cs(_rk %if &_idx gt 0 %then +&_idx;);
     _cs(_rk %if &_idx gt 0 %then +&_idx;)=0;
    end;
  %end;
 %end;
%mend TOT;
