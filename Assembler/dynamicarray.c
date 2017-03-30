#include "dynamicarray.h"
#include <string.h>
#include "error.h"

DArray newDArray(uint16_t baseCapasity, size_t elementSize)
{
    void *data = calloc(baseCapasity, elementSize);
    test(!data, "Cannot allocate mempry for dynamic array");

    DArray res;
    res.data = data;
    res.capasity = baseCapasity;
    res.size = 0;
    res.elementSize = elementSize;
    return res;
}

void daAppend(DArray * array, const void *data)
{
    daAppendN(array, data, 1);
}

void daAppendArr(DArray * array, DArray * data)
{
    test(array->elementSize != data->elementSize,
         "Incompatible array types!");
    daAppendN(array, data->data, data->size);
}

void daAppendN(DArray * array, const void *data, uint16_t count)
{
    if (array->size + count > array->capasity) {
        void *newData = calloc((count + array->capasity) * 2,
                               array->elementSize);
        test(!newData, "Cannot allocate mempry for dynamic array");
        memcpy(newData, array->data, array->capasity);
        free(array->data);
        array->data = newData;
        array->capasity = (count + array->capasity) * 2;
    }
    memcpy(array->data + array->size * array->elementSize, data,
           array->elementSize * count);
    array->size += count;
}
