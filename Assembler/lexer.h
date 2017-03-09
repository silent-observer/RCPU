#ifndef _LEXER
#define _LEXER

#include "token.h"

int initLexer(char* filename); // Lexer initialisation
struct Token nextToken(); // Get next token

#endif
