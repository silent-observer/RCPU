#include "token.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "linkedlist.h"
#include "hashtable.h"
#include "error.h"

struct Token nextToken();

static struct Token t;

List/*of InstructionNode*/ parsedInstrs;
Hashtable labelTable;
static uint16_t addr;

void initParser() {
    parsedInstrs = newLL();
    labelTable = newHashtable();
    addr = 0;
    t = nextToken();
    if (t.type == NEWLINE)
        t = nextToken();
}

void freeParser() {
    llFree(parsedInstrs);
    free(labelTable);
}

static ArgumentNode *parseAddrMode() {
    ArgumentNode *arg = malloc(sizeof(ArgumentNode));
    testP(!arg, "Cannot allocate storage at %s:%d\n");

    if (t.type == REGISTER) {
        if (!strcmp(t.text, "A")) arg->sourceType = MODEA;
        else if (!strcmp(t.text, "B")) arg->sourceType = MODEB;
        else if (!strcmp(t.text, "C")) arg->sourceType = MODEC;
        else testP(1, "Strange error at %s:%d\n");
    }
    else if (t.type == INTEGER) {
        if (!strcmp(t.text, "0")) arg->sourceType = MODE0;
        else {
            arg->sourceType = MODEI;
            addr++;
            arg->value = strtol(t.text, NULL, 10);
        }
    }
    else if (t.type == LABELUSE) {
        arg->sourceType = MODEI;
        addr++;
        arg->label = t.text;
    }
    else if (t.type == LPAREN) {
        t = nextToken();
        if (t.type == REGISTER) {
                test(strcmp(t.text, "A"), "Invalid adressing register: %s\n",
                    t.text);
                test(nextToken().type != RPAREN, "Unclosed parenthesis!\n")
                arg->sourceType = MODEAD;
            }

        else if(t.type == INTEGER || t.type == LABELUSE) {
            if (t.type == INTEGER)
                arg->value = strtol(t.text, NULL, 10);
            else
                arg->label = t.text;
            addr++;
            t = nextToken();
            if (t.type == COMMA) {
                t = nextToken();
                test(t.type != REGISTER || strcmp(t.text, "A"), "Invalid "
                    "adressing register: %s\n", t.text);
                arg->sourceType = MODEABSI;
                t = nextToken();
            }
            else arg->sourceType = MODEABS;
            test(t.type != RPAREN, "Unclosed parenthesis!\n");
        }
    }
    t = nextToken();

    return arg;
}


static InstructionNode *parseInstruction() {
    InstructionNode *instr = malloc(sizeof(InstructionNode));
    testP(!instr, "Cannot allocate storage at %s:%d\n");
    instr->address = addr++;
    test(t.type != INSTR, "Invalid token type %s while waiting for INSTR\n",
        typeName(t.type));
    instr->name = t.text;
    t = nextToken();
    instr->args = newLL();
    if (t.type != EOFT && t.type != NEWLINE) {
        llAppend(instr->args, (void*)parseAddrMode());
        if (!strcmp(instr->name, "MOV")) {
            ArgumentNode *noArg = malloc(sizeof(ArgumentNode));
            testP(!noArg, "Cannot allocate storage at %s:%d\n");
            noArg->sourceType = MODE0;
            llAppend(instr->args, (void*) noArg);
            instr->name = "ADD";
        }
        while (t.type == COMMA) {
            t = nextToken();
            llAppend(instr->args, (void*)parseAddrMode());
        }
    }
    if (!strcmp(instr->name, "JMP") ||
        !strcmp(instr->name, "ADDI") || !strcmp(instr->name, "ADCI") ||
        !strcmp(instr->name, "SUBI") || !strcmp(instr->name, "SBCI") ||
        !strcmp(instr->name, "ANDI") || !strcmp(instr->name, "ORI") ||
        !strcmp(instr->name, "XORI") ||
        !strcmp(instr->name, "LSHI") || !strcmp(instr->name, "RSHI") ||
        !strcmp(instr->name, "LRTI") || !strcmp(instr->name, "RRTI")
    ) addr--;
    test(t.type != NEWLINE, "Invalid token type %s while waiting for NEWLINE\n",
        typeName(t.type));
    t = nextToken();
    return instr;
}

void parseProgram() {
    while (t.type != EOFT) {
        if (t.type == NEWLINE)
            t = nextToken();
        else if (t.type != LABELDEF) {
            llAppend(parsedInstrs, (void*)parseInstruction());
        } else {
            htSet(labelTable, t.text, addr);
            t = nextToken();
        }
    }
}
