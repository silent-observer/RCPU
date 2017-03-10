#ifndef _LEXER
#define _LEXER

#include "token.h"
#include <stdint.h>

int16_t initLexer(char* filename); // Lexer initialisation
struct Token nextToken(); // Get next token

#endif
