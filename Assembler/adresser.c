#include "token.h"
#include <stdint.h>
#include "instructions.h"

struct Token nextToken();

static struct Token t;

int16_t initAddresser()
{
    t = nextToken();
    return 0;
}
