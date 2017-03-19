#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdint.h>
#include "token.h"
#include "error.h"

#define MAXCHAR 10000
#define MAXLENGTH MAXCHAR*sizeof(char)
#define SMALLMAX 100*sizeof(char)

// Sorted list of instructions names

static const char *instrs[] = {
    "ADC", "ADCI", "ADD", "ADDI", "AND", "ANDI",
    "FLC", "FLS",
    "JCC", "JCS", "JEQ", "JFC", "JFS", "JGE", "JGT", "JLE", "JLT", "JMP", "JNE",
    "JVC", "JVS",
    "LRT", "LRTI", "LSH", "LSHI",
    "MLL", "MOV", "MUL",
    "NOT",
    "OR", "ORI",
    "POP", "PUSH",
    "RAS", "RET", "RRT", "RRTI", "RSH", "RSHI",
    "SBC", "SBCI", "SGN", "SUB", "SUBI",
    "XOR", "XORI"
};
// Number of instructions
#define NUMINSTR sizeof(instrs) / sizeof(instrs[0])

static char input[MAXLENGTH]; // Input .asm file
static char *p; // Pointer to current character in input file

int16_t initLexer(const char *filename) { // Lexer initialization
    FILE *fp = fopen(filename, "r");
    test(!fp, "File reading error: %s\n", filename);
    char c;
    uint16_t i = 0;
    while ((c = getc(fp)) != EOF) // Reading from file
        if (i < MAXLENGTH)
            input[i++] = c;
        else {
            fclose(fp);
            test(1, "File is bigger than %d characters\n", MAXCHAR);
        }
    input[i] = '\0';
    p = &input[0]; // Setting pointer to the start of file
    fclose(fp);
    return 0;
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
    int16_t x = strtol(p, &p, 0); // Read integer from pointer
    char *str = (char*) malloc(SMALLMAX); // Allocate new string
    testP(!str, "Cannot allocate string at %s:%d\n");
    sprintf(str, "%d", sign*x); // And write integer there in decimal
    return newToken(str, INTEGER);
}
// Get instruction, label or register token
static struct Token getIdentifier()
{
    char *str1 = (char*) malloc(SMALLMAX); // Allocate new string
    char *str2 = (char*) malloc(SMALLMAX); // Allocate new string
    testP(!str1 || !str2, "Cannot allocate string at %s:%d\n");
    char *strpntr1 = str1;
    char *strpntr2 = str2;
    while (isalnum(*p)) { // Read to it from pointer
        *strpntr1++ = *p;
        *strpntr2++ = toupper(*p++);
    }
    *strpntr1++ = '\0';
    *strpntr2++ = '\0';
    if (*p == ':') { // If label definition
        p++;
        return newToken(str1, LABELDEF);
    }

    if (!strcmp(str2, "A") || // If one of registers
        !strcmp(str2, "B") ||
        !strcmp(str2, "C"))
        return newToken(str2, REGISTER);

    char **match = (char**) bsearch(&str2, &instrs[0],
        NUMINSTR, sizeof(instrs[0]), &voidstrcmp); // Find instruction
    if (!match)
        return newToken(str1, LABELUSE);
    else
        return newToken(str2, INSTR);
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
            return newToken("\n", NEWLINE);
        }
        else if (*p == ',') { // Comma
            p++;
            return newToken(",", COMMA);
        }
        else if (*p == '(') { // Left parenthesis
            p++;
            return newToken("(", LPAREN);
        }
        else if (*p == ')') { // Right parenthesis
            p++;
            return newToken(")", RPAREN);
        }
        else if (isdigit(*p) || *p == '-') return getInteger(); // Integer
        // Instruction, label or register
        else if (isalpha(*p)) return getIdentifier();
        else return newToken("", ERROR); // Invalid token
    }
    return newToken("", EOFT);
}
