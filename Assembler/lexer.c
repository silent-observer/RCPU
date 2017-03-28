#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "lexer.h"
#include "error.h"

#define MAX 1000
#define SMALLMAX 100
#define VERYSMALL 10
#include "dynamicarray.h"

#define DEFINE_INSTR_LIST
#include "instrlist.h"
#undef DEFINE_INSTR_LIST


static DArray input; // Input .asm file
static char *p; // Pointer to current character in input file

int16_t initLexer(const char *filename) { // Lexer initialization
    FILE *fp = fopen(filename, "r");
    test(!fp, "File reading error: %s\n", filename);
    char c;
    input = newDArray(MAX, sizeof(char));
    while ((c = getc(fp)) != EOF) // Reading from file
        daAppend(&input, &c);
    // Using empty string to append \0
    daAppend(&input, "");
    p = input.data; // Setting pointer to the start of file
    fclose(fp);
    return 0;
}

void freeLexer() {
    free(input.data);
}

static int voidstrcmp(const void *a, const void *b) { // Comparison of strings
    return strcmp(*(char**) a, *(char**) b);
}

static struct Token getInteger() // Get integer token from input file
{
    int16_t sign = 1;
    if (*p == '-') { // If negative
        p++;
        sign = -1;
    }
    int16_t x = strtol(p, &p, 0) * sign; // Read integer from pointer
    return newTokenV(x, INTEGER);
}
// Get instruction, label or register token
static struct Token getIdentifier()
{
    DArray str1 = newDArray(VERYSMALL, sizeof(char));
    DArray str2 = newDArray(VERYSMALL, sizeof(char));
    while (isalnum(*p)) { // Read to strings from pointer
        daAppend(&str1, p);
        char x = toupper(*p++);
        daAppend(&str2, &x);
    }
    // Using empty string to append \0
    daAppend(&str1, "");
    daAppend(&str2, "");
    if (*p == ':') { // If label definition
        p++;
        return newTokenT(str1.data, LABELDEF);
    }

    if (!strcmp(str2.data, "A") || // If one of registers
        !strcmp(str2.data, "B") ||
        !strcmp(str2.data, "C"))
        return newTokenT(str2.data, REGISTER);

    char **match = (char**) bsearch(&str2.data, &instrList[0],
        NUMINSTR, sizeof(instrList[0]), &voidstrcmp); // Find instruction
    free(str2.data);
    if (!match)
        return newTokenT(str1.data, LABELUSE);
    else {
        free(str1.data);
        return newTokenV(((const char**)match) - &instrList[0], INSTR);
    }
}


// Get next token from input file
struct Token nextToken() {
    while (*p != '\0') {
        if (*p == ';') // Comment
            do
                p++;
            while (*p == '\n');
        else if (*p == ' ' || *p == '\t') // Whitespace
            do
                p++;
            while (*p == '\n' || *p == ' ' || *p == '\t');
        else if (*p == '\n') { // Newline
            do
                p++;
            while (*p == '\n' || *p == ' ' || *p == '\t');
            return newTokenT("\n", NEWLINE);
        }
        else if (*p == ',') { // Comma
            p++;
            return newTokenT(",", COMMA);
        }
        else if (*p == '(') { // Left parenthesis
            p++;
            return newTokenT("(", LPAREN);
        }
        else if (*p == ')') { // Right parenthesis
            p++;
            return newTokenT(")", RPAREN);
        }
        else if (isdigit(*p) || *p == '-') return getInteger(); // Integer
        // Instruction, label or register
        else if (isalpha(*p)) return getIdentifier();
        else return newTokenT("", ERROR); // Invalid token
    }
    return newTokenT("", EOFT);
}
