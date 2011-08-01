#include <math.h>;
#include <io.h>;

/*berechnet n!*/
void fak(int *n)
{
int k=1;
int i;
for(i=1; i <= *n; i++) {
k=k*i;
}
Rprintf("%d", k);
Rprintf("\n");
n[0]=k;
}




