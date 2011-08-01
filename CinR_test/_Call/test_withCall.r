#Beispiele für Funktion .Call
#.Call ermöglich Bearbeitung beliebigen Objekten von R in C

#vecSum.dll wird geladen
dyn.load("C:/Users/darek/Desktop/RinC/CinR_test/_Call/vecSum.dll")

#vecSum beinhaltet Funktionen:
# vecSum, mat, setList, list


#vecSum addiert alle Elemente des vektors
.Call("vecSum", c(1:3))


#mat addiert zu jede Elemente einer Matrix +1
mat<-matrix(1:9,3, byrow =T)
mat
.Call("mat",mat)


#setList erschafft eine Liste mit zwei vektoren
.Call("setList")


#list gibt der erste Listen Element aus, solnage der ein numerische Vektor ist
x<-c(1:3)
y<-c("ja", "nein")
list<-list(x,y)
.Call("list", list)

dyn.unload("C:/Users/darek/Desktop/RinC/CinR_test/_Call/vecSum.dll")
