#ifndef _AST
#define _AST

#include <stdint.h>
#include "dynamicarray.h"

typedef struct {
    int8_t sourceType;
    const char *label;
    int32_t value;
} ArgumentNode;

typedef struct {
    uint16_t address;
    uint16_t type;
    DArray args;
} InstructionNode;

#define MODE0 0
#define MODEA 1
#define MODEB 2
#define MODEC 3
#define MODEI 4
#define MODEABS 5
#define MODEAD 6
#define MODEABSI 7

void printInstr(const InstructionNode instr);
void printArg(const ArgumentNode arg);
char *instrToString(const InstructionNode instr);

#endif
