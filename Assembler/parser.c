#include "token.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"
#include "error.h"

struct Token nextToken();

static struct Token t;

DArray /*of InstructionNode */ parsedInstrs;
Hashtable labelTable;
static uint32_t addr;

#include "instrlist.h"

void initParser()
{
    parsedInstrs = newDArray(100, sizeof(InstructionNode));
    labelTable = newHashtable();
    addr = 0x80;
    t = nextToken();
    if (t.type == NEWLINE)
        t = nextToken();
}

void freeParser()
{
    free(parsedInstrs.data);
    freeHT(labelTable);
}

static ArgumentNode parseAddrMode()
{
    ArgumentNode arg;
    arg.label = NULL;
    arg.value = 0;

    if (t.type == REGISTER) {
        if (!strcmp(t.text, "A"))
            arg.sourceType = MODEA;
        else if (!strcmp(t.text, "B"))
            arg.sourceType = MODEB;
        else if (!strcmp(t.text, "C"))
            arg.sourceType = MODEC;
        else
            testP(1, "Strange error at %s:%d\n");
        free((void *) t.text);
    } else if (t.type == INTEGER) {
        if (t.value == 0)
            arg.sourceType = MODE0;
        else {
            arg.sourceType = MODEI;
            addr++;
            arg.value = t.value;
        }
    } else if (t.type == LABELUSE) {
        arg.sourceType = MODEI;
        addr++;
        arg.label = t.text;
    } else if (t.type == LPAREN) {
        t = nextToken();
        if (t.type == REGISTER) {
            test(strcmp(t.text, "A"), "Invalid adressing register: %s\n",
                 t.text);
            free((void *) t.text);
            test(nextToken().type != RPAREN, "Unclosed parenthesis!\n");
            arg.sourceType = MODEAD;
        }

        else if (t.type == INTEGER || t.type == LABELUSE) {
            if (t.type == INTEGER)
                arg.value = t.value;
            else
                arg.label = t.text;
            addr++;
            t = nextToken();
            if (t.type == COMMA) {
                t = nextToken();
                test(t.type != REGISTER || strcmp(t.text, "A"), "Invalid "
                     "adressing register: %s\n", t.text);
                arg.sourceType = MODEABSI;
                free((void *) t.text);
                t = nextToken();
            } else
                arg.sourceType = MODEABS;
            test(t.type != RPAREN, "Unclosed parenthesis!\n");
        }
    }
    t = nextToken();

    return arg;
}


static InstructionNode parseInstruction()
{
    InstructionNode instr;
    instr.address = addr++;
    test(t.type != INSTR,
         "Invalid token type %s while waiting for INSTR: %s\n",
         typeName(t.type), t.text);
    instr.type = t.value;
    t = nextToken();
    instr.args = newDArray(3, sizeof(ArgumentNode));
    if (t.type != EOFT && t.type != NEWLINE) {
        ArgumentNode arg = parseAddrMode();
        daAppend(&instr.args, &arg);
        ArgumentNode noArg;
        noArg.label = NULL;
        noArg.value = 0;
        switch (instr.type) {
        case MOV_INDEX:
            noArg.sourceType = MODE0;
            daAppend(&instr.args, &noArg);
            instr.type = ADD_INDEX;
            break;
        case JCC_INDEX:
        case JCS_INDEX:
            noArg.sourceType = MODEI;
            noArg.value = 3;
            addr++;
            daAppend(&instr.args, &noArg);
            break;
        case JGE_INDEX:
        case JLT_INDEX:
            noArg.sourceType = MODEI;
            noArg.value = 2;
            addr++;
            daAppend(&instr.args, &noArg);
            break;
        case JEQ_INDEX:
        case JNE_INDEX:
            noArg.sourceType = MODEI;
            noArg.value = 1;
            addr++;
            daAppend(&instr.args, &noArg);
            break;
        case JVC_INDEX:
        case JVS_INDEX:
            noArg.sourceType = MODEI;
            noArg.value = 0;
            addr++;
            daAppend(&instr.args, &noArg);
            break;
        }
        switch (instr.type) {
        case JCC_INDEX:
        case JGE_INDEX:
        case JNE_INDEX:
        case JVC_INDEX:
            instr.type = JFC_INDEX;
            break;
        case JCS_INDEX:
        case JLT_INDEX:
        case JEQ_INDEX:
        case JVS_INDEX:
            instr.type = JFS_INDEX;
            break;
        }
        while (t.type == COMMA) {
            t = nextToken();
            arg = parseAddrMode();
            daAppend(&instr.args, &arg);
        }
    }
    if ((instr.type >= FLC_INDEX && instr.type <= JVS_INDEX) ||
        instr.type == ADDI_INDEX || instr.type == ADCI_INDEX ||
        instr.type == SUBI_INDEX || instr.type == SBCI_INDEX ||
        instr.type == ANDI_INDEX || instr.type == ORI_INDEX ||
        instr.type == XORI_INDEX ||
        instr.type == LSHI_INDEX || instr.type == RSHI_INDEX ||
        instr.type == LRTI_INDEX || instr.type == RRTI_INDEX ||
        instr.type == SVPC_INDEX || instr.type == RET_INDEX)
        addr--;
    if (instr.type >= JCC_INDEX &&
        instr.type <= JVS_INDEX && instr.type != JMP_INDEX)
        addr--;
    if (instr.type == POP_INDEX || instr.type == PUSH_INDEX) {
        ArgumentNode *args = (ArgumentNode*) instr.args.data;
        test(instr.args.size != 1, "Invalid argument count %d "
            "while expected 1: %s\n", instr.args.size, instrToString(instr));
        if (args[0].sourceType == MODEABS && args[0].value < 128) addr--;
    }
    test(t.type != NEWLINE,
         "Invalid token type %s while waiting for NEWLINE: " "%s\n",
         typeName(t.type), t.text);
    t = nextToken();
    return instr;
}

void parseProgram()
{
    while (t.type != EOFT) {
        if (t.type == NEWLINE)
            t = nextToken();
        else if (t.type != LABELDEF) {
            InstructionNode instr = parseInstruction();
            daAppend(&parsedInstrs, &instr);
        } else {
            char *high = malloc(strlen(t.text)+3);
            char *low = malloc(strlen(t.text)+3);
            strcpy(high, t.text);
            strcpy(low, t.text);
            strcat(high, "$h");
            strcat(low, "$l");
            htSet(labelTable, t.text, addr);
            htSet(labelTable, high, addr >> 16);
            htSet(labelTable, low, addr & 0xFFFF);

            t = nextToken();
        }
    }
}
