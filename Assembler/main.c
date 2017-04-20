#include <stdio.h>
#include <stdint.h>
#include "lexer.h"
#include "parser.h"
#include "addresser.h"
#include "synthesizer.h"
#include "error.h"

int main(int argc, char *argv[])
{
    test(argc != 2, "Usage: rcpuasm test.asm");
    initLexer(argv[1]);
    initParser();
    parseProgram();
    freeLexer();

    initAddresser(labelTable, parsedInstrs);
    resolveReferences();

    initSynth(parsedInstrs);
    FILE *fp = fopen("a.rcpu", "w");
    test(!fp, "File writing error!");
    fputs("@00000080\n", fp);
    fputs(synthesize(), fp);
    fputc('\n', fp);
    fclose(fp);

    //freeParser();
    return 0;
}
