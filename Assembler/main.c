#include <stdio.h>
#include <stdint.h>
#include "lexer.h"
#include "parser.h"
#include "ast.h"
#include "linkedlist.h"

int main()
{
    initLexer("test.asm");
    initParser();
    parseProgram();

    while (parsedInstrs) {
        printInstr((InstructionNode*)(parsedInstrs->data));
        parsedInstrs = parsedInstrs->next;
    }

    htPrint(labelTable);

    freeParser();
    return 0;
}
