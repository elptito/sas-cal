hello<-function(n){.C("hello", as.integer(n))}

hey<-function(n){.C("hey", as.integer(n))}

fak<-function(n){.C("fak", fakultat= as.integer(n))}

vecSum<-function(vec).Call("vecSum", vec)

mat<-function(m){.Call("mat",m)}

setList<-function(){.Call("setList")}

list<-function(l){.Call("list", l)}



