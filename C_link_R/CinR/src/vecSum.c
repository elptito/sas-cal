#include <R.h>
#include <Rdefines.h>
#include <Rmath.h>

//addiert alle Vektor-Elemente
SEXP vecSum(SEXP Rvec){
     int i, n;
     double *vec, value = 0;

     vec = REAL(AS_NUMERIC(Rvec));
     n = length(Rvec);
     for (i = 0; i < n; i++) value += vec[i];
         Rprintf("The value is: %4.6f \n", value);

     return R_NilValue;
}

//addiert zu jede Matrix-Element +1
SEXP mat(SEXP RinMatrix){
     SEXP Rdim, Rval;
     int I,J, i, j;
     
     Rdim = getAttrib(RinMatrix, R_DimSymbol);
     I = INTEGER(Rdim)[0];
     J = INTEGER(Rdim)[1];
     
     PROTECT(Rval = allocMatrix(REALSXP, I, J));
     for (i = 0; i < I; i++){
         for (j = 0; j < I; j++)         
             REAL(Rval)[i + I * j] = REAL(AS_NUMERIC(RinMatrix))[i + I * j]+1;
     }
     UNPROTECT(1);
     return Rval;
}

//erzeugt und gibt eine Liste mit zwei Elemente zurück 
SEXP setList() {
     int *p_myint, i; 
     double *p_double;
     SEXP mydouble, myint, rlist, list_names;   
     char *names[2] = {"integer", "numeric"};
     PROTECT(myint = NEW_INTEGER(5)); 
     p_myint = INTEGER_POINTER(myint);
     PROTECT(mydouble = NEW_NUMERIC(5)); 
     p_double = NUMERIC_POINTER(mydouble);
      
     for(i = 0; i < 5; i++) {
           p_double[i] = 1/(double)(i + 1);
           p_myint[i] = i + 1;
     }

     PROTECT(list_names = allocVector(STRSXP,2));    

     for(i = 0; i < 2; i++)   
           SET_STRING_ELT(list_names,i,mkChar(names[i])); 
     
     PROTECT(rlist = allocVector(VECSXP, 2)); 
   
     SET_VECTOR_ELT(rlist, 0, myint); 
   
     SET_VECTOR_ELT(rlist, 1, mydouble); 
   
     setAttrib(rlist, R_NamesSymbol, list_names); 
     UNPROTECT(4);
     return rlist;
}

     
//gibt erstes Listen-Element aus
SEXP list(SEXP list){
     int n, i;
     int *vec;
     vec=INTEGER(VECTOR_ELT(list, 0));
     
     n = length(VECTOR_ELT(list, 0));
 
     for (i = 0; i < n; i++) 
         Rprintf("%d \n", vec[i]);
     
     return R_NilValue;
}







