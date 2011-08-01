library(survey)

#Beispiel
data(api)
des<-svydesign(id=~sname,weights=~pw, data=apiclus1)

pop.totals<-c(`(Intercept)`=6194, stypeH=755, stypeM=1018)

cal<-calibrate(des, ~stype, pop.totals)

svymean(~enroll, cal)
svytotal(~enroll,cal)
#########################bootstrap#########################################

boot_design <- as.svrepdesign(des, type="bootstrap" , replicate=10000)

svymean(~enroll, boot_design )


