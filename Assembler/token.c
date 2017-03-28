#include "token.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "error.h"

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

struct Token newTokenT(const char *text, uint16_t type) { // New object
    struct Token t;
    t.text = text;
    t.type = type;
    return t;
}

struct Token newTokenV(int16_t value, uint16_t type) { // New object
    struct Token t;
    t.value = value;
    t.type = type;
    return t;
}

char *tokenToStr(struct Token token) { // Convert to string
    char *str = (char*) malloc(MAXLENGTH);
    test(!str, "Cannot allocate storage for tokenToStr\n");
    if (token.type == NEWLINE)
        sprintf(str, "<\"\\n\", NEWLINE>");
    else
        sprintf(str, "<\"%s\", %s>", token.text, typeNames[token.type]);
    return str;
}

const char *typeName(uint16_t type) {
    return typeNames[type];
}
