#include <stdio.h>
#include <stdint.h>
#include "lexer.h"
#include "parser.h"
#include "addresser.h"

int main()
{
    initLexer("test.asm");
    initParser();
    parseProgram();

    initAddresser(labelTable, parsedInstrs);
    resolveReferences();

    while (parsedInstrs) {
        printInstr((InstructionNode*)(parsedInstrs->data));
        parsedInstrs = parsedInstrs->next;
    }

    htPrint(labelTable);

    freeParser();
    return 0;
}
