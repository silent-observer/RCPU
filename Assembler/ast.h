#ifndef _AST
#define _AST

#include <stdint.h>
#include "linkedlist.h"

typedef struct {
    int8_t sourceType;
    const char *label;
    int16_t value;
} ArgumentNode;

typedef struct {
    uint16_t address;
    const char *name;
    List/*of ArgumentNode*/ args;
} InstructionNode;

#define MODE0 0
#define MODEA 1
#define MODEB 2
#define MODEC 3
#define MODEI 4
#define MODEABS 5
#define MODEAD 6
#define MODEABSI 7

void printInstr(const InstructionNode *instr);
void printArg(const ArgumentNode *arg);

#endif
