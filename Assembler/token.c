#include "token.h"

struct Token newToken(char *text, unsigned int type) {
    struct Token this;
    this.text = text;
    this.type = type;
    return this;
}
