#include <stdio.h>
#include "lexer.h"

int main()
{
    initLexer("test.asm");
    struct Token t;
    while ((t = nextToken()).type != EOFT)
        printf("%s\n", tokenToStr(t));
    return 0;
}
