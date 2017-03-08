#include <stdio.h>
#include <ctype.h>
#include "token.h"

#define MAXLENGTH 10000

static char input[MAXLENGTH];
static char *p;

int initLexer(char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) return -2;
    char c;
    unsigned int i = 0;
    while ((c = getc(fp)) != EOF)
        if (i < MAXLENGTH)
            input[i++] = c;
        else
            return -1;
    input[i] = '\0';
    p = &input[0];
    return 0;
}

static struct Token getInteger()
{
    return newToken("", INTEGER);
}
static struct Token getIdentifier()
{
    return newToken("", INSTR);
}

struct Token nextToken() {
    while (*p != '\0') {
        if (*p == ';')
            do
                p++;
            while (*p == '\n' || *p == '\0');
        else if (*p == ' ' || *p == '\t')
            do
                p++;
            while (*p == '\n' || *p == '\0' || *p == ' ' || *p == '\t');
        else if (*p == '\n') {
            p++;
            return newToken("\n", NEWLINE);
        }
        else if (*p == ',') {
            p++;
            return newToken(",", COMMA);
        }
        else if (*p == '(') {
            p++;
            return newToken("(", LPAREN);
        }
        else if (*p == ')') {
            p++;
            return newToken(")", LPAREN);
        }
        else if (isdigit(*p)) return getInteger();
        else if (isalpha(*p)) return getIdentifier();
        else return newToken("", ERROR);
    }
    return newToken("", EOFT);
}
