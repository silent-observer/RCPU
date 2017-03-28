#ifndef _DYNAMIC
#define _DYNAMIC

#include <stdint.h>
#include <stdlib.h>

typedef struct {
    void *data;
    uint16_t capasity;
    uint16_t size;
    size_t elementSize;
} DArray;

DArray newDArray (uint16_t baseCapasity, size_t elementSize);
void daAppend(DArray *array, const void *data);
void daAppendArr(DArray *array, DArray *data);
void daAppendN(DArray *array, const void *data, uint16_t count);

#endif
