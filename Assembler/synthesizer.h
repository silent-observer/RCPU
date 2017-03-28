#ifndef _SYNTH
#define _SYNTH

#include "ast.h"
#include "dynamicarray.h"

void initSynth(DArray instrList);
char *synthesize();

#endif
