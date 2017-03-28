#include "ast.h"
#include <stdio.h>

#define DEFINE_INSTR_LIST
#include "instrlist.h"
#undef DEFINE_INSTR_LIST

void printInstr(const InstructionNode instr) {
    printf("%d: %s[", instr.address, instrList[instr.type]);
    if (instr.args.size > 0) {
        uint16_t size = instr.args.size;
        ArgumentNode *data = (ArgumentNode*) instr.args.data;
        for (uint16_t i = 0; i < size; i++)
            printArg(data[i]);
        printf("\b]\n");
    }
    else printf("]\n");
}

void printArg(ArgumentNode arg) {
    switch(arg.sourceType) {
        case MODE0: printf("0 "); break;
        case MODEA: printf("A "); break;
        case MODEB: printf("B "); break;
        case MODEC: printf("C "); break;
        case MODEI: if (arg.label) printf("%s ", arg.label);
                    else printf("%d ", arg.value); break;
        case MODEAD: printf("(A) "); break;
        case MODEABS: if (arg.label) printf("(%s) ", arg.label);
                    else printf("(%d) ", arg.value); break;
        case MODEABSI: if (arg.label) printf("(%s, A) ", arg.label);
                    else printf("(%d, A) ", arg.value); break;
    }
}

static uint16_t argToString(char *str, const ArgumentNode arg) {
    switch(arg.sourceType) {
        case MODE0: return sprintf(str, "0 ");
        case MODEA: return sprintf(str, "A ");
        case MODEB: return sprintf(str, "B ");
        case MODEC: return sprintf(str, "C ");
        case MODEI: if (arg.label) return sprintf(str, "%s ", arg.label);
                    else return sprintf(str, "%d ", arg.value);
        case MODEAD: sprintf(str, "(A) ");
        case MODEABS: if (arg.label) return sprintf(str, "(%s) ", arg.label);
                    else return sprintf(str, "(%d) ", arg.value);
        case MODEABSI: if (arg.label)
                        return sprintf(str, "(%s, A) ", arg.label);
                    else return sprintf(str,"(%d, A) ", arg.value);
    }
    return 0;
}

char *instrToString(const InstructionNode instr) {
    char *res = calloc(100, sizeof(char));
    char *str = res;
    str += sprintf(str, "%d: %s[", instr.address, instrList[instr.type]);
    if (instr.args.size > 0) {
        uint16_t size = instr.args.size;
        ArgumentNode *data = (ArgumentNode*) instr.args.data;
        for (uint16_t i = 0; i < size; i++)
            str += argToString(str, data[i]);
        str += sprintf(str-1, "]");
    }
    else str += sprintf(str, "]");
    return res;
}
