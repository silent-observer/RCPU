#include "hashtable.h"
#include <stdlib.h>
#include <string.h>
#include "error.h"

#define MAXSTRLENGTH 200*sizeof(char)


static uint16_t strhash(const char *str)
{
    uint16_t hash = 5381;
    uint8_t c;

    while ((c = *str++))
        hash = ((hash << 5) + hash) + c;
    return hash % _HASHSIZE;
}

Hashtable newHashtable()
{
    Hashtable hash =
        (Hashtable) calloc(_HASHSIZE, sizeof(struct HashEntry));
    test(!hash, "Cannot allocate storage for new Hashtable\n");
    return hash;
}

void freeHT(Hashtable ht)
{
    for (uint16_t i = 0; i < _HASHSIZE; i++) {
        free((void *) ht[i].key);
    }
    free(ht);
}

_Bool htHas(const Hashtable ht, const char *key)
{
    uint16_t hash = strhash(key);
    uint16_t steps = 0;
    while (ht[hash].key != NULL && steps++ < _HASHSIZE) {
        if (!strcmp(ht[hash].key, key))
            return true;
        hash++;
        hash %= _HASHSIZE;
    }
    test(steps >= _HASHSIZE, "Hashtable has been filled\n");
    return false;
}

uint16_t htGet(const Hashtable ht, const char *key)
{
    uint16_t hash = strhash(key);
    uint16_t steps = 0;
    while (ht[hash].key != NULL && steps++ < _HASHSIZE) {
        if (!strcmp(ht[hash].key, key))
            return ht[hash].item;

        hash++;
        hash %= _HASHSIZE;
    }
    test(steps >= _HASHSIZE, "Hashtable has been filled\n");
    test(1, "Cannot find key %s in hashtable\n", key);
}

void htPrint(const Hashtable ht)
{
    printf("{\n");
    for (uint16_t i = 0; i < _HASHSIZE; i++)
        if (ht[i].key)
            printf("  %s:%d\n", ht[i].key, ht[i].item);
    printf("}\n");
}

void htSet(Hashtable ht, const char *key, uint16_t item)
{
    uint16_t hash = strhash(key);
    uint16_t steps = 0;
    while (steps++ < _HASHSIZE) {
        if (ht[hash].key == NULL || !strcmp(ht[hash].key, key)) {
            ht[hash].key = key;
            ht[hash].item = item;
            return;
        }

        hash++;
        hash %= _HASHSIZE;
    }
    test(steps >= _HASHSIZE, "Hashtable has been filled\n");
}
