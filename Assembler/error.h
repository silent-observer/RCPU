#ifndef _ERROR
#define _ERROR

#include <stdio.h>

#define test(A, ...) do {if (A) { \
    fprintf(stderr, __VA_ARGS__); \
    exit(EXIT_FAILURE); \
}} while(0)

#define testP(A, ...) do {if (A) { \
    fprintf(stderr, __VA_ARGS__, __FILE__, __LINE__); \
    exit(EXIT_FAILURE); \
}} while(0)
#endif
