#Package CinR
#beinhaltet: 
#1)R-Code mit funktionen:
#  hello, hey, fak, vecsum, mat, setList, list
#2)src Ordner mit:
#  C-Programme fak.c, hello.c, vecSum.c
#  CinR.dll

library(CinR)


#CinR.dll wird geladen, findet automatisch immer den richtigen Pfad
dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))

#paar Hilfvariablen
a<-c(1:3)
b<-c("ja", "nein")
list.ab<-list(a,b)

mat.test<-matrix(1:9,3, byrow =T)
mat.test

v<-c(1:3)

#Aufruf von Funktionen
hello(3)
hey(2)
fak(5)
setList()
list(list.ab)
mat(mat.test)
vecSum(v)

#CinR.dll ist nicht mehr geladen
dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))

