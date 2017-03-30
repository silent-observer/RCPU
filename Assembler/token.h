#ifndef _TOKEN
#define _TOKEN

#include <stdint.h>

struct Token {
    union {
        const char *text;
        int16_t value;
    };
    uint16_t type;
};

#define ERROR 0
#define EOFT 1
#define INSTR 2
#define NEWLINE 3
#define INTEGER 4
#define LABELDEF 5
#define LABELUSE 6
#define REGISTER 7
#define COMMA 8
#define LPAREN 9
#define RPAREN 10

struct Token newTokenT(const char *text, uint16_t type);        // Create new object
struct Token newTokenV(int16_t value, uint16_t type);   // Create new object
char *tokenToStr(struct Token token);   // Convert to string
const char *typeName(uint16_t type);

#endif
