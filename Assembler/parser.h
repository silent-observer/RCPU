#ifndef _PARSER
#define _PARSER

#include "ast.h"
#include "dynamicarray.h"
#include "hashtable.h"

void initParser();
void freeParser();
void parseProgram();

extern DArray /*of InstructionNode */ parsedInstrs;
extern Hashtable labelTable;

#endif
