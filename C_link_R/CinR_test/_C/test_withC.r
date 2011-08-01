#Beispiele für Funktion .C
#.C ermöglich Bearbeitung von Zahlen und Vektoren in C
#.C gibt immer eine LIste zurück

#hello.dll wird geladen
dyn.load("C:/Users/darek/Desktop/RinC/CinR_test/_C/hello.dll")

#hello beinhaltet Funktionen:
#hello, hey
#beide Funktionen geben kurze Texte aus

.C("hello", as.integer(3))
.C("hey", as.integer(2))
dyn.unload("C:/Users/darek/Desktop/RinC/CinR_test/_C/hello.dll")

#####################################

#fak.dll wird geladen
dyn.load("C:/Users/darek/Desktop/RinC/CinR_test/_C/fak.dll")

#Funktion fak berechnet n!
.C("fak", fakultat= as.integer(5))
dyn.unload("C:/Users/darek/Desktop/RinC/CinR_test/_C/fak.dll")

