#ifndef _ERROR
#define _ERROR

#include <stdio.h>

#define test(A, ...) if (A) { \
    fprintf(stderr, __VA_ARGS__); \
    exit(EXIT_FAILURE); \
}

#define testP(A, ...) if (A) { \
    fprintf(stderr, __VA_ARGS__, __FILE__, __LINE__); \
    exit(EXIT_FAILURE); \
}
#endif
