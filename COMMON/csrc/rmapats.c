#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarHasChanged=0;
void  hsF_0(struct dummyq_struct * I748, EBLK  * I749, U  I556);
U   hsF_1(U  I760);
U   hsF_1(U  I760)
{
    U  I939 = ffs(I760);
    return  I939 - 1;
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
