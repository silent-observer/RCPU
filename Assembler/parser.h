#ifndef _PARSER
#define _PARSER

#include "ast.h"
#include "linkedlist.h"
#include "hashtable.h"

void initParser();
void freeParser();
void parseProgram();

extern List parsedInstrs;
extern Hashtable labelTable;

#endif
