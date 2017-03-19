#include "ast.h"
#include <stdio.h>

void printInstr(const InstructionNode *instr) {
    printf("%d: %s[", instr->address, instr->name);
    List args = instr->args;
    if (args->data) {
        while (args) {
            printArg((ArgumentNode*) args->data);
            args = args->next;
        }
        printf("\b]\n");
    }
    else printf("]\n");
}

void printArg(const ArgumentNode *arg) {
    switch(arg->sourceType) {
        case MODE0: printf("0 "); break;
        case MODEA: printf("A "); break;
        case MODEB: printf("B "); break;
        case MODEC: printf("C "); break;
        case MODEI: if (arg->label) printf("%s ", arg->label);
                    else printf("%d ", arg->value); break;
        case MODEAD: printf("(A) "); break;
        case MODEABS: if (arg->label) printf("(%s) ", arg->label);
                    else printf("(%d) ", arg->value); break;
        case MODEABSI: if (arg->label) printf("(%s, A) ", arg->label);
                    else printf("(%d, A) ", arg->value); break;
    }
}
