#ifndef _HASHTABLE
#define _HASHTABLE

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

struct HashEntry {
    const char *key;
    uint16_t item;
};

#define _HASHSIZE 100

typedef struct HashEntry *Hashtable;
Hashtable newHashtable();
_Bool htHas(const Hashtable ht, const char *key);
uint16_t htGet(const Hashtable ht, const char *key);
void htSet(Hashtable ht, const char *key, uint16_t value);
void htPrint(Hashtable ht);

#endif
