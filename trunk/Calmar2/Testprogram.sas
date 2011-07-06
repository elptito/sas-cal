LIBNAME COMPIL 'C:\Users\darek\Desktop\Calmar2';
OPTIONS SASMSTORE=COMPIL MSTORED NODATE;

DATA don;
INPUT nom $ x $ y $ z pond;
CARDS;
A 1 f 1 10
B 1 h 2  0
C 1 h 3  .
D 5 f 1 11
E 5 f 3 13
F 5 h 2  7
G 5 h 2  8
H 1 h 2  8
I 5 f 2  9
J . h 2 10
K 5 h 2 14
;
DATA marges;
INPUT var $ n mar1 mar2;
CARDS;
X 2  20  60
y 2  30  50
z 0 140   .
;
TITLE "Un petit exemple commenté de calage sur marges";
%CALMAR2(DATAMEN=don,POIDS=pond,IDENT=nom,
        MARMEN=marges,M=2,EDITPOI=oui,OBSELI=oui,
        DATAPOI=sortie,POIDSFIN=pondfin,LABELPOI=pondération raking ratio)

PROC PRINT DATA=__OBSELI;
TITLE2 "Liste des observations éliminées";
RUN ;


/* XIV.2.1 Le programme */


/* Données concernant les grappes */


/* Table échantillon */


DATA ent;
    INPUT ident $ x1ent $ x2ent $ x3ent $ x4ent $ y1ent y2ent pond;
    x3entold=x3ent;
    x4entold=x4ent;
    CARDS;

a 1 1 11 a 1 1 10
b 2 2 12 a 2 2 11
c 1 2 11 b 2 3 12
d 2 3 14 c 1 0 10
e 2 3 13 b 4 1  9
f 2 3 11 c 0 1 10
g 1 1 12 c 5 2 10
h 1 2 11 a 1 1 12
i 1 3 14 c 2 0 10
j 1 2 12 b 2 4  9
k 2 2 13 a 1 2 10
l 1 3 14 a 2 0 11
m 2 1 11 a 0 3 10
n 2 2 12 b 2 2 13
o 1 2 13 c 5 1  8
p 2 3 14 b 6 2 10
q 1 1 13 a 2 5 11
r 2 2 11 a 1 3  9
s 1 3 12 b 2 2 11
t 1 3 13 a 1 1 10
u 2 2 11 b 4 2  9
v 2 2 12 c 0 1 12
w 1 1 14 a 1 2  9
;



/* Table des marges de niveau 1 (entreprises) */


DATA margent;
     INPUT var $ r n mar1-mar4;
     CARDS;

x1ent 0 2 120 116  .  .
x2ent 0 3  60 100 76  .
x3ent 0 4  70  60 50 56
x4ent 0 3 100  70 66  .
y1ent 0 0 480   .  .  .
y2ent 0 0 410   .  .  .
;
 


  /*   Données concernant les établissements */

DATA etab;
     INPUT ident $ num $ x1etab $ x2etab $ y1etab y2etab pond;
     x1etabold=x1etab;
     x2etabold=x2etab;
     identetab=COMPRESS(ident!!num);
     CARDS;

a 1 1 a 1 1 10
a 2 2 a 1 0 10
a 3 2 b 1 3 10
b 1 2 b 1 3 11
b 2 3 a 4 2 11
c 1 3 a 2 0 12
c 2 1 b 3 1 12
d 1 2 a 0 1 10
e 1 3 a 4 5  9
e 2 2 a 1 2  9
f 1 1 b 0 3 10
g 1 1 a 2 1 10
g 2 3 b 1 0 10
g 3 2 a 2 3 10
g 4 3 a 4 1 10
h 1 1 b 1 2 12
i 1 2 b 4 2 10
i 2 3 a 1 2 10
j 1 3 a 0 2  9
k 1 2 b 1 2 10
k 2 1 a 1 4 10
l 1 2 a 2 0 11
l 2 3 a 4 0 11
m 1 1 a 0 3 10
n 1 1 b 4 2 13
n 2 3 a 1 5 13
n 3 2 a 0 1 13
o 1 1 b 5 1  8
p 1 2 b 6 2 10
q 1 3 a 1 5 11
q 2 1 a 2 3 11
r 1 1 b 0 6  9
s 1 3 b 2 4 11
t 1 1 a 0 1 10
t 2 2 b 4 1 10
u 1 1 b 4 3  9
u 2 2 a 2 5  9
v 1 2 a 0 1 12
w 1 1 a 5 2  9
w 2 2 a 1 0  9
;

/* Table des marges de niveau 2 (individus)*/

DATA margetab;
     INPUT var $ R n mar1-mar3;
     CARDS;

x1etab 0 3 140 160 114
x2etab 0 2 270 144   .
y1etab 0 0 820   .   .
y2etab 0 0 850   .   .
;


%CALMAR2(DATAMEN=ent,
         MARMEN=margent,
         IDENT=ident,
         DATAIND=etab,
         MARIND=margetab,
         IDENT2=identetab,
         POIDS=pond,
         DATAPOI=poidsm,
         DATAPOI2=poidsi,
         POIDSFIN=pond,
         CONTPOI=non)
RUN ;
