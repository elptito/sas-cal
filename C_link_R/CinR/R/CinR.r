
hello<-function(n)
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	.C("hello", as.integer(n))
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
}

hey<-function(n)
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	.C("hey", as.integer(n))
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
}

fak<-function(n)
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	.C("fak", fakultat= as.integer(n))
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
}

vecSum<-function(vec)
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	.Call("vecSum", vec)
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
}

plus.one.mat<-function(m)
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	new.m<-.Call("mat",m)
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	return(new.m)
}

mach.list<-function()
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	l<-.Call("setList")
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	return(l)
}

prn.list<-function(l)
{
	dyn.load(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
	.Call("list", l)
	dyn.unload(paste(.path.package("CinR"),"/libs/i386/CinR.dll", sep=""))
}



