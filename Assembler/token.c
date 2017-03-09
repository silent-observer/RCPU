#include "token.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXLENGTH 50*sizeof(char)

static const char *typeNames[] = {
    "ERROR",
    "EOFT",
    "INSTR",
    "NEWLINE",
    "INTEGER",
    "LABELDEF",
    "LABELUSE",
    "REGISTER",
    "COMMA",
    "LPAREN",
    "RPAREN"
};

struct Token newToken(char *text, unsigned int type) { // New object
    struct Token this;
    this.text = text;
    this.type = type;
    return this;
}

char* tokenToStr(struct Token token) { // Convert to string
    char* str = malloc(MAXLENGTH);
    if (token.type == NEWLINE)
        sprintf(str, "<\"\\n\", NEWLINE>");
    else
        sprintf(str, "<\"%s\", %s>", token.text, typeNames[token.type]);
    return str;
}
