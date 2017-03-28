#ifndef _ADDRESSER
#define _ADDRESSER

#include "ast.h"
#include "dynamicarray.h"
#include "hashtable.h"

void initAddresser(Hashtable ht, DArray instrList);
void resolveReferences();

#endif
