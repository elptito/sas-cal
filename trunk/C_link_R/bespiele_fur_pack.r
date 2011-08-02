#Package CinR
#beinhaltet: 
#1)R-Code mit funktionen:
#  hello, hey, fak, vecsum, mat, setList, list
#2)src Ordner mit:
#  C-Programme fak.c, hello.c, vecSum.c
#  CinR.dll


library(CinR)

mat2<-matrix(1:9,3, byrow =T) #Matrix für die Funktion plus.one.mat(m)
mat2
v<-c(1:3)				#Vektor für die Funktion vecSum(v)


#Aufruf von Funktionen
hello(3) 			 #Hallo World ver.1
hey(2)			 #Hallo World ver.2
fak(5)			 #berechnet n!
l<-mach.list()		 #erschafft eine Liste und gibt die zurück	
prn.list(l)			 #print erste Listen-Element, wenn numerisch		
plus.one.mat(mat2)	 #addiert zu jede Matrix-Element +1 und liefert die zurück
vecSum(v)			 #gibt Summe alle Vektoren-Elemente aus
