#ifndef _HASHTABLE
#define _HASHTABLE

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

struct HashEntry {
    const char *key;
    uint32_t item;
};

#define _HASHSIZE 100

typedef struct HashEntry *Hashtable;
Hashtable newHashtable();
void freeHT(Hashtable ht);
_Bool htHas(const Hashtable ht, const char *key);
uint32_t htGet(const Hashtable ht, const char *key);
void htSet(Hashtable ht, const char *key, uint32_t value);
void htPrint(Hashtable ht);

#endif
