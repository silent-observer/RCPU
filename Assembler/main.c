#include <stdio.h>
#include <stdint.h>
#include "lexer.h"
#include "parser.h"
#include "addresser.h"
#include "synthesizer.h"

int main()
{
    initLexer("test.asm");

    /*struct Token t = nextToken();
    printf("%s\n", tokenToStr(t));
    while ((t = nextToken()).type != EOFT)
        printf("%s\n", tokenToStr(t));*/
    initParser();
    parseProgram();
    freeLexer();

    initAddresser(labelTable, parsedInstrs);
    resolveReferences();
    /*InstructionNode *instrs = (InstructionNode*) parsedInstrs.data;
    for (uint16_t i = 0; i < parsedInstrs.size; i++)
        printInstr(instrs[i]);

    htPrint(labelTable);*/

    initSynth(parsedInstrs);
    printf("%s\n", synthesize());

    freeParser();
    return 0;
}
